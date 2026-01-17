{ pkgs, config, lib, ... }: {
  config = lib.mkIf (builtins.elem "nvim" config.var.editors) {
    programs.neovim = {
      enable = true;
      withNodeJs = true;
      withPython3 = true;

      plugins = with pkgs.vimPlugins; [ nvim-treesitter.withAllGrammars ];

      extraPackages = with pkgs; [
        # Runtime dependencies
        ripgrep
        fd
        cargo
        gnumake
        unzip
        python3
        tree-sitter

        # Formatters
        mdformat
        black
        blade-formatter
        isort
        nixfmt
        # pint # installed using composer on a per project basis
        prettierd
        rustywind
        shfmt
        stylua
        intelephense
      ];
    };

    # Stylix + Symlink doesn't work well
    # https://github.com/nix-community/home-manager/issues/5175#issuecomment-2858394830
    stylix.targets.neovim.enable = false;

    # Stylix workaround
    home.file.".config/nvim/init.lua".text = ''
      -- Colors for lualine generated with nix
      colors = {
      bg       = '${config.lib.stylix.colors.base01}',
      fg       = '${config.lib.stylix.colors.base06}',
      yellow   = '#ECBE7B',
      cyan     = '#008080',
      darkblue = '#081633',
      green    = '#98be65',
      orange   = '#FF8800',
      violet   = '#a9a1e1',
      magenta  = '#c678dd',
      blue     = '${config.lib.stylix.colors.base0D}',
      red      = '#ec5f67',
      }

      require('real_init')

      -- Auto-generated base16 colorscheme from Nix
      require('mini.base16').setup({
          palette = {
            base00 = "#${config.lib.stylix.colors.base00}",
            base01 = "#${config.lib.stylix.colors.base01}",
            base02 = "#${config.lib.stylix.colors.base02}",
            base03 = "#${config.lib.stylix.colors.base03}",
            base04 = "#${config.lib.stylix.colors.base04}",
            base05 = "#${config.lib.stylix.colors.base05}",
            base06 = "#${config.lib.stylix.colors.base06}",
            base07 = "#${config.lib.stylix.colors.base07}",
            base08 = "#${config.lib.stylix.colors.base08}",
            base09 = "#${config.lib.stylix.colors.base09}",
            base0A = "#${config.lib.stylix.colors.base0A}",
            base0B = "#${config.lib.stylix.colors.base0B}",
            base0C = "#${config.lib.stylix.colors.base0C}",
            base0D = "#${config.lib.stylix.colors.base0D}",
            base0E = "#${config.lib.stylix.colors.base0E}",
            base0F = "#${config.lib.stylix.colors.base0F}"
          }
        })

    '';

    home.file.".config/nvim/after/ftplugin/markdown.lua".text = ''
      vim.opt_local.conceallevel = 2
    '';

    home.file.".config/nvim/lua" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.var.configDirectory}/home/programs/editors/nvim/lua";
      recursive = true;
    };

    # Treesitter parsers, declarative install.
    xdg.configFile."nvim/parser".source = "${
        pkgs.symlinkJoin {
          name = "treesitter-parsers";
          paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins:
            with plugins; [
              php
              python
              lua
              query
              typescript
              tsx
              javascript
              markdown
              markdown_inline
              bash
              regex
              nix
            ])).dependencies;
        }
      }/parser";
  };
}
