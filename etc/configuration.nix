# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    # ./hardware-configuration.nix
    ./hyprland.nix
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  nix.settings.trusted-users = [
    "root"
    "adam"
  ];

  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
  };

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  networking.hostName = lib.mkDefault "nixos"; # Define your hostname.

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  systemd.services.NetworkManager-wait-online.enable = false;

  services.mullvad-vpn.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "pl_PL.UTF-8";
      LC_IDENTIFICATION = "pl_PL.UTF-8";
      LC_MEASUREMENT = "pl_PL.UTF-8";
      LC_MONETARY = "pl_PL.UTF-8";
      LC_NAME = "pl_PL.UTF-8";
      LC_PAPER = "pl_PL.UTF-8";
      LC_TELEPHONE = "pl_PL.UTF-8";
      LC_TIME = "pl_PL.UTF-8";
    };
  };
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  services.kmscon = {
    enable = false;
    hwRender = true;

    fonts = [
      {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      }
    ];
    extraConfig = "font-size=14";
  };

  console = {
    enable = true;
    packages = with pkgs; [ terminus_font ];

    font = "ter-v16n";

    keyMap = "us";
    # useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR

  security.rtkit.enable = true;

  security.pam.services.hyprlock = { };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 2048;
      };
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.adam = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "adbusers"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
    ];
  };

  # enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    git
    neovim

    man-pages

    rclone
    alsa-ucm-conf
    alsa-utils
  ];

  programs.adb.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # --- The Basics ---
    stdenv.cc.cc.lib # Standard C++ library (crucial)
    zlib # Compression (almost always needed)
    glib # Core C library

    # --- The Crash Fixes (Image & Graphics) ---
    libwebp
    SDL2 # Core graphics
    SDL2_image # Loads images (png, jpg, webp)
    SDL2_ttf # Fonts
    SDL2_mixer # Audio
    libpng
    libjpeg
    freetype
    fontconfig

    # --- X11 / Windowing (The game expects these to exist) ---
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXcursor # Mouse cursor support
    xorg.libXrandr # Resolution support
    xorg.libXinerama # Multi-monitor support
    xorg.libXi # Input devices
    xorg.libXScrnSaver

    # --- OpenGL & Audio ---
    libglvnd # OpenGL support
    alsa-lib # Audio support
    pulseaudio # Audio support

    # --- Video / Extras ---
    ffmpeg # Video playback (opening movies)
    dbus # System messaging (notifications)
    gtk3 # File pickers/dialogs (sometimes needed)
  ];

  programs.direnv = {
    enable = true;
    silent = true;

    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  services.flatpak.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };

  environment.pathsToLink = [ "/share/zsh/" ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
