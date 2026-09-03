"""Resolve the two known auth-path adjacency conflicts of this cycle."""
import re, sys

FIELD_CONFLICT = (
    "    try std.testing.expect(runtime.credential_refresh_failure_source == null);\n"
    "    try std.testing.expect(runtime.profile_home == null);\n"
    "=======\n"
    "    try std.testing.expect(runtime.credential_failure == null);\n"
)

def resolve_auth_runtime(path):
    text = open(path).read()
    if "<<<<<<<" not in text: return False
    # The runtime's failure field was renamed upstream; the twin keeps its own
    # profile_home assertion beside the new name.
    m = re.search(r"<<<<<<< [^\n]*\n" + re.escape(FIELD_CONFLICT) + r">>>>>>> [^\n]*\n", text)
    if m:
        text = (text[:m.start()]
                + "    try std.testing.expect(runtime.credential_failure == null);\n"
                + "    try std.testing.expect(runtime.profile_home == null);\n"
                + text[m.end():])
        open(path,'w').write(text)
        if "<<<<<<<" not in text: return True
    lines = text.split('\n')
    start = sep = end = None
    for i, ln in enumerate(lines):
        if ln.startswith("<<<<<<<") and start is None: start = i
        elif ln == "=======" and start is not None and sep is None: sep = i
        elif ln.startswith(">>>>>>>") and sep is not None: end = i; break
    ours = lines[start+1:sep]
    theirs = lines[sep+1:end]
    if not (ours and ours[0].startswith('test "pinned ChatGPT account')): return False
    if not any("CredentialFailureReason" in t for t in theirs): return False
    ours = ours + ["}"]
    out = lines[:start] + theirs + lines[end+1:]
    merged = '\n'.join(out)
    anchor = "\npub const FailureReason = enum {"
    assert anchor in merged
    merged = merged.replace(anchor, "\n" + '\n'.join(ours) + "\n" + anchor, 1)
    open(path,'w').write(merged)
    return True

def resolve_app_auth_runtime(path):
    text = open(path).read()
    m = re.search(
        r"<<<<<<< [^\n]*\n(            var selected_team = \(if \(app_profile_runtime\.explicitHome\(app\)\) \|profile_home\|\n"
        r"                selection\.selectFromHome\(app\.alloc, index, profile_home\)\n"
        r"            else\n"
        r"                selection\.select\(app\.alloc, index\)\) catch \|err\| \{\n)"
        r"=======\n"
        r"            var selected_team = selection\.select\(app\.alloc, index\) catch \|err\| \{\n"
        r"(                cancelPromptRetryAfterAuth\(app\);\n)"
        r">>>>>>> [^\n]*\n", text)
    if not m: return False
    open(path,'w').write(text[:m.start()] + m.group(1) + m.group(2) + text[m.end():])
    return True

if __name__ == "__main__":
    ok = True
    for p in sys.argv[1:]:
        if p.endswith("core/auth/auth_runtime.zig"): r = resolve_auth_runtime(p)
        elif p.endswith("app/app_auth_runtime.zig"): r = resolve_app_auth_runtime(p)
        else: r = False
        print(("resolved " if r else "UNRESOLVED ") + p)
        ok = ok and r
    sys.exit(0 if ok else 1)
