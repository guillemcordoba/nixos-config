# Creating a bootable ISO image

```bash
nix build .#nixosConfigurations.guillem.config.system.build.isoImage
sudo dd if=result/iso/nixos-24.05.20240914.8f7492c-x86_64-linux.iso of=/dev/sdb bs=100M conv=sync,noerror status=progress
```


