# Installing NixOS on the ThinkPad X1 Carbon Gen 9

Dual boot with Windows on a new 1 TB SSD, cloned from the original Windows SSD with a USB NVMe enclosure.

The disk ends up as:

| Partition | What | Mounted at |
| --- | --- | --- |
| p1 | Windows ESP (260 MB), holds systemd-boot and the Windows boot manager | `/efi` |
| p2 | Microsoft reserved | |
| p3 | Windows C: | |
| p4 | Windows recovery | |
| p5 | XBOOTLDR (1 GB, FAT32), holds NixOS kernels and initrds | `/boot` |
| p6 | LUKS, ext4 root | `/` |

The ESP is too small for several NixOS kernels, hence the separate XBOOTLDR partition. `hosts/thinkpad/default.nix` sets the matching mount points.

Use the latest stable NixOS ISO. Its version doesn't matter: `nixos-install --flake` builds the system from the nixpkgs pinned in `flake.lock`.

## 0. Prepare Windows (old SSD)

In an admin terminal:

```powershell
manage-bde -protectors -get C:
manage-bde -protectors -disable C: -RebootCount 0
powercfg /h off
reg add "HKLM\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
```

- Write down the BitLocker recovery password somewhere off the laptop. Cloning and turning Secure Boot off can make Windows ask for it.
- `-RebootCount 0` keeps BitLocker suspended until it is re-enabled in step 5.
- `powercfg /h off` disables hibernation and Fast Startup, so NTFS is left cleanly closed.
- `RealTimeIsUniversal` makes Windows keep the hardware clock in UTC like NixOS, otherwise the clock is off by an hour after switching OS.

In the BIOS (F1 at power-on):

- Security → Secure Boot → Off. The NixOS installer doesn't boot with it on.
- Config → Power → Disable built-in battery, before opening the case. Plugging in the charger turns it back on.

## 1. Clone

With the old SSD still inside, boot the live USB (F12 for the boot menu) and connect the new SSD in the enclosure.

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,LOG-SEC
```

The source is `nvme0n1`. The target is the `sdX` disk with `TRAN=usb`. Both must show `LOG-SEC` 512: some enclosures present 4096-byte sectors, and then the partition table is wrong once the drive is inside the laptop.

```bash
sudo dd if=/dev/nvme0n1 of=/dev/sdX bs=16M status=progress conv=fsync oflag=direct
sudo sgdisk -e /dev/sdX
sudo sgdisk -v /dev/sdX
```

`sgdisk -e` moves the backup GPT to the real end of the bigger disk.

The clone shares partition GUIDs with the original, so never boot Windows with both drives connected.

## 2. Swap

Power off and swap the M.2 2280 drives (5 captive screws on the bottom cover, one screw on the drive). Keep the old SSD as a backup.

Boot Windows once to check it works. Disk Management should show the extra space as unallocated at the end of the disk.

## 3. Partition the free space

Boot the live USB again. Check that Windows uses p1–p4 and adjust the numbers below if not:

```bash
sudo sgdisk -p /dev/nvme0n1
```

```bash
sudo sgdisk -n 5:0:+1G -t 5:ea00 -c 5:XBOOTLDR /dev/nvme0n1
sudo sgdisk -n 6:0:0   -t 6:8309 -c 6:nixos    /dev/nvme0n1

sudo mkfs.vfat -F 32 -n XBOOTLDR /dev/nvme0n1p5
sudo cryptsetup luksFormat /dev/nvme0n1p6
sudo cryptsetup open /dev/nvme0n1p6 cryptroot
sudo mkfs.ext4 -L nixos /dev/mapper/cryptroot

sudo mount /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/efi /mnt/boot
sudo mount -o umask=0077 /dev/nvme0n1p1 /mnt/efi
sudo mount -o umask=0077 /dev/nvme0n1p5 /mnt/boot
```

## 4. Install

Connect to wifi (see `guides/wifi.md`), then:

```bash
sudo mkdir -p /mnt/home/guillem
sudo git clone https://github.com/guillemcordoba/nixos-config /mnt/home/guillem/nixos-config
cd /mnt/home/guillem/nixos-config

sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee hosts/thinkpad/hardware-configuration.nix
sudo git add hosts/thinkpad/hardware-configuration.nix
```

The flake only sees files git knows about, so the `git add` is required.

Check that the generated file has a `boot.initrd.luks.devices."cryptroot"` entry and `fileSystems` entries for both `/efi` and `/boot`. Then:

```bash
sudo nixos-install --flake .#thinkpad
```

`nixos-install` only asks for the root password, so set the user's password before rebooting, and hand the clone over to the user:

```bash
sudo nixos-enter --root /mnt -c 'passwd guillem'
sudo nixos-enter --root /mnt -c 'chown -R guillem:users /home/guillem'
```

## 5. After the first boot

- The systemd-boot menu lists NixOS and Windows Boot Manager. Windows is found automatically because systemd-boot is on the same ESP.
- Boot Windows from that menu and re-enable BitLocker with `manage-bde -protectors -enable C:`, so it seals to the boot path through systemd-boot. If it still asks for the recovery key on every boot, the fix is Secure Boot with lanzaboote.
- If a Windows update puts Windows Boot Manager first in the boot order, fix it in the BIOS.
- Commit `hosts/thinkpad/hardware-configuration.nix`. From then on, `sudo nixos-rebuild switch --flake .` picks the config from the hostname.
- Wipe the old SSD once the new setup has proven itself.
