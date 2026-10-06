{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.image-proxy;
in
{
  options.services.image-proxy = {
    enable = lib.mkEnableOption "image-proxy, a SillyTavern-OpenAI to MiniMax translation service";

    port = lib.mkOption {
      type = lib.types.port;
      description = "TCP port for image-proxy. Must be set explicitly.";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind image-proxy to. Loopback by default.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "image-proxy";
      description = "User the image-proxy service runs as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "image-proxy";
      description = "Group the image-proxy service runs as.";
    };

    upstream = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "https://api.minimax.io/v1/image_generation";
        description = "MiniMax image generation endpoint.";
      };

      envFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to an EnvironmentFile containing MINIMAX_API_KEY.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."minimax-api-key" = {
      sopsFile = inputs.self + "/secrets/agent.yaml";
      owner = cfg.user;
      group = cfg.group;
    };

    sops.templates."image-proxy-env" = {
      owner = cfg.user;
      group = cfg.group;
      content = ''
        MINIMAX_API_KEY=${config.sops.placeholder."minimax-api-key"}
      '';
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = { };

    environment.systemPackages = [ pkgs.custom.image-proxy ];

    systemd.services.image-proxy = {
      description = "SillyTavern OpenAI to MiniMax image translation proxy";

      wantedBy = [ "multi-user.target" ];

      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];

      serviceConfig = {
        ExecStart = lib.getExe pkgs.custom.image-proxy;
        EnvironmentFile = cfg.upstream.envFile;
        Environment = [
          "IMAGE_PROXY_BIND=${cfg.bind}"
          "IMAGE_PROXY_PORT=${toString cfg.port}"
          "MINIMAX_IMAGE_URL=${cfg.upstream.url}"
        ];

        DynamicUser = false;
        User = cfg.user;
        Group = cfg.group;

        Restart = "no";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
      };
    };
  };
}
