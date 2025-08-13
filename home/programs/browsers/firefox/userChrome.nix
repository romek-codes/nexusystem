{ config, ... }:
{
  css = ''
    :root {
      --zen-colors-primary: #${config.lib.stylix.colors.base01} !important;
      --zen-primary-color: #${config.lib.stylix.colors.base08} !important;
      --zen-colors-secondary: #${config.lib.stylix.colors.base01} !important;
      --zen-colors-tertiary: #${config.lib.stylix.colors.base02} !important;
      --zen-colors-border: #${config.lib.stylix.colors.base08} !important;
      --toolbarbutton-icon-fill: #${config.lib.stylix.colors.base08} !important;
      --lwt-text-color: #${config.lib.stylix.colors.base05} !important;
      --toolbar-field-color: #${config.lib.stylix.colors.base05} !important;
      --tab-selected-textcolor: #${config.lib.stylix.colors.base05} !important;
      --toolbar-field-focus-color: #${config.lib.stylix.colors.base05} !important;
      --toolbar-color: #${config.lib.stylix.colors.base05} !important;
      --newtab-text-primary-color: #${config.lib.stylix.colors.base05} !important;
      --arrowpanel-color: #${config.lib.stylix.colors.base05} !important;
      --arrowpanel-background: #${config.lib.stylix.colors.base00} !important;
      --sidebar-text-color: #${config.lib.stylix.colors.base05} !important;
      --lwt-sidebar-text-color: #${config.lib.stylix.colors.base05} !important;
      --lwt-sidebar-background-color: #${config.lib.stylix.colors.base03} !important;
      --toolbar-bgcolor: #${config.lib.stylix.colors.base01} !important;
      --newtab-background-color: #${config.lib.stylix.colors.base00} !important;
      --zen-themed-toolbar-bg: #${config.lib.stylix.colors.base02} !important;
      --zen-main-browser-background: #${config.lib.stylix.colors.base02} !important;
      --toolbox-bgcolor-inactive: #${config.lib.stylix.colors.base02} !important;
    }

    #permissions-granted-icon {
      color: #${config.lib.stylix.colors.base02} !important;
    }

    .sidebar-placesTree {
      background-color: #${config.lib.stylix.colors.base00} !important;
    }

    #zen-workspaces-button {
      background-color: #${config.lib.stylix.colors.base00} !important;
    }

    #TabsToolbar {
      background-color: #${config.lib.stylix.colors.base02} !important;
    }

    #urlbar-background {
      background-color: #${config.lib.stylix.colors.base00} !important;
    }

    .content-shortcuts {
      background-color: #${config.lib.stylix.colors.base00} !important;
      border-color: #${config.lib.stylix.colors.base08} !important;
    }

    .urlbarView-url {
      color: #${config.lib.stylix.colors.base08} !important;
    }

    #zenEditBookmarkPanelFaviconContainer {
      background: #${config.lib.stylix.colors.base03} !important;
    }

    #zen-media-controls-toolbar {
      & #zen-media-progress-bar {
        &::-moz-range-track {
          background: #${config.lib.stylix.colors.base01} !important;
        }
      }
    }

    toolbar .toolbarbutton-1 {
      &:not([disabled]) {
        &:is([open], [checked])
          > :is(
            .toolbarbutton-icon,
            .toolbarbutton-text,
            .toolbarbutton-badge-stack
          ) {
          fill: #${config.lib.stylix.colors.base03};
        }
      }
    }

    .identity-color-blue {
      --identity-tab-color: #${config.lib.stylix.colors.base0D} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base0D} !important;
    }

    .identity-color-turquoise {
      --identity-tab-color: #${config.lib.stylix.colors.base0C} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base0C} !important;
    }

    .identity-color-green {
      --identity-tab-color: #${config.lib.stylix.colors.base0B} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base0B} !important;
    }

    .identity-color-yellow {
      --identity-tab-color: #${config.lib.stylix.colors.base0A} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base0A} !important;
    }

    .identity-color-orange {
      --identity-tab-color: #${config.lib.stylix.colors.base09} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base09} !important;
    }

    .identity-color-red {
      --identity-tab-color: #${config.lib.stylix.colors.base08} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base08} !important;
    }

    .identity-color-pink {
      --identity-tab-color: #${config.lib.stylix.colors.base0E} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base0E} !important;
    }

    .identity-color-purple {
      --identity-tab-color: #${config.lib.stylix.colors.base0F} !important;
      --identity-icon-color: #${config.lib.stylix.colors.base0F} !important;
    }

    hbox#titlebar {
      background-color: #${config.lib.stylix.colors.base02} !important;
    }

    #zen-appcontent-navbar-container {
      background-color: #${config.lib.stylix.colors.base02} !important;
    }
  '';
}
