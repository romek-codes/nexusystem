{ config }:
let
  baseInstructions = builtins.readFile ./SYSTEM-AGENTS.md;
  configDirectory = toString config.var.configDirectory;
in
baseInstructions
+ ''

## Host configuration

- NixOS configuration directory: `${configDirectory}`
- When working on this machine's NixOS config, prefer that path over guessing a repo location.
''
