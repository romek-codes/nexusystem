: {
  home.file.".ssh/allowed_signers".text =
    "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRpvZVdMG/A99WjxY18LUCEF8OGi2ldzyl+gK/GuzLX";
  programs.git.extraConfig = {
    commit.gpgsign = true;
    gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    gpg.ormat = "ssh";
    user.signingkey = "~/.ssh/id_ed25519.pub";
  };
}
