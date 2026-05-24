{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./default.nix
    ./hardware/nixos-hardware.nix
    ./hardware/gpu/nvidia.nix

    inputs.aagl.nixosModules.default
  ];

  nixosModules.openclaw.enable = lib.mkForce true;
  nixosModules.sandbox.enable = lib.mkForce true;

  programs.sleepy-launcher.enable = true;

  networking.hostName = lib.mkForce "nixos";

  # No battery on desktop
  services.upower.enable = lib.mkForce false;

  fileSystems."/home/adam/media".options = [
    "rw"
    "nofail"
    "user"
    "exec"
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
    default = "saved";
    gfxmodeEfi = "keep";
    splashImage = null;
    theme = pkgs.sleek-grub-theme.override {
      withStyle = "dark";
      withBanner = "Hello, Adam";
    };
    useOSProber = false;
    extraEntriesBeforeNixOS = true;
    extraEntries = ''
      menuentry "Windows 11" --class windows --class os {
        savedefault
        insmod part_gpt
        insmod fat
        insmod search_fs_uuid
        insmod chain
        search --fs-uuid --set=root 8826-661B
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
    extraPerEntryConfig = ''
      set gfxpayload=text
      terminal_output console
      clear
    '';
    extraInstallCommands = ''
      ${pkgs.coreutils}/bin/cat <<'EOF' >> /boot/grub/grub.cfg
      menuentry "UEFI Firmware Settings" --class efi {
        fwsetup
      }
      EOF
    '';
  };

  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.timeout = null;
}