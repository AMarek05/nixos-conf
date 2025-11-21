{ ... }:
{
  programs = {
    tmux = {
      enable = true;

      shortcut = "a";
      newSession = true;
    };

    ghostty = {
      enable = true;
    };
  };
}
