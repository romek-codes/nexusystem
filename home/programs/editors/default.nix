{ config, pkgs, lib, ... }:
let
  helpers = import ../../../helpers { inherit lib; };

  installEditor = editor:
    if editor == "nvim" || editor == "vscode" then
      [ ]
    else
      [ (lib.getAttrFromPath (lib.splitString "." editor) pkgs) ];

  allEditors = builtins.concatLists (map installEditor config.var.editors);
  mainEditor = builtins.head config.var.editors;
  mainEditorBinary = helpers.getOrBasename helpers.editorBinaryMap mainEditor;
in {
  imports = [ ./nvim ./vscode ];

  home.packages = allEditors;
  home.sessionVariables.EDITOR = mainEditorBinary;
}
