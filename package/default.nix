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
    finalImageTag = source.version;
    outputHashAlgo = "sha256";
    outputHash = source.outputHash;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "frpc";
  version = source.version;

  src = image;
  sourceRoot = ".";
  
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ jq ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    layer1=$(jq -r '.[0].Layers[1]' manifest.json)
    tar -xf "$layer1" -C "$out/bin" frpc

    chmod +x "$out/bin/frpc"

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "SakuraFrp frpc client (proprietary fork of fatedier/frp)";
    homepage = "https://www.natfrp.com/";
    license = licenses.unfree;
    mainProgram = "frpc";
    platforms = builtins.attrNames sources.architectures;
    maintainers = [ ];
  };
})
