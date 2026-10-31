{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex-limits";
  version = "1.3.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@simonesiega/codex-limits/-/codex-limits-${finalAttrs.version}.tgz";
    hash = "sha512-8drzTVLlz1p4aKNbgIio68F6sBnxu0Rnu+So+TBou0/alZsAJ0ogOzg+Hnn6up/YCob5jgTep+JMI4E/+kC9oQ==";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Published tarball ships a prebuilt dist/ with zero runtime deps to vendor.
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/codex-limits
    cp -r package.json dist $out/libexec/codex-limits/

    makeWrapper ${lib.getExe nodejs} $out/bin/codex-limits \
      --add-flags $out/libexec/codex-limits/dist/cli.js

    runHook postInstall
  '';

  meta = {
    description = "Non-interactive usage, reset-time, and reset-credit coupon checker for the OpenAI Codex CLI";
    homepage = "https://github.com/simonesiega/codex-limits";
    license = lib.licenses.mit;
    mainProgram = "codex-limits";
    platforms = lib.platforms.unix;
  };
})
