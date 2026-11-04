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

  services.claudeRemoteControl.repos = {
    pimpampum.path = "/home/guillem/pimpampum";
  };
}
