{ config, lib, ... }:
let
  rgb-to-hsl = color:
    let
      r = ((lib.toInt config.lib.stylix.colors."${color}-rgb-r") * 100.0) / 255;
      g = ((lib.toInt config.lib.stylix.colors."${color}-rgb-g") * 100.0) / 255;
      b = ((lib.toInt config.lib.stylix.colors."${color}-rgb-b") * 100.0) / 255;
      max = lib.max r (lib.max g b);
      min = lib.min r (lib.min g b);
      delta = max - min;
      fmod = base: int: base - (int * builtins.floor (base / int));
      h = if delta == 0 then
        0
      else if max == r then
        60 * (fmod ((g - b) / delta) 6)
      else if max == g then
        60 * (((b - r) / delta) + 2)
      else if max == b then
        60 * (((r - g) / delta) + 4)
      else
        0;
      l = (max + min) / 2;
      s = if delta == 0 then
        0
      else
        100 * delta / (100 - lib.max (2 * l - 100) (100 - (2 * l)));
      roundToString = value: toString (builtins.floor (value + 0.5));
    in lib.concatMapStringsSep " " roundToString [ h s l ];
in {
  services = {
    glance = {
      enable = true;
      settings = {
        theme = {
          # TODO: Maybe theming?
          # background-color = rgb-to-hsl "base0D";
          # primary-color = rgb-to-hsl "base0D";
          contrast-multiplier = lib.mkForce 1.4;
        };
        pages = [{
          hide-desktop-navigation = true;
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "bookmarks";
                  groups = [
                    {
                      title = "";
                      same-tab = true;
                      color = "200 50 50";
                      links = [
                        {
                          title = "Github";
                          url = "https://github.com/romek-codes/";
                        }
                        {
                          title = "Tutanota";
                          url = "https://tutanota.com/";
                        }
                        {
                          title = "Coolify";
                          url = "https://coolify.romek.codes/";
                        }
                        {
                          title = "Hetzner";
                          url = "https://console.hetzner.com/projects";
                        }
                        {
                          title = "Decodo";
                          url =
                            "https://dashboard.decodo.com/residential-proxies/statistics";
                        }
                        {
                          title = "PostHog";
                          url = "https://posthog.com";
                        }
                        {
                          title = "WhatsApp";
                          url = "https://web.whatsapp.com/";
                        }
                      ];
                    }
                    {
                      title = "Docs";
                      same-tab = true;
                      color = "200 50 50";
                      links = [
                        {
                          title = "Nixpkgs repo";
                          url = "https://github.com/NixOS/nixpkgs";
                        }
                        {
                          title = "Nixvim";
                          url = "https://nix-community.github.io/nixvim/";
                        }
                        {
                          title = "Hyprland wiki";
                          url = "https://wiki.hyprland.org/";
                        }
                        {
                          title = "Search NixOS";
                          url = "https://search.nixos.org/packages";
                        }
                      ];
                    }
                    {
                      title = "Helpful";
                      same-tab = true;
                      color = "200 50 50";
                      links = [
                        {
                          title = "Svgl";
                          url = "https://svgl.app";
                        }
                        {
                          title = "Cobalt (Downloader)";
                          url = "https://cobalt.tools";
                        }
                        {
                          title = "Mazanoke (Image optimizer)";
                          url = "https://mazanoke.com";
                        }
                      ];
                    }
                  ];
                }
                {
                  type = "rss";
                  limit = 10;
                  collapse-after = 3;
                  cache = "12h";
                  feeds = [
                    {
                      url = "https://selfh.st/rss/";
                      title = "selfh.st";
                      limit = 4;
                    }
                    { url = "https://ciechanow.ski/atom.xml"; }
                    {
                      url = "https://www.joshwcomeau.com/rss.xml";
                      title = "Josh Comeau";
                    }
                    { url = "https://samwho.dev/rss.xml"; }
                    {
                      url = "https://ishadeed.com/feed.xml";
                      title = "Ahmad Shadeed";
                    }
                  ];
                }
                {
                  type = "twitch-channels";
                  channels = [ "theprimeagen" ];
                }
                {
                  type = "releases";
                  cache = "1d";
                  repositories = [
                    # "NixOS/nixpkgs"
                    "hyprwm/hyprland"
                    "immich-app/immich"
                    "syncthing/syncthing"
                    "Aider-AI/aider"
                    "neovim/neovim"
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "group";
                  widgets = [{ type = "hacker-news"; }];
                }
                {
                  type = "videos";
                  channels = [
                    "UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
                    "UCsBjURrPoezykLs9EqgamOA" # Fireship
                    "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
                  ];
                }
                {
                  type = "group";
                  widgets = [
                    {
                      type = "reddit";
                      subreddit = "technology";
                      show-thumbnails = true;
                    }
                    {
                      type = "reddit";
                      subreddit = "selfhosted";
                      show-thumbnails = true;
                    }
                  ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "clock";
                  hour-format = "24h";
                }
                {
                  type = "weather";
                  location = "Recklinghausen, Germany";
                }
                {
                  type = "markets";
                  markets = [
                    {
                      symbol = "SPY";
                      name = "S&P 500";
                    }
                    {
                      symbol = "FTSE All World";
                      name = "VWCE.DE";
                    }
                    {
                      symbol = "BTC-USD";
                      name = "Bitcoin";
                    }
                    {
                      symbol = "NVDA";
                      name = "NVIDIA";
                    }
                    {
                      symbol = "AAPL";
                      name = "Apple";
                    }
                    {
                      symbol = "MSFT";
                      name = "Microsoft";
                    }
                    {
                      symbol = "GOOGL";
                      name = "Google";
                    }
                    {
                      symbol = "AMD";
                      name = "AMD";
                    }
                    {
                      symbol = "AMZN";
                      name = "AMAZON";
                    }
                  ];
                }
              ];
            }
          ];
          name = "Home";
        }];
        server = { port = 2048; };
      };
    };
  };
}
