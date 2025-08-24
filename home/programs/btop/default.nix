{ pkgs, config, ... }: {
  home.packages = with pkgs;
    [
      (if config.var.gpu.type == "amd" then
      # rocmSupport is so that AMD GPU's can be shown.
        btop.override { rocmSupport = true; }
      else
        btop)
    ];

  xdg.configFile."btop/btop.conf".text = ''
    vim_keys = True
  '';
}
