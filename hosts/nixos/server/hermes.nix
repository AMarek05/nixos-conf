# Hermes Agent Container Guest OS Configuration
# A minimal NixOS VM that runs Hermes Agent in a hardened nspawn container
{
  pkgs,
  config,
  inputs,
  ...
}:

let
  inherit (config.sops.secrets) "minimax-api-key";
in

{
  imports = [
    inputs.hermes-agent.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  # ── Static networking on the virtual ethernet (ve-+) ───────────────────
  networking.hostName = "hermes";
  networking.usePredictableInterfaceNames = false;

  networking.interfaces.eth.ipv4.addresses = [
    {
      address = "192.168.100.12";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "192.168.100.10";
  networking.nameservers = [ "10.20.20.5" ];

  # ── SOPS ────────────────────────────────────────────────────────────────
  sops.age.sshKeyPaths = [ "/var/lib/sops-nix/age_key" ];

  sops.secrets."minimax-api-key" = {
    sopsFile = ../../../secrets/openclaw.yaml;
  };

  # ── Hermes Agent service ──────────────────────────────────────────────
  services.hermes-agent = {
    enable = true;

    # hermes-agent package provides the `hermes` CLI; runtime deps
    # (Node.js, Python, uv) are provisioned by the entrypoint on first boot.
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Use the NixOS module's native systemd mode (NOT container mode).
    # The nspawn container itself provides isolation; hermes runs as a
    # systemd service inside the guest OS.
    container.enable = false;

    user = "hermes";
    group = "hermes";
    createUser = true;

    stateDir = "/var/lib/hermes";

    settings = {
      # Model: MiniMax M2.7 via global endpoint
      # MINIMAX_API_KEY is sourced from ~/.hermes/.env (injected via environmentFile below)
      model = "minimax/MiniMax-M2.7";

      # Gateway bind — LAN interface so host Caddy can reach it
      gateway.bind = "lan";

      # Disable default OpenAI provider
      providers.openai = null;
    };

    # Inject MINIMAX_API_KEY into ~/.hermes/.env so Hermes picks it up
    environment = {
      MINIMAX_API_KEY = "@minimax-api-key@";
    };
  };

  # ── Network ───────────────────────────────────────────────────────────
  # Hermes gateway listens on port 8080 by default
  networking.firewall.allowedTCPPorts = [ 8080 ];

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}