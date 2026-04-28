{ lib, ... }:

rec {
  parseBase16Yaml = yamlPath:
    let
      lines = lib.splitString "\n" (builtins.readFile yamlPath);
      parseLine = line:
        let match = builtins.match ''(base[0-9A-F]{2}):[[:space:]]*"?#?([0-9a-fA-F]{6})"?.*'' line;
        in
        if match == null then
          null
        else
          {
            name = lib.elemAt match 0;
            value = "#${lib.toLower (lib.elemAt match 1)}";
          };
      entries = builtins.filter (entry: entry != null) (map parseLine lines);
    in
    builtins.listToAttrs (map (entry: lib.nameValuePair entry.name entry.value) entries);

  resolveBase16Scheme = pkgs: scheme:
    if builtins.isString scheme then
      parseBase16Yaml "${pkgs.base16-schemes}/share/themes/${scheme}.yaml"
    else
      scheme;

  withPolarity = polarity: scheme:
    let
      normalized = builtins.mapAttrs (_: value:
        if lib.hasPrefix "#" value then lib.toLower value else "#${lib.toLower value}"
      ) scheme;
      accents = builtins.intersectAttrs {
        base08 = null;
        base09 = null;
        base0A = null;
        base0B = null;
        base0C = null;
        base0D = null;
        base0E = null;
        base0F = null;
      } normalized;
      darkNeutrals = {
        base00 = "#010400";
        base01 = "#161616";
        base02 = "#202020";
        base03 = "#6f7689";
        base04 = "#585b70";
        base05 = "#cdd6f4";
        base06 = "#ffffff";
        base07 = "#b4befe";
      };
      lightNeutrals = {
        base00 = "#ffffff";
        base01 = "#f3f5f7";
        base02 = "#e5e9ef";
        base03 = "#5f6b7a";
        base04 = "#374151";
        base05 = "#111827";
        base06 = "#0b1220";
        base07 = "#000000";
      };
    in
    (if polarity == "light" then lightNeutrals else darkNeutrals) // accents;

  isStaticImage = path:
    let
      pathStr = if builtins.isPath path then toString path else path;
      lower = lib.strings.toLower pathStr;
      staticExtensions =
        [ ".jpg" ".jpeg" ".png" ".bmp" ".tiff" ".webp" ".svg" ];
    in lib.any (ext: lib.strings.hasSuffix ext lower) staticExtensions;

  isGif = path:
    if builtins.isString path then
      let
        lower = lib.strings.toLower path;
        staticExtensions = [ ".gif" ];
      in lib.any (ext: lib.strings.hasSuffix ext lower) staticExtensions
    else
      false;

  isEmpty = value: value == null || value == false || value == "";

  # Retrieves the value from the map (browserBinaryMap etc.), if not found, returns the last part of value (by dot).
  # Examples:
  # google-chrome -> google-chrome-stable
  # jetbrains.webstorm -> webstorm
  # nvim -> nvim
  getOrBasename = map: key: map.${key} or (lib.last (lib.splitString "." key));

  # These are important so that the $BROWSER and $EDITOR variables can correctly be set so they're used as default apps,
  # and also so they can be started from the command palette.
  browserBinaryMap = {
    zen = "zen-beta";
    ungoogled-chromium = "chromium";
    google-chrome = "google-chrome-stable";
  };

  # For getting the correct icon name, to show in command palette.
  # If you want to find icons, go to /nix/store, fzf for WhiteSur (or the icon theme you're using if you changed it), and go into that directory.
  # From there, look for an icon using fzf, and open it using "open /path/to/icon.svg"
  browserIconMap = {
    zen = "zen-browser";
    ungoogled-chromium = "chromium";
  };

  editorBinaryMap = { vscode = "code"; };
}
