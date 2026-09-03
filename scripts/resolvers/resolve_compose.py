"""Resolve the four composition conflicts the credential carry presents."""
import re, sys

def hunks(text):
    return list(re.finditer(r"<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n", text, re.S))

def resolve(path):
    s = open(path).read()
    while True:
        ms = hunks(s)
        if not ms: break
        m = ms[0]
        ours, theirs = m.group(1), m.group(2)
        if path.endswith("acp/server.zig"):
            # Keep the composed server shape; add only the broker start.
            merged = "".join(l for l in theirs.splitlines(keepends=True)
                             if "lifecycle_runtime" not in l and "lifecycle_view" not in l)
        elif path.endswith("app/app_entry_runtime.zig"):
            if "startCodexCredentialBroker" in theirs:
                merged = "".join(l for l in theirs.splitlines(keepends=True)
                                 if "startMcpDiscovery" not in l and "rebindAfterInit" not in l)
            else:
                merged = ours + theirs
        elif path.endswith("main.zig"):
            merged = ours + theirs
        elif path.endswith("cli/cli_surface.zig"):
            # Every hunk here is a union; the credential control appends to the
            # composed launch grammar rather than replacing it.
            merged = ours + theirs
        else:
            return False
        s = s[:m.start()] + merged + s[m.end():]
    open(path,'w').write(s)
    return True

if __name__ == "__main__":
    ok = True
    for p in sys.argv[1:]:
        r = resolve(p)
        print(("resolved " if r else "UNRESOLVED ") + p)
        ok = ok and r
    sys.exit(0 if ok else 1)
