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
    owner = "hermes";
  };

  sops.templates."hermes-env" = {
    owner = "hermes";
    group = "hermes";
    content = ''
      MINIMAX_API_KEY=${config.sops.placeholder."minimax-api-key"}
    '';
  };

  # ── Hermes Agent service ──────────────────────────────────────────────
  # The hermes module's activation script writes cfg.environment and
  # cfg.environmentFiles to ~/.hermes/.env (via load_hermes_dotenv at Python
  # startup). hermes-agent's own _HERMES_PROVIDER_ENV_BLOCKLIST scrubs
  # MINIMAX_API_KEY from tool subprocess environments.
  #
  # We use EnvironmentFile=/run/secrets/minimax-api-key — sops-nix decrypts
  # the secret here at runtime (systemd tmpfiles.d), and systemd's
  # EnvironmentFile= injects it into the service process env. The activation
  # script also writes the same path to ~/.hermes/.env for load_hermes_dotenv.
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

    # Use the hermes module's own environmentFiles option — it writes the
    # template to ~/.hermes/.env at activation, which hermes reads via
    # load_hermes_dotenv() at startup. The blocklist scrub prevents
    # MINIMAX_API_KEY from reaching tool subprocesses.
    environmentFiles = [
      config.sopsTemplates."hermes-env".path
    ];
  };

  # ── Network ───────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [ 8080 ];

  # ── Timezone ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";
  system.stateVersion = "24.11";
}