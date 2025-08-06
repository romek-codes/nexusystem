{ inputs, pkgs, ... }: {
  wayland.windowManager.hyprland = {
    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
    ];
    settings = {
      plugin = {
        split-monitor-workspaces = { enable_persistent_workspaces = 0; };
      };
    };
  };
}
