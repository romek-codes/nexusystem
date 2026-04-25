{ config, ... }: {
  virtualisation.docker = {
    enable = true;
    # Start dockerd on first use via docker.socket instead of blocking boot.
    enableOnBoot = false;
  };
  users.users."${config.var.username}".extraGroups = [ "docker" ];
}
