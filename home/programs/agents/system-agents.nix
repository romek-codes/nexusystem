# liveImports: emit `@path` imports for jira.md/work.md (Claude Code reads them at session start,
# no rebuild needed to edit them). Codex has no import syntax, so it keeps them inlined.
{ config, liveImports ? false }:
let
  baseInstructions = builtins.readFile ./SYSTEM-AGENTS.md;
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
baseInstructions
+ ''

## Host configuration

- NixOS configuration directory: `${configDirectory}`
- When working on this machine's NixOS config, prefer that path over guessing a repo location.
${obsidianVaultLines}
${brunoCollectionLines}
''
