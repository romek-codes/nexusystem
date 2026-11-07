# Host-specific instructions. The shared instructions are linked directly from SYSTEM-AGENTS.md.
{ config }:
let
  configDirectory = toString config.var.configDirectory;
  obsidianVaults = config.var.obsidianVaults or [ ];
  brunoCollections = config.var.brunoCollections or [ ];
  obsidianVaultLines = if obsidianVaults == [ ] then "" else
    ''
- Obsidian vault directories:
'' + builtins.concatStringsSep "\n" (
        map (vault: "- `${toString vault.path}`${if vault ? name then " (${vault.name})" else ""}") obsidianVaults
      );
  brunoCollectionLines = if brunoCollections == [ ] then "" else
    ''
- Bruno collection directories:
'' + builtins.concatStringsSep "\n" (
        map (collection: "- `${toString collection.path}`${if collection ? name then " (${collection.name})" else ""}") brunoCollections
      );
in
''
## Host configuration

- NixOS configuration directory: `${configDirectory}`
- When working on this machine's NixOS config, prefer that path over guessing a repo location.
${obsidianVaultLines}
${brunoCollectionLines}
''
