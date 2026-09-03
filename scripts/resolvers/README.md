# Replay resolvers (2026-09-03 cycle)

Cycle helpers written while replaying all carries onto upstream four times in
one pass. They are not gate scripts and nothing in the gate contract reads
them; they exist so the next upstream replay starts from recorded resolutions
instead of rediscovering them.

- `replay_all.py` drives a whole replay of the declared carries in dependency
  order with real merges and content verification.
- `resolve_auth.py` resolves the auth-runtime field rename and the home-aware
  team selection between upstream and `carry/acp-state-isolation` /
  `carry/state-auth-borrowing`.
- `resolve_libfx.py` resolves the four SDK and NAPI adjacencies between
  upstream's libfx kernel and `carry/libfx-provider-authorization`.
- `resolve_compose.py` and `resolve_cli.py` resolve the credential-authority
  carry's composition and CLI-surface hunks.

Read each script before trusting it against a new upstream: they encode the
resolutions that were correct on 2026-09-03, not a general rule. Rerere holds
a corrupt resolution for `src/core/agent/worker_runtime.zig` (two stacked
return types); clear it from `.git/rr-cache` before the next replay.
