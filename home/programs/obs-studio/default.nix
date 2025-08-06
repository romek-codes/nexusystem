{ pkgs, ... }: {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-composite-blur
      obs-vkcapture
    ];
    # plugins = [
    # (pkgs.wrapOBS {
    #   plugins = with pkgs.obs-studio-plugins; [
    #     obs-backgroundremoval
    #     obs-pipewire-audio-capture
    #     obs-composite-blur
    #   ];
    # })
    # ];
  };
}
