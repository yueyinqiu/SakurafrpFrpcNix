#!/usr/bin/env bash
set -euo pipefail

# Update package/sources.json with the latest (or a given) frpc version: per-arch
# manifest digests and output hashes.
#
# Dependencies: curl, jq, crane, nix
# Usage: ./update.sh [version]

cd "$(dirname "$0")"

json=sources.json

token=$(curl -fsSL "https://ghcr.io/token?scope=repository:natfrp/frpc:pull" | jq -r .token)
auth=(-H "Authorization: Bearer $token")

# 1. Resolve the version (defaults to the highest version tag).
if (($# >= 1)); then
  version=$1
else
  version=$(
    curl -fsSL "${auth[@]}" "https://ghcr.io/v2/natfrp/frpc/tags/list" \
      | jq -r '.tags[]' \
      | grep -E '^[0-9]+\.[0-9]+\.[0-9]+-sakura-[0-9.]+$' \
      | sort -V \
      | tail -1
  )
fi

# 2. Fetch the multi-arch index and map OCI arch -> manifest digest.
declare -A manifest_of=()
while read -r oci digest; do
  manifest_of[$oci]=$digest
done < <(
  curl -fsSL "${auth[@]}" \
    -H "Accept: application/vnd.oci.image.index.v1+json" \
    "https://ghcr.io/v2/natfrp/frpc/manifests/$version" \
    | jq -r '.manifests[] | select(.platform.os == "linux") | "\(.platform.architecture) \(.digest)"'
)

# OCI arch -> Nix system. Keep in sync with the architectures in sources.json.
declare -A system_of=(
  [amd64]=x86_64-linux
  [arm64]=aarch64-linux
  [arm]=armv7l-linux
  [386]=i686-linux
  [riscv64]=riscv64-linux
  [loong64]=loongarch64-linux
)

# 3. Compute the per-arch output hash of the flattened rootfs (crane export).
#    Deterministic order for a stable diff.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

architectures="{}"
for oci in amd64 arm64 arm 386 riscv64 loong64; do
  system=${system_of[$oci]:-}
  digest=${manifest_of[$oci]:-}
  [[ -n $system && -n $digest ]] || continue

  crane export "ghcr.io/natfrp/frpc@$digest" > "$tmp/out.tar"
  hash=$(nix hash file --type sha256 --sri "$tmp/out.tar")
  architectures=$(
    jq --arg s "$system" --arg d "$digest" --arg h "$hash" --arg v "$version" \
      '. + {($s): { version: $v, manifestDigest: $d, outputHash: $h }}' <<<"$architectures"
  )
  rm -f "$tmp/out.tar"
done

jq -n --argjson a "$architectures" '{ architectures: $a }' >"$json"

echo "wrote $json: version=$version"
