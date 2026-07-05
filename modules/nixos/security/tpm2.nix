{ lib, config, pkgs, ... }:
{
  config = lib.mkIf (config.nixosModules.security.enable && config.nixosModules.security.tpm2.enable) {
    security.tpm2 = {
      enable = true;
      abrmd.enable = true;
      pkcs11.enable = true;
      applyUdevRules = true;
    };

    programs.ssh.startAgent = true;

    systemd.user.services.ssh-agent = {
      environment = {
        TPM2_PKCS11_STORE = "/var/lib/tpm2-pkcs11";
        TPM2_PKCS11_BACKEND = "esysdb";
        TPM2TOOLS_TCTI = "tabrmd:bus_type=system";
      };

      serviceConfig = {
        Type = lib.mkForce "forking";
        ExecStart = lib.mkForce "${pkgs.openssh}/bin/ssh-agent -a %t/ssh-agent -P /nix/store/*,/run/current-system/sw/lib/*";
      };
    };

    users.users.adam.extraGroups = [ "tss" ];

    environment.systemPackages = with pkgs; [
      sops
      ssh-to-age
      tpm2-tools
      pkcs11-provider
      opensc
    ];

    environment.sessionVariables = {
      TPM2_PKCS11_STORE = "/var/lib/tpm2-pkcs11";
      TPM2_PKCS11_BACKEND = "esysdb";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
    };

    systemd.tmpfiles.rules = [
      # Type  Path                  Mode  User  Group  Age  Argument
      "d      /var/lib/tpm2-pkcs11  0700  adam  tss    -    -"
    ];
  };
}
