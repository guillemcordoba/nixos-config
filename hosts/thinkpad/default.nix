{ inputs, pkgs, ... }:

{
  imports = [
    # Generated on the machine during install, see guides/install-thinkpad.md.
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];

  # Dual boot with Windows: the Windows ESP is only 260 MB, too small for
  # NixOS kernels. systemd-boot itself lives on the ESP (so it still finds
  # Windows), while kernels and initrds go to a 1 GB XBOOTLDR partition.
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";

  environment.sessionVariables.DEVICE_TYPE = "LAPTOP";

  # Suspend when the laptop lid is closed. Combined with the swayidle
  # `before-sleep` handler below, this means closing the lid locks
  # the session (and it stays locked on resume).
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  # This unit's left woofer buzzes above roughly -15 dB of output (measured
  # 2026-11-20; the right one is clean at full volume). DAC2 feeds only the
  # woofer pair and PipeWire only moves Master, so lowering its left channel
  # keeps that speaker under the threshold at any volume. Remove once the
  # speaker assembly is replaced.
  systemd.services.attenuate-left-woofer = {
    wantedBy = [ "sound.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.alsa-utils}/bin/amixer -c sofhdadsp sset DAC2 -- -10.5dB,0dB";
    };
  };

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

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        # Resolved by Tailscale MagicDNS, so it works away from home too.
        settings.workstation = {
          HostName = "workstation";
          User = "guillem";
          # Editors open many short-lived connections; reusing one keeps them instant.
          ControlMaster = "auto";
          ControlPath = "~/.ssh/control-%C";
          ControlPersist = "10m";
        };
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
