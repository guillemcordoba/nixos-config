{ inputs, pkgs, ... }: {
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri.package = pkgs.niri;

  imports = [ inputs.niri.nixosModules.niri ];

  programs.niri.enable = true;
  environment.systemPackages = with pkgs; [
    xwayland-satellite-unstable
  ];

  # security.soteria.enable = true;

  # programs.niri.settings = {
  #   input.keyboard.xkb.layout = "no";
  #   input.mouse.accel-speed = 1.0;
  #   input.touchpad = {
  #     tap = true;
  #     dwt = true;
  #     natural-scroll = true;
  #     click-method = "clickfinger";
  #   };

  #   # input.mouse.scroll-factor = 3;

  #   # config-notification.disable-failed = true;

  #   clipboard.disable-primary = true;

  #   prefer-no-csd = true;

  #   layout = {
  #     gaps = 16;
  #     struts.left = 64;
  #     struts.right = 64;

  #     always-center-single-column = true;

  #     empty-workspace-above-first = true;

  #     # fog of war
  #     focus-ring = {
  #       enable = false;
  #       width = 10000;
  #       active.color = "#00000055";
  #     };

  #     border = {
  #       enable = true;
  #       width = 4;
  #     };

  #     # border.active.gradient = {
  #     #   from = "red";
  #     #   to = "blue";
  #     #   in' = "oklch shorter hue";
  #     # };

  #     shadow.enable = true;

  #     # default-column-display = "tabbed";

  #     tab-indicator = {
  #       position = "top";
  #       gaps-between-tabs = 10;

  #       # hide-when-single-tab = true;
  #       # place-within-column = true;

  #       # active.color = "red";
  #     };
  #   };

  #   overview.zoom = 0.5;

  #   animations.window-resize.custom-shader = builtins.readFile ./resize.glsl;

  #   window-rules = [{
  #     draw-border-with-background = false;
  #     geometry-corner-radius = let r = 8.0;
  #     in {
  #       top-left = r;
  #       top-right = r;
  #       bottom-left = r;
  #       bottom-right = r;
  #     };
  #     clip-to-geometry = true;
  #   }];

  #   xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
  #   screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

  #   binds = lib.attrsets.mergeAttrsList [
  #     {
  #       "Mod+T".action.spawn = "alacritty";
  #       "Mod+O".action.show-hotkey-overlay = [ ];
  #       "Mod+D".action.spawn = "fuzzel";
  #       # "Mod+W".action = sh (
  #       #   builtins.concatStringsSep "; " [
  #       #     "systemctl --user restart waybar.service"
  #       #   ]
  #       # );

  #       "Mod+L".action.spawn = "blurred-locker";

  #       "Mod+Shift+S".action.screenshot = [ ];
  #       "Print".action.screenshot-screen = [ ];
  #       "Mod+Print".action.screenshot-window = [ ];

  #       "Mod+Insert".action.set-dynamic-cast-window = [ ];
  #       "Mod+Shift+Insert".action.set-dynamic-cast-monitor = [ ];
  #       "Mod+Delete".action.clear-dynamic-cast-target = [ ];

  #       "XF86AudioRaiseVolume".action.spawn-sh =
  #         "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
  #       "XF86AudioLowerVolume".action.spawn-sh =
  #         "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
  #       "XF86AudioMute".action.spawn-sh =
  #         "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

  #       "XF86MonBrightnessUp".action.spawn-sh = "brightnessctl set 10%+";
  #       # "XF86MonBrightnessUp".hotkey-overlay.title = "awawa";
  #       "XF86MonBrightnessDown".action.spawn-sh = "brightnessctl set 10%-";
  #       # "XF86MonBrightnessDown".hotkey-overlay.hidden = true;

  #       "Mod+Q".action.close-window = [ ];

  #       "Mod+Space".action.toggle-column-tabbed-display = [ ];

  #       "XF86AudioNext".action.focus-column-right = [ ];
  #       "XF86AudioPrev".action.focus-column-left = [ ];

  #       "Mod+Tab".action.focus-window-down-or-column-right = [ ];
  #       "Mod+Shift+Tab".action.focus-window-up-or-column-left = [ ];
  #     }
  #     # (binds {
  #     #   suffixes."Left" = "column-left";
  #     #   suffixes."Down" = "window-down";
  #     #   suffixes."Up" = "window-up";
  #     #   suffixes."Right" = "column-right";
  #     #   prefixes."Mod" = "focus";
  #     #   prefixes."Mod+Ctrl" = "move";
  #     #   prefixes."Mod+Shift" = "focus-monitor";
  #     #   prefixes."Mod+Shift+Ctrl" = "move-window-to-monitor";
  #     #   substitutions."monitor-column" = "monitor";
  #     #   substitutions."monitor-window" = "monitor";
  #     # })
  #     # {
  #     #   "Mod+V".action.switch-focus-between-floating-and-tiling = [ ];
  #     #   "Mod+Shift+V".action.toggle-window-floating = [ ];
  #     # }
  #     # (binds {
  #     #   suffixes."Home" = "first";
  #     #   suffixes."End" = "last";
  #     #   prefixes."Mod" = "focus-column";
  #     #   prefixes."Mod+Ctrl" = "move-column-to";
  #     # })
  #     # (binds {
  #     #   suffixes."U" = "workspace-down";
  #     #   suffixes."I" = "workspace-up";
  #     #   prefixes."Mod" = "focus";
  #     #   prefixes."Mod+Ctrl" = "move-window-to";
  #     #   prefixes."Mod+Shift" = "move";
  #     # })
  #     # (binds {
  #     #   suffixes = builtins.listToAttrs (map (n: {
  #     #     name = toString n;
  #     #     value = [
  #     #       "workspace"
  #     #       (n + 1)
  #     #     ]; # workspace 1 is empty; workspace 2 is the logical first.
  #     #   }) (lib.range 1 9));
  #     #   prefixes."Mod" = "focus";
  #     #   prefixes."Mod+Ctrl" = "move-window-to";
  #     # })
  #     {
  #       "Mod+Comma".action.consume-window-into-column = [ ];
  #       "Mod+Period".action.expel-window-from-column = [ ];

  #       "Mod+R".action.switch-preset-column-width = [ ];
  #       "Mod+F".action.maximize-column = [ ];
  #       "Mod+Shift+F".action.fullscreen-window = [ ];
  #       "Mod+C".action.center-column = [ ];

  #       "Mod+Minus".action.set-column-width = "-10%";
  #       "Mod+Plus".action.set-column-width = "+10%";
  #       "Mod+Shift+Minus".action.set-window-height = "-10%";
  #       "Mod+Shift+Plus".action.set-window-height = "+10%";

  #       "Mod+Shift+Escape".action.toggle-keyboard-shortcuts-inhibit = [ ];
  #       "Mod+Shift+E".action.quit = [ ];
  #       "Mod+Shift+P".action.power-off-monitors = [ ];

  #       "Mod+Shift+Ctrl+T".action.toggle-debug-tint = [ ];
  #     }
  #   ];
  # };
  # services.mako = {
  #   enable = true;
  #   borderRadius = 8;
  #   format = "%a\n%s\n%b";
  # };

  # services.swaync = { enable = true; };
}
