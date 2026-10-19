{
  lib,
  stdenv,
  runCommand,
  crane,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  source = sources.${stdenv.hostPlatform.system};

  rootfs = runCommand "frpc-rootfs-${source.version}.tar" {
    nativeBuildInputs = [ crane ];
    outputHashAlgo = "sha256";
    outputHashMode = "flat";
    outputHash = source.outputHash;
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
  } ''
    crane export "ghcr.io/natfrp/frpc@${source.manifestDigest}" > "$out"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "frpc";
  version = source.version;

  src = rootfs;
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 frpc "$out/bin/frpc"
    runHook postInstall
  '';

  meta = with lib; {
    description = "SakuraFrp frpc client";
    homepage = "https://www.natfrp.com/";
    license = licenses.unfree;
    mainProgram = "frpc";
    platforms = builtins.attrNames sources;
    maintainers = [ ];
  };
})
