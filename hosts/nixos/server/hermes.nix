# Hermes Agent Container Guest OS Configuration
# A minimal NixOS VM that runs Hermes Agent in a hardened nspawn container
{
  pkgs,
  config,
  inputs,
  ...
}:

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
  # hermes-agent's own _HERMES_PROVIDER_ENV_BLOCKLIST (tools/environments/local.py)
  # scrubs MINIMAX_API_KEY from tool subprocess environments. So the key is
  # available to the hermes-gateway process (which needs it for API calls) but
  # blocked from reaching any tool subprocesses the agent spawns.
  services.hermes-agent = {
    enable = true;

    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    container.enable = false;

    user = "hermes";
    group = "hermes";
    createUser = true;

    stateDir = "/var/lib/hermes";

    settings = {
      model = "minimax/MiniMax-M2.7";
      gateway.bind = "lan";
      providers.openai = null;
    };

    # The module's activation script writes these to ~/.hermes/.env.
    # hermes reads it at startup via load_hermes_dotenv() — no .env file
    # ever appears in the store. The key is available to the gateway process
    # and scrubbed from tool subprocesses by _HERMES_PROVIDER_ENV_BLOCKLIST.
    environment = {
      MINIMAX_API_KEY = config.sops.secrets."minimax-api-key".path;
    };
  };

  # ── Network ───────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [ 8080 ];

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}