# Themes

Themes live in `themes/` and define the visual defaults used by Hyprland and most apps (colors, fonts, cursor, wallpaper, bar, boot splash).
Each host selects a theme by importing it from `hosts/<name>/variables.nix`.

## What's in the example theme

The `themes/example.nix` file shows all supported knobs:

- `backgroundImage`: static or animated wallpaper, including `pkgs.fetchurl` examples.
- `base16Scheme`: use a named scheme (from the tinted gallery) or an inline custom scheme.
- `polarity`: `dark` or `light`, used for icon/theme choices and Stylix generation.
- Window feel: rounding, gaps, opacity, blur, border size, animation speed, fetch tool.
- Bar: position, transparency, floating mode, button styling.
- Boot splash (Plymouth): enablement, theme selection, and theme packages.
- Cursor and fonts: cursor package/name/size, mono/sans/emoji fonts, and sizes.

## Add your own theme

1. Copy `themes/example.nix` to `themes/<your-theme>.nix`.
2. Edit the values you care about (wallpaper, colors, fonts, etc.).
3. In `hosts/<name>/variables.nix`, replace the theme import with your new file.

## Gallery

### Example theme

![nvim / yt music](assets/images/nvim-yt-music.png)
![zen browser / command palette](assets/images/zen-browser-and-command-palette.png)
![qdirstat / planify](assets/images/qdirstat-planify.png)
![gaming](assets/images/gaming.png)
