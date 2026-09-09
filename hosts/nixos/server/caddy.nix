{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mapAttrs';

  cfg = config.nixosModules.vhosts;

  vhostSubmodule = types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Target upstream address.";
      };

      port = mkOption {
        type = types.port;
        description = "Target upstream port.";
      };

      proxyConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Directives nested directly inside the reverse_proxy block.";
        example = ''
          header_up Host {upstream_hostport}
          header_up X-Real-IP {remote_host}
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional Caddyfile configuration appended to the host block.";
      };
    };
  };

  mkProxyBlock =
    v:
    let
      target = "${v.address}:${toString v.port}";
    in
    if v.proxyConfig == "" then
      "reverse_proxy ${target}"
    else
      ''
        reverse_proxy ${target} {
          ${v.proxyConfig}
        }
      '';
in
{
  options.nixosModules.vhosts = mkOption {
    type = types.attrsOf vhostSubmodule;
    default = { };
    description = "Simplified reverse proxy setup for amarek.pl";
  };

  config = {
    services.caddy.virtualHosts = mapAttrs' (name: v: {
      name = "${name}.amarek.pl";
      value = {
        useACMEHost = "amarek.pl";
        extraConfig = ''
          ${mkProxyBlock v}
          ${v.extraConfig}
        '';
      };
    }) cfg;

  };
}
