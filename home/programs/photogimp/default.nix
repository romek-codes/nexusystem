{ pkgs, ... }: {
  # Fetch PhotoGIMP configuration files from GitHub and install to ~/.config/GIMP/2.10/
  xdg.configFile."GIMP/2.10" = {
    source = pkgs.fetchFromGitHub {
      owner = "Diolinux";
      repo = "PhotoGIMP";
      rev =
        "photogimp-2.10"; # update revision to master when gimp 3.0 is in nixpkgs
      sha256 = "sha256-tWbkHf0Es/I0oLooep+GIFhFXWgGxanBUUCpzHMzC1I=";
    }
      + "/.var/app/org.gimp.GIMP/config/GIMP/2.10"; # update path when gimp 3.0 is in nixpkgs
  };

  # TODO: Fix permission and dynamically linked executable errors.
  # TODO: Maybe trying gimp3 might be a good idea? Might get automatically fixed.
  home.packages = with pkgs;
    [
      gimp # gnu image manipulation program
    ];
}
