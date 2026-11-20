{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  environment.sessionVariables.DEVICE_TYPE = "DESKTOP";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    # powerManagement.enable = false;
    # powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "guillem" ];

  users.users.guillem.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILB/q9xX95SLDHLZKk8A+a3ZvO+DfA/Cv+MCuZqnjtgb guillem@thinkpad"
  ];

  services.claudeRemoteControl.repos = {
    pimpampum.path = "/home/guillem/pimpampum";
  };
}
