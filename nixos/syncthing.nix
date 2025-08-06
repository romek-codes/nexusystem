{ config, ... }:
{
  services = {
    syncthing = {
      enable = true;
      user = config.var.username;
      dataDir = "/home/${config.var.username}/Documents"; # Default folder for new synced folders
      configDir =
        "/home/${config.var.username}/Documents/.config/syncthing"; # Folder for Syncthing's settings and keys
    };
  };
}
