# fxnk

A Workshop for maintaining and installing the `possibilities/fx` fork. It keeps selected Fx features rebuilt on current upstream and publishes them through the fork's Integration branch.

## Use from fmx

```sh
git clone https://github.com/possibilities/fmx.git
cd fmx
scripts/install.sh --install
```

Fmx pins an exact approved Integration commit and builds it from source as
`~/.local/bin/fmx-fx`. Fxnk publishes no private fmx binaries. AgentStart uses
the same Fmx installer with the exact source build already proved by this
Workshop, while retaining its independently managed `~/.local/bin/fx`.
