# fxnk

A Workshop for maintaining and installing the `possibilities/fx` fork. It keeps selected Fx features rebuilt on current upstream and publishes them through the fork's Integration branch.

## Install for fmx

```sh
curl -fsSL https://c1g42cnmuvvspilo.public.blob.vercel-storage.com/fx/setup.sh | bash
```

This installs the latest approved Integration build as `~/.local/bin/fmx-fx`.
Set `FMX_FX_VERSION` to an exact full Integration commit to reproduce a pinned
installation. AgentStart intentionally uses the Workshop Installer instead and
keeps its independently managed copy at `~/.local/bin/fx`.
