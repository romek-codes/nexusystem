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
    hash = "sha256-ys/ue045qRPZlvqrHf0zMlgWQi4GkhC4OGASAyyxbI0=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    makeWrapper
  ];

  postPatch = ''
    # Upstream leaks "which: no bun in (...)" to the terminal: findBunGlobalCliPath()
    # runs `which bun` via execSync without suppressing stdio, and execSync forwards
    # child stderr to the parent by default. The sibling `which claude` probe a few
    # lines up already suppresses stdio for this reason; apply the same fix here.
    substituteInPlace packages/happy-cli/scripts/claude_version_utils.cjs \
      --replace-fail \
        "execSync(bunCheckCommand, { encoding: 'utf8' });" \
        "execSync(bunCheckCommand, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });"

    # findClaudeInPath() treats any `which claude` result without a .js/.cjs/.exe
    # extension as an unspawnable npm shim (a Windows-only artifact) and discards
    # it. On Unix that also matches a normal extension-less native binary -- e.g.
    # the Nix-built claude-code binary -- so a perfectly good PATH match gets
    # thrown away and happy falls through all the way to "Claude Code is not
    # installed". The shim case only exists on win32; treat it as executable
    # everywhere else.
    substituteInPlace packages/happy-cli/scripts/claude_version_utils.cjs \
      --replace-fail \
        "const isExecutable = resolvedPath.endsWith('.js') || resolvedPath.endsWith('.cjs') || resolvedPath.endsWith('.exe');" \
        "const isExecutable = process.platform !== 'win32' || resolvedPath.endsWith('.js') || resolvedPath.endsWith('.cjs') || resolvedPath.endsWith('.exe');"
  '';

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
