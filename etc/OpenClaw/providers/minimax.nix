{
  config,
  lib,
  ...
}:

let
  cfg = config.services.openclaw;
in

{
  config = lib.mkIf (cfg.enable) {
    services.openclaw.extraConfig = {
      models = {
        mode = "merge";
        providers = {
          minimax = {
            api = "anthropic-messages";
            authHeader = true;

            baseUrl = "https://api.minimax.io/anthropic";
            models = [
              {
                id = "MiniMax-M2.7";
                name = "Minimax M2.7";
                reasoning = true;
                input = [
                  "text"
                  "image"
                ];
                cost = {
                  input = 0.3;
                  output = 1.2;
                  cacheRead = 0.06;
                  cacheWrite = 0.375;
                };
                contextWindow = 204800;
                maxTokens = 131072;
              }
            ];
          };
        };
      };
    };
  };
}
