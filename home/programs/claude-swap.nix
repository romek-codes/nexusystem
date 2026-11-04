{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication {
  pname = "claude-swap";
  version = "0.25.0b1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "realiti4";
    repo = "claude-swap";
    rev = "9f35426af3846763e79a304dd53d4ce2f40a07a6";
    hash = "sha256-4/dzjvJ7reuYsjA5p091CGHE2qnk7xWOWWkcjv10Ymk=";
  };

  build-system = [ python3Packages.hatchling ];

  nativeBuildInputs = [ python3Packages.pythonRelaxDepsHook ];
  pythonRelaxDeps = [ "textual" ];

  dependencies = with python3Packages; [
    textual
    truststore
  ];

  meta = {
    description = "Multi-account switcher for Claude Code";
    homepage = "https://github.com/realiti4/claude-swap";
    license = lib.licenses.mit;
    mainProgram = "cswap";
  };
}
