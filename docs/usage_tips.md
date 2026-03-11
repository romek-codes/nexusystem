# Usage Tips

## Essentials (Hyprland)

- Command palette: :material-microsoft-windows:
- Switch workspace: :material-microsoft-windows: + {number}
- Move window to workspace: SHIFT + :material-microsoft-windows: + {number}
- Program list: :material-microsoft-windows: + P
- Terminal: :material-microsoft-windows: + ENTER
- File manager: :material-microsoft-windows: + E
- Close window: :material-microsoft-windows: + Q
- Toggle fullscreen: :material-microsoft-windows: + F
- Toggle floating: :material-microsoft-windows: + T

More keybindings: [Keybindings](keybindings.md).

## Quick actions

- Rebuild from the command palette (apply changes after modifying config): `Nix helper -> Rebuild`

## Bitwarden (rbw) setup and important commands

`rbw` is the Bitwarden CLI used by the command palette (Bitwarden shortcut).

### First-time setup

```sh
rbw config set email you@example.com
rbw register
rbw login
rbw unlock
rbw sync
```

If you use a self-hosted Bitwarden/Vaultwarden, set the URL first:

```sh
rbw config set base_url https://your-bitwarden.example
```

### Use in the command palette

- Open the command palette (SUPER) and select Bitwarden.

## Bitwarden (rbw) quick commands

These are the most common actions:

```sh
rbw add            # Add a new entry
rbw edit <name>    # Edit an entry
rbw generate       # Generate a password (alias: rbw gen)
rbw sync           # Sync local database
```


## GitHub keys (SSH + GPG)

These keys let you push to GitHub securely and sign your commits so people can
verify they came from you.

### SSH key (GitHub)

```sh
ssh-keygen -t ed25519 -C "you@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Copy the public key and add it to GitHub:

```sh
cat ~/.ssh/id_ed25519.pub
```

Test:

```sh
ssh -T git@github.com
```

### GPG key (GitHub + commit signing)

Generate a key:

```sh
gpg --full-generate-key
```

Find your key ID (the long hex after `sec`):

```sh
gpg --list-secret-keys --keyid-format=long
```

Export the public key and add it to GitHub:

```sh
gpg --armor --export <KEYID>
```

Set your signing key in `hosts/<your-hostname>/variables.nix`:

```nix
git = {
  signingKey = "<KEYID>";
};
```

Note: use the key ID (not the armored block) for `signingKey`.
