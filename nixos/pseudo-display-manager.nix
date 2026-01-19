{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/start-hyprland";
        user = config.var.username;
      };
    };
  };
}
