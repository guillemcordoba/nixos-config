"""
Daemon that moves new windows to the workspace of their ancestor window.

Listens to niri's event stream. When a new window appears:
1. Gets the window's PID
2. Walks /proc/<pid>/status PPid chain upward
3. Finds the first ancestor PID that matches an existing niri window
4. Moves the new window to that ancestor window's workspace

Use case: Claude Code running in a terminal on workspace 1 spawns a Tauri
app — the Tauri window opens on workspace 1, not the currently focused one.
"""

import json
import subprocess
import sys


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


def move_window_to_workspace(window_id, workspace_idx):
    subprocess.run(
        [
            "niri",
            "msg",
            "action",
            "move-window-to-workspace",
            "--window-id",
            str(window_id),
            str(workspace_idx),
        ],
        capture_output=True,
    )


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
    known_window_ids = set()
    windows = {}  # window_id -> {pid, workspace_id}
    pid_to_window = {}  # pid -> window_id
    ws_id_to_idx = {}  # workspace_id -> workspace_idx

    # Initialize workspace map
    workspaces = niri_msg_json("workspaces")
    if workspaces:
        for ws in workspaces:
            ws_id_to_idx[ws["id"]] = ws["idx"]

    # Initialize windows map
    initial_windows = niri_msg_json("windows")
    if initial_windows:
        for w in initial_windows:
            wid = w["id"]
            known_window_ids.add(wid)
            windows[wid] = {"pid": w.get("pid"), "workspace_id": w.get("workspace_id")}
            if w.get("pid"):
                pid_to_window[w["pid"]] = wid

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

        if "WindowsChanged" in event:
            known_window_ids.clear()
            windows.clear()
            pid_to_window.clear()
            for w in event["WindowsChanged"]["windows"]:
                wid = w["id"]
                known_window_ids.add(wid)
                windows[wid] = {
                    "pid": w.get("pid"),
                    "workspace_id": w.get("workspace_id"),
                }
                if w.get("pid"):
                    pid_to_window[w["pid"]] = wid

        elif "WorkspacesChanged" in event:
            ws_id_to_idx.clear()
            for ws in event["WorkspacesChanged"]["workspaces"]:
                ws_id_to_idx[ws["id"]] = ws["idx"]

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
                continue

            ancestor_ws_id = windows.get(ancestor_wid, {}).get("workspace_id")
            if not ancestor_ws_id or ancestor_ws_id == new_ws_id:
                continue

            # Move to ancestor's workspace
            target_idx = ws_id_to_idx.get(ancestor_ws_id)
            if target_idx is not None:
                move_window_to_workspace(wid, target_idx)

        elif "WindowClosed" in event:
            closed_id = event["WindowClosed"]["id"]
            known_window_ids.discard(closed_id)
            old = windows.pop(closed_id, None)
            if old and old.get("pid") and pid_to_window.get(old["pid"]) == closed_id:
                del pid_to_window[old["pid"]]


if __name__ == "__main__":
    main()
