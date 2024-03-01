# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.log_utils import logger
from qtile_extras import widget
from qtile_extras.widget.decorations import PowerLineDecoration
import time

mod = "mod1"
terminal = guess_terminal()

@lazy.function
def new_group_prompt(qtile):
    def add_group(text):
        qtile.addgroup(group=text)
        qtile.cmd_spawn(f"qtile cmd-obj -o group {text} -f toscreen")
        # group[text].toscreen()
        # logger.warning(f"qtile cmd-obj -o group {text} -f toscreen")
        # lazy.spawn(f"qtile cmd-obj -o group {text} -f toscreen")
        # qtile.group[text].toscreen()

    prompt = qtile.widgets_map["prompt"]
    prompt.start_input("New group name", add_group)

@lazy.function
def new_project_group_prompt(qtile):
    def add_project_group(text):
        qtile.addgroup(group=text)
        qtile.spawn(f"qtile cmd-obj -o group {text} -f toscreen")
        qtile.spawn(f"""alacritty --hold --command ''bash -c 'eval "$(zoxide init bash)";z {text};hx'''""", shell = True)
        qtile.spawn(f"""alacritty --hold --command ''bash -c 'eval "$(zoxide init bash)";z {text};pwd;bash'''""", shell = True)
        qtile.spawn(f"""alacritty --hold --command ''bash -c 'eval "$(zoxide init bash)";z {text};lazygit'''""", shell = True)

    prompt = qtile.widgets_map["prompt"]
    prompt.start_input("Project name", add_project_group)

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "mod4"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "mod4"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "mod4"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "mod4"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    # Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.screen.toggle_group(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "o", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([mod, "Shift"], 'h', lazy.next_screen(), desc='Next monitor'),
    Key([mod, "Shift"], 'l', lazy.prev_screen(), desc='Previous monitor'),
    Key([mod, "Shift"], 'k', lazy.screen.next_group(), desc='Next group'),
    Key([mod, "Shift"], 'j', lazy.screen.prev_group(), desc='Previous group'),
    Key([mod], "v", lazy.switchgroup(prompt="View group")),
    Key([mod], "m", lazy.togroup(prompt="Move to group")),
    Key([mod], "c", lazy.labelgroup(prompt="Change group name")),
    Key([mod], "n", new_group_prompt),
    Key([mod, "Shift"], "n", new_project_group_prompt),
    Key([], "Print", lazy.spawn("scrot /home/guillem/Imatges")),

]

groups = [
    Group("web", matches=[Match(wm_class=["chromium"])]), 
    Group("debug", matches=[Match(wm_class=["hc-launch"])]), 
    Group("chat", matches=[Match(wm_class=["discord"])]), 
    Group("music", matches=[Match(wm_class=["spotify"])]), 
    Group("zoom", matches=[Match(wm_class=["zoom"])]), 
]

# for i in groups:
#     keys.extend(
#         [
#             # mod1 + letter of group = switch to group
#             Key(
#                 [mod],
#                 i.name,
#                 lazy.group[i.name].toscreen(),
#                 desc="Switch to group {}".format(i.name),
#             ),
#             # mod1 + shift + letter of group = switch to & move focused window to group
#             Key(
#                 [mod, "shift"],
#                 i.name,
#                 lazy.window.togroup(i.name, switch_group=True),
#                 desc="Switch to & move focused window to group {}".format(i.name),
#             ),
#             # Or, use below if you prefer not to switch to that group.
#             # # mod1 + shift + letter of group = move focused window to group
#             # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
#             #     desc="move focused window to group {}".format(i.name)),
#         ]
#     )

layouts = [
    layout.Columns(margin=8, insert_position=1, border_focus='yellow'),
    # layout.Max(),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=20hl),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(margin = 8),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="sans",
    fontsize=12,
    padding=3,
)

powerline = {
    "decorations": [
        PowerLineDecoration(path = "forward_slash", padding_x = 16)
    ]
}

s = widget.Battery() if os.environ.get('DEVICE_TYPE', 'DESKTOP') == 'LAPTOP' else []
main_screen = Screen(
    top=bar.Bar(
        [
            # widget.CurrentLayout(),
            widget.GroupBox(
                highlight_method = "line",
            ),
            widget.TextBox(
                text = '|',
                foreground = "#ffffff",
                padding = 2 
            ),
            widget.WindowName(**powerline),
            widget.Chord(
                chords_colors={
                    "launch": ("#ff0000", "#ffffff"),
                },
                name_transform=lambda name: name.upper(),
                **powerline
            ),
            widget.Prompt(**powerline),
            # widget.TextBox("default config", name="default"),
            # widget.TextBox("Press &lt;M-r&gt; to spawn", foreground="#d75f5f"),
            # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
            # widget.StatusNotifier(),
            # widget.Notify(),
            widget.Systray(**powerline),
            widget.TextBox("Network", foreground="#ffffff", background = "#303F9F", **powerline),
            widget.NetGraph(graph_color = "#ffffff", background = "#303F9F", **powerline),
            widget.TextBox("CPU", foreground="#ffffff", background = "#E64A19", **powerline),
            widget.CPUGraph(graph_color = "#ffffff", background = "#E64A19", **powerline),
        ] +
        (
            [widget.Battery(background = "#FF4081", **powerline)] if os.environ.get('DEVICE_TYPE', 'DESKTOP') == 'LAPTOP' else []
        ) +
        [
            widget.Clock(format="%d-%m-%Y %a %I:%M %p", background = "#303F9F"),
        ],
        24,
        # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
        # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
    ),
    wallpaper_mode='stretch',
    wallpaper='~/.config/qtile/wallpaper.jpg',
    # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
    # By default we handle these events delayed to already improve performance, however your system might still be struggling
    # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
    # x11_drag_polling_rate = 60,
)

secondary_screen = Screen(
    top=bar.Bar(
        [
            # widget.CurrentLayout(),
            widget.GroupBox(
                highlight_method = "line",
            ),
            widget.TextBox(
                text = '|',
                foreground = "#ffffff",
                padding = 2 
            ),
            widget.WindowName(),
            widget.Chord(
                chords_colors={
                    "launch": ("#ff0000", "#ffffff"),
                },
                name_transform=lambda name: name.upper(),
            ),
            # widget.TextBox("default config", name="default"),
            # widget.TextBox("Press &lt;M-r&gt; to spawn", foreground="#d75f5f"),
            # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
            # widget.StatusNotifier(),
            # widget.Systray(),
            # widget.
        ],
        24,
        # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
        # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
    ),
    wallpaper_mode='stretch',
    wallpaper='~/.config/qtile/wallpaper.jpg',
    # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
    # By default we handle these events delayed to already improve performance, however your system might still be struggling
    # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
    # x11_drag_polling_rate = 60,
)

screens = [
    secondary_screen,
    main_screen
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
