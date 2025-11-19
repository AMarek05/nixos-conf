{ pkgs, ...}:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      clang-tools
      gopls
      pyright
      jdt-language-server
      rust-analyzer
      zls
      lua-language-server
      stylua
      bash-language-server
      nixd
    ];
  };
}
