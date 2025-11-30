{ pkgs, ... }: {
  hardware.sane = {
    enable = true;
    brscan5.enable = true;
  };
}
