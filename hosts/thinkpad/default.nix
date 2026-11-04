{ inputs, ... }:

{
  imports = [
    # Generated on the machine during install, see guides/install-thinkpad.md.
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];

  environment.sessionVariables.DEVICE_TYPE = "LAPTOP";

  # Suspend when the laptop lid is closed. Combined with the swayidle
  # `before-sleep` handler below, this means closing the lid locks
  # the session (and it stays locked on resume).
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  home-manager.users.guillem =
    { pkgs, ... }:
    {
      home.sessionVariables = {
        # Faster rust compilation in laptop
        CARGO_PROFILE_DEV_OPT_LEVEL = "0";
        CARGO_PROFILE_DEV_CODEGEN_UNITS = "256";
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "clang";
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
      };

      # Lock the screen after 1 minute idle and before the system sleeps
      # (e.g. when the laptop lid is closed). swayidle runs `loginctl
      # lock-session`; DankMaterialShell locks on that signal because its
      # loginctlLockIntegration is enabled by default.
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 60;
            command = "${pkgs.systemd}/bin/loginctl lock-session";
          }
        ];
        events = {
          before-sleep = "${pkgs.systemd}/bin/loginctl lock-session";
          lock = "${pkgs.systemd}/bin/loginctl lock-session";
        };
      };
    };
}
