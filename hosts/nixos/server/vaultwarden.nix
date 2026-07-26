{ ... }:
{
  services.vaultwarden = {
    enable = true;

    dbBackend = "postgresql";

    configurePostgres = true;
  };
}
