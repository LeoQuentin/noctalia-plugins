# noctalia-plugins (personal fork)

Fork of [noctalia-dev/noctalia-plugins](https://github.com/noctalia-dev/noctalia-plugins) with patches for my hardware.

Right now this only has `noctalia-supergfxctl`, but I'll add more plugins here as I tweak them.

## noctalia-supergfxctl

On some ASUS laptops (mine is a ProArt P16 H7606, RTX 5060 / Ryzen AI 9 HX 370), `supergfxctl --mode` just doesn't work. It either fails silently or throws errors. Editing `/etc/supergfxd.conf` and restarting the daemon works fine though, so that's what this fork does instead.

Changes:
- GPU switching goes through `pkexec /usr/local/bin/gpu-switch-daemon` instead of `supergfxctl --mode`. The helper script edits the config and restarts the daemon. A polkit policy handles auth.
- Integrated/Hybrid transitions require a reboot instead of a logout (matches what actually happens on this hardware).

Reading GPU state still uses `supergfxctl` as normal since that part works fine.

## Setup

### System files (one-time)

```bash
sudo ./system/install.sh
```

Installs the helper script to `/usr/local/bin/` and the polkit policy to `/usr/share/polkit-1/actions/`.

### Plugin

Symlink into your Noctalia plugins directory:

```bash
ln -sf "$(pwd)/noctalia-supergfxctl" ~/.config/noctalia/plugins/supergfxctl
```

## License

MIT. Original plugin by [cod3ddot](mailto:cod3ddot@proton.me). See [noctalia-supergfxctl/COPYING](noctalia-supergfxctl/COPYING).
