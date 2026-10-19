{
  lib,
  stdenv,
  dockerTools,
  jq,
}:

let
  version = "0.51.0-sakura-15";

  # OCI multi-arch index digest (ghcr.io/natfrp/frpc:<version>).
  # To update: fetch a token with
  #   curl -s "https://ghcr.io/token?scope=repository:natfrp/frpc:pull"
  # then read the Docker-Content-Digest of
  #   curl -sIL -H "Authorization: Bearer <token>" \
  #     -H "Accept: application/vnd.oci.image.index.v1+json" \
  #     https://ghcr.io/v2/natfrp/frpc/manifests/<version>
  indexDigest = "sha256:24e29ca1f751dea995ffc86999ec0ee005d3db60d35bc6c1810aa13ec5bd3113";

  # hostPlatform.system -> { goArch, outputHash }
  # outputHash is the hash of the per-arch docker-archive. After updating the
  # image, clear the value to "" and read the `got: sha256-…` from the build error.
  archs = {
    x86_64-linux = {
      goArch = "amd64";
      hash = "sha256-4zFxeyaonKXeVM/Gv8jrLQNTsWj8fNIZRu8S9xon6to=";
    };
    aarch64-linux = {
      goArch = "arm64";
      hash = "sha256-bv4QItuFKUXRQE5f8U1bNhZIff7LmWYG3cllolyfUCE=";
    };
    armv7l-linux = {
      goArch = "arm";
      hash = "sha256-KCxBuh+gsa3LNxPMr1Jb3C27R9Jk/EdLzgvSdi1j5Us=";
    };
    i686-linux = {
      goArch = "386";
      hash = "sha256-IiLZAY0XXugjyTa1D/60eELRQSXSt0sugt02YNp5ebE=";
    };
    riscv64-linux = {
      goArch = "riscv64";
      hash = "sha256-0/lRztx9VunF4po8YJokUYV0RlY99t8p0j3LshQa1DU=";
    };
    loongarch64-linux = {
      goArch = "loong64";
      hash = "sha256-19keQGbv0XKhyrfFb7n9zi2FFUI8qdjYgm0N0RM29OA=";
    };
  };

  image = dockerTools.pullImage {
    imageName = "ghcr.io/natfrp/frpc";
    imageDigest = indexDigest;
    finalImageName = "natfrp-frpc";
    finalImageTag = version;
    os = "linux";
    arch = archs.${stdenv.hostPlatform.system}.goArch;
    outputHash = archs.${stdenv.hostPlatform.system}.hash;
    outputHashAlgo = "sha256";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "frpc";
  inherit version;

  # pullImage produces a docker-archive .tar, unpacked automatically by unpackPhase.
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

  meta = with lib; {
    description = "SakuraFrp frpc client (proprietary fork of fatedier/frp)";
    homepage = "https://www.natfrp.com/";
    license = licenses.unfree;
    # No redistribution is granted by upstream, so the output must not be pushed to
    # a public binary cache.
    unfreeRedistributable = true;
    mainProgram = "frpc";
    platforms = builtins.attrNames archs;
    maintainers = [ ];
  };
})
