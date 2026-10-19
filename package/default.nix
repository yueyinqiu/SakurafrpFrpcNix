{
  lib,
  stdenv,
  dockerTools,
  jq,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  source = sources.architectures.${stdenv.hostPlatform.system};

  image = dockerTools.pullImage {
    imageName = "ghcr.io/natfrp/frpc";
    imageDigest = source.manifestDigest;
    finalImageName = "natfrp-frpc";
    finalImageTag = source.version;
    os = "linux";
    outputHash = source.outputHash;
    outputHashAlgo = "sha256";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "frpc";
  version = source.version;

  src = image;
  sourceRoot = ".";

  nativeBuildInputs = [ jq ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    # manifest.json's Layers field lists each layer tar in order; find the one with frpc
    jq -r '.[0].Layers[]' manifest.json | while IFS= read -r layer; do
      if tar -tf "$layer" 2>/dev/null | grep -qx 'frpc'; then
        tar -xf "$layer" -C "$out/bin" frpc && break
      fi
    done
    chmod +x "$out/bin/frpc"
    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "SakuraFrp frpc client (proprietary fork of fatedier/frp)";
    homepage = "https://www.natfrp.com/";
    license = licenses.unfree;
    # No redistribution is granted by upstream, so the output must not be pushed to
    # a public binary cache.
    unfreeRedistributable = true;
    mainProgram = "frpc";
    platforms = builtins.attrNames sources.architectures;
    maintainers = [ ];
  };
})
