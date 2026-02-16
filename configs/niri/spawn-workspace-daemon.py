"""
Daemon that moves new windows to the workspace of their ancestor window.

Listens to niri's event stream. When a new window appears:
1. Gets the window's PID
2. Walks /proc/<pid>/status PPid chain upward
3. Finds the first ancestor PID that matches an existing niri window
4. Moves the new window to that ancestor window's workspace (handling multi-monitor)

Use case: Claude Code running in a terminal on workspace 1 spawns a Tauri
app — the Tauri window opens on workspace 1, not the currently focused one.
"""

import json
import subprocess
import sys
import traceback


def log(msg):
    print(f"[spawn-ws] {msg}", file=sys.stderr, flush=True)


def get_ppid(pid):
    try:
        with open(f"/proc/{pid}/status") as f:
            for line in f:
                if line.startswith("PPid:"):
                    return int(line.split()[1])
    except (FileNotFoundError, PermissionError, ValueError, IndexError):
        return None
    return None


def niri_msg_json(*args):
    result = subprocess.run(
        ["niri", "msg", "--json"] + list(args),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None


def niri_action(*args):
    result = subprocess.run(
        ["niri", "msg", "action"] + list(args),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        log(f"  niri action failed: {' '.join(args)} -> {result.stderr.strip()}")
    return result.returncode == 0


def find_ancestor_window(pid, pid_to_window):
    """Walk up PID tree to find the first ancestor that is a known niri window."""
    visited = set()
    current = get_ppid(pid)
    while current and current > 1 and current not in visited:
        visited.add(current)
        if current in pid_to_window:
            return pid_to_window[current]
        current = get_ppid(current)
    return None


def main():
    log("starting")

    known_window_ids = set()
    windows = {}  # window_id -> {pid, workspace_id}
    pid_to_window = {}  # pid -> window_id
    workspaces = {}  # workspace_id -> {idx, output}

    def update_workspaces(ws_list):
        workspaces.clear()
        for ws in ws_list:
            workspaces[ws["id"]] = {"idx": ws["idx"], "output": ws.get("output")}

    def update_all_windows(win_list):
        known_window_ids.clear()
        windows.clear()
        pid_to_window.clear()
        for w in win_list:
            wid = w["id"]
            known_window_ids.add(wid)
            windows[wid] = {"pid": w.get("pid"), "workspace_id": w.get("workspace_id")}
            if w.get("pid"):
                pid_to_window[w["pid"]] = wid

    # Initialize
    ws_data = niri_msg_json("workspaces")
    if ws_data:
        update_workspaces(ws_data)
        log(f"initialized {len(workspaces)} workspaces")

    win_data = niri_msg_json("windows")
    if win_data:
        update_all_windows(win_data)
        log(f"initialized {len(windows)} windows")

    # Listen to event stream
    proc = subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"],
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )

    for line in proc.stdout:
        line = line.strip()
        if not line:
            continue

        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        try:
            if "WindowsChanged" in event:
                update_all_windows(event["WindowsChanged"]["windows"])

            elif "WorkspacesChanged" in event:
                update_workspaces(event["WorkspacesChanged"]["workspaces"])

            elif "WindowOpenedOrChanged" in event:
                window = event["WindowOpenedOrChanged"]["window"]
                wid = window["id"]
                pid = window.get("pid")
                new_ws_id = window.get("workspace_id")

                is_new = wid not in known_window_ids
                known_window_ids.add(wid)

                # Update tracking maps
                old = windows.get(wid)
                if old and old.get("pid") and old["pid"] in pid_to_window:
                    del pid_to_window[old["pid"]]
                windows[wid] = {"pid": pid, "workspace_id": new_ws_id}
                if pid:
                    pid_to_window[pid] = wid

                if not is_new or not pid or not new_ws_id:
                    continue

                # New window — find ancestor workspace
                ancestor_wid = find_ancestor_window(pid, pid_to_window)
                if ancestor_wid is None:
                    log(f"new window id={wid} app_id={window.get('app_id')} pid={pid}: no ancestor found")
                    continue

                ancestor_ws_id = windows.get(ancestor_wid, {}).get("workspace_id")
                if not ancestor_ws_id or ancestor_ws_id == new_ws_id:
                    continue

                ancestor_ws = workspaces.get(ancestor_ws_id)
                new_ws = workspaces.get(new_ws_id)
                if not ancestor_ws:
                    log(f"new window id={wid}: ancestor workspace {ancestor_ws_id} not found")
                    continue

                target_idx = ancestor_ws["idx"]
                target_output = ancestor_ws.get("output")
                current_output = new_ws.get("output") if new_ws else None

                log(f"new window id={wid} app_id={window.get('app_id')} pid={pid}: "
                    f"ancestor id={ancestor_wid} ws={ancestor_ws_id} output={target_output} idx={target_idx}, "
                    f"current ws={new_ws_id} output={current_output}")

                # Move to correct monitor first if needed
                if target_output and current_output and target_output != current_output:
                    log(f"  moving to monitor {target_output}")
                    niri_action("move-window-to-monitor", "--id", str(wid), target_output)

                # Move to correct workspace
                log(f"  moving to workspace idx={target_idx}")
                niri_action(
                    "move-window-to-workspace",
                    "--window-id", str(wid),
                    "--focus", "false",
                    str(target_idx),
                )

            elif "WindowClosed" in event:
                closed_id = event["WindowClosed"]["id"]
                known_window_ids.discard(closed_id)
                old = windows.pop(closed_id, None)
                if old and old.get("pid") and pid_to_window.get(old["pid"]) == closed_id:
                    del pid_to_window[old["pid"]]

        except Exception:
            log(f"error processing event: {traceback.format_exc()}")


if __name__ == "__main__":
    main()
