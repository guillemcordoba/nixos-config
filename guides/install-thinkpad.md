# Installing NixOS on the ThinkPad X1 Carbon Gen 9

Boot the NixOS installer, then partition and format the disk, and mount it at `/mnt` with the EFI partition at `/mnt/boot`.

```bash
sudo mkdir -p /mnt/home/guillem
sudo git clone https://github.com/guillemcordoba/nixos-config /mnt/home/guillem/nixos-config
cd /mnt/home/guillem/nixos-config

sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee hosts/thinkpad/hardware-configuration.nix
sudo git add hosts/thinkpad/hardware-configuration.nix

sudo nixos-install --flake .#thinkpad
```

The flake only sees files git knows about, so the `git add` is required.

`nixos-install` only asks for the root password, so set the user's password before rebooting, and hand the clone over to the user:

```bash
sudo nixos-enter --root /mnt -c 'passwd guillem'
sudo nixos-enter --root /mnt -c 'chown -R guillem:users /home/guillem'
```

After the first boot, commit the hardware file. From then on, `sudo nixos-rebuild switch --flake .` picks the config from the hostname.
