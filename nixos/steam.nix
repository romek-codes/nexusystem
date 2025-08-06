{ config, lib, ... }: {
  # I guess this can't be installed using home-manager, at least not in a straight forward way.
  # https://github.com/nix-community/home-manager/issues/4314
  config = lib.mkIf (config.var.withGames or false) {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };
  };
}
