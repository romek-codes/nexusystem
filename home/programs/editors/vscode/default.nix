{ pkgs, config, lib, ... }: {
  # For installing extensions declaratively
  # davi.sh/blog/2024/11/nix-vscode/
  config = lib.mkIf (builtins.elem "vscode" config.var.editors) {
    programs.vscode = {
      enable = true;
      profiles.default.userSettings = {
        "workbench.sideBar.location" = "right";
      };
    };
  };
}
