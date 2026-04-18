{
  config,
  ...
}:
{
  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.4.11"
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.defaultSopsFile = ../secrets/openclaw.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.secrets."nim-api-key" = {
    owner = "openclaw";
  };

  services.openclaw = {
    enable = true;

    domain = "localhost";

    modelProvider = "openai";
    modelApiKeyFile = config.sops.secrets."nim-api-key".path;
  };

  systemd.services.openclaw.environment = {
    OPENAI_BASE_URL = "https://integrate.api.nvidia.com/v1";
    OPENAI_MODEL = "z-ai/glm5";
  };
}
