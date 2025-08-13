{ lib, ... }:

{
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
