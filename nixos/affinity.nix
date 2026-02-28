{ inputs, ... }: {
  environment.systemPackages = [ inputs.affinity-nix.packages.x86_64-linux.v3 ];
}
