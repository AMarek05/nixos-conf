# boot/loader.nix — grub EFI boot loader configuration
{ pkgs, lib, config }:
let
  cfg = config.modules.boot.loader;
in
{
  config = lib.mkIf cfg.enable {
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.timeout = null;

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
  };
}
