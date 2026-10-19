# SakurafrpFrpcNix

Nix packaging for [SakuraFrp](https://www.natfrp.com/) frpc — the proprietary fork of [fatedier/frp](https://github.com/fatedier/frp).

The binary is not fetched from the official download page (which requires a login and prunes old versions), but extracted from the official Docker image [`ghcr.io/natfrp/frpc`](https://github.com/orgs/natfrp/packages/container/package/frpc). Image tags are kept long-term and provide `latest`, making them more stable than the download page URLs.

## Adding as a flake input

```nix
{
  inputs = {
    sakurafrp-frpc.url = "github:yueyinqiu/SakurafrpFrpcNix";
  };
}
```

## Package

The binary is exposed as `frpc`:

```nix
sakurafrp-frpc.packages.${system}.frpc
```

Or try it directly from the CLI:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:yueyinqiu/SakurafrpFrpcNix -- -V
```

---

All documentation and `description` fields in this repository are AI-generated.
