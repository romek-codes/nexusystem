{
  lib,
  stdenv,
  fetchPnpmDeps,
  pnpm_10,
  pnpmConfigHook,
  nodejs,
  makeWrapper,
  src,
  version,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "happy";
  inherit version src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    pnpmWorkspaces = [
      "happy"
      "@slopus/happy-wire"
    ];
    fetcherVersion = 3;
    hash = "sha256-STnqzVxClUfuf2la2R6yeIrNbaXsTpT6tX9xUJoLsK4=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    pnpm --filter happy... build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    installRoot=$out/lib/happy

    mkdir -p "$installRoot/packages"
    cp package.json "$installRoot/"
    cp pnpm-workspace.yaml "$installRoot/"
    cp -r node_modules "$installRoot/"
    cp -r packages/happy-cli "$installRoot/packages/"
    cp -r packages/happy-wire "$installRoot/packages/"

    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs} $out/bin/happy \
      --add-flags "$installRoot/packages/happy-cli/bin/happy.mjs"
    makeWrapper ${lib.getExe nodejs} $out/bin/happy-mcp \
      --add-flags "$installRoot/packages/happy-cli/bin/happy-mcp.mjs"

    runHook postInstall
  '';

  meta = {
    description = "Mobile and web client wrapper for Claude Code and Codex with end-to-end encryption";
    homepage = "https://github.com/slopus/happy";
    license = lib.licenses.mit;
    mainProgram = "happy";
  };
})
