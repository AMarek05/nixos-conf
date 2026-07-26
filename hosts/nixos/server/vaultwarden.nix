{ ... }:
{
  services.vaultwarden = {
    enable = true;

    dbBackend = "postgresql";

    configurePostgres = true;

    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
    };
  };
}
