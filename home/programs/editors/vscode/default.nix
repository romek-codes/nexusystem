{ pkgs, config, lib, ... }: {
  config = lib.mkIf (builtins.elem "vscode" config.var.editors) {
    programs.vscode = { enable = true; };
  };
}
