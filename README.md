# fxnk

A Workshop for maintaining and installing the `possibilities/fx` fork. It keeps selected Fx features rebuilt on current upstream and publishes them through the fork's Integration branch.

## Consumers

AgentStart is the consumer. It pins the exact approved Integration commit as
`fx_integration_sha` in its own installer and builds `~/.local/bin/fx` from
that source. Fxnk publishes no binaries; the Integration branch is source
publication, and `scripts/install.sh` here builds it for this machine.
