{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # rocmSupport is so that AMD GPU's can be shown.
    (btop.override { rocmSupport = true; }) # alternative to htop & ytop
  ];

  xdg.configFile."btop/btop.conf".text = ''
    vim_keys = True
  '';
}
