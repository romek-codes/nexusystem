# Discord is a popular chat application.
{ inputs, ... }: {
  #imports = [ inputs.nixcord.homeModules.nixcord ];

  # nixcord dont wanna work
  programs.vesktop = {
    enable = true;
    #config = { frameless = true; };
  };
}
