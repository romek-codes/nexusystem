{ pkgs, inputs, config, lib, ... }: {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = config.var.username;
      };
    };
  };
}
