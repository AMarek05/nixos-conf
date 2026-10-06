{
  model = "minimax/MiniMax-M3";
  gateway.bind = "lan";
  gateway.platforms.discord.gateway_restart_notification = false;

  providers.openai = null;

  discord = {
    enabled = true;
    token = "\${DISCORD_BOT_TOKEN}";
  };

  api_server = {
    enable = true;
    host = "0.0.0.0";
  };

  display = {
    show_reasoning = true;
    reasoning_full = true;
  };

  memory = {
    user_profile_enabled = true;
    memory_char_limit = 10000;
  };

  curator = {
    interval_hours = 24;
    min_idle_hours = 336;
    archive_after_days = 30;
  };

  kanban = {
    # keep cards in review
    review_dispatch = false;
    # have triage wait for input
    auto_decompose = false;
  };

  platform_toolsets.cli = [
    "hermes-cli"
    "kanban"
  ];

  agent = {
    disabled_toolsets = [
      "computer_use"
      "homeassistant"
      "discord_admin"
    ];

    task_completion_guidance = true;
    tool_use_enforcement = "auto";
    environment_probe = true;
  };
}
