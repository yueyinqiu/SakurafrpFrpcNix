import json
from pathlib import Path
import subprocess
import tempfile

CRANE = "@CRANE@"  # noqa: E501

def run(*command) -> bytes:
    return subprocess.run(command, capture_output=True, check=True).stdout

def main():
    repository = "ghcr.io/natfrp/frpc"
    systems = {
        "amd64": "x86_64-linux",
        "arm64": "aarch64-linux",
        "arm": "armv7l-linux",
        "386": "i686-linux",
        "riscv64": "riscv64-linux",
        "loong64": "loongarch64-linux",
    }

    version = run(CRANE, "ls", repository).decode().strip().splitlines()[-1]
    manifests = json.loads(run(CRANE, "manifest", f"{repository}:{version}"))["manifests"]

    result = {}
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tempDirectoryPath:
        tempDirectory = Path(tempDirectoryPath)
        for manifest in manifests:
            platform = manifest["platform"]
            system = systems.get(platform["architecture"])
            if system is None:
                continue
            digest = manifest["digest"]
            rootfs = tempDirectory / "rootfs.tar"
            rootfs.write_bytes(run(CRANE, "export", f"{repository}@{digest}"))
            hash = run(
                "nix", "hash", "file", "--type", "sha256", "--sri", rootfs
            ).decode().strip()
            result[system] = {
                "version": version,
                "manifestDigest": digest,
                "outputHash": hash,
            }

    with open("package/sources.json", "w") as f:
        json.dump(result, f, indent=2)

if __name__ == "__main__":
    main()
