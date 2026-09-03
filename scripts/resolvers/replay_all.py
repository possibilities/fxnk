import subprocess, sys, os
W="/Volumes/Scratch/fx-credential-authority-20260903/replay"
R="/private/tmp/claude-502/-Users-arthack--herdr-worktrees-fmx-worktree-lucky-stone-2334/d634db91-12a2-403e-86d8-79073e3c585d/scratchpad/resolve_auth.py"
def git(*a, check=True, cwd=W):
    cmd=["git","-c","rerere.enabled=false","-c","user.name=Mike Bannister","-c","user.email=notimpossiblemike@gmail.com"]+list(a)
    r=subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    if check and r.returncode!=0:
        print("GIT FAIL:", " ".join(a)); print(r.stdout[-2000:]); print(r.stderr[-1000:]); sys.exit(1)
    return r
def try_resolve(cwd=W):
    u=git("diff","--name-only","--diff-filter=U",cwd=cwd).stdout.split()
    if not u: return True
    L="/private/tmp/claude-502/-Users-arthack--herdr-worktrees-fmx-worktree-lucky-stone-2334/d634db91-12a2-403e-86d8-79073e3c585d/scratchpad/resolve_libfx.py"
    auth=[f for f in u if f.endswith("core/auth/auth_runtime.zig") or f.endswith("app/app_auth_runtime.zig")]
    libfx=[f for f in u if f.endswith("napi_core_main.zig") or f.endswith("wasm_core_main.zig")
           or f.endswith("sdk/NAPI.md") or f.endswith("sdk/browser.js") or f.endswith("sdk/node.js")]
    if set(auth)|set(libfx) != set(u): return False
    for script, files in ((R, auth), (L, libfx)):
        if not files: continue
        r=subprocess.run([sys.executable,script]+files,capture_output=True,text=True,cwd=cwd)
        print("   ", r.stdout.strip())
        if r.returncode!=0: return False
    fmt=subprocess.run(["zig","fmt","--check","src/","build.zig"],capture_output=True,text=True,cwd=cwd)
    if fmt.returncode!=0:
        print("   FMT FAIL:", fmt.stderr[-500:]); return False
    git("add","-A",cwd=cwd); return True
def merge(branch, into_label, cwd=W):
    r=git("merge","--no-ff","-m",f"Merge {branch} into {into_label}",branch,check=False,cwd=cwd)
    if r.returncode!=0:
        if not try_resolve(cwd):
            print(f"STOP unresolved merging {branch} into {into_label}:",
                  git("diff","--name-only","--diff-filter=U",cwd=cwd).stdout.split())
            print(r.stdout[-1500:]); sys.exit(2)
        git("commit","-q","--no-edit",cwd=cwd)

LEAVES=["acp-capability-gates","acp-permission-policy","acp-project-instructions","acp-state-isolation",
        "ade-event-feed","effort","effort-catalog","exclusive-skill-roots","external-editor",
        "fmx-work-control","fxnk-version","invocation-skill-roots","libfx-provider-authorization",
        "notification-sound-single-flight","resume-bounds","structured-inference","system-prompt-files",
        "terminal-probe-determinism"]
for n in LEAVES:
    git("checkout","-q","carry/"+n); merge("carry/hosted-full-ci","carry/"+n)
    print(f"  {n}: {git('rev-parse','--short','HEAD').stdout.strip()}")
for n,dep in [("acp-tool-selection","acp-capability-gates"),("edited-git-roots","ade-event-feed"),
              ("session-naming","ade-event-feed"),("state-auth-borrowing","acp-state-isolation")]:
    git("checkout","-q","carry/"+n); merge("carry/"+dep,"carry/"+n)
    print(f"  {n}: {git('rev-parse','--short','HEAD').stdout.strip()}")
git("checkout","-q","carry/launch-control-continuity")
for dep in LEAVES+["acp-tool-selection","edited-git-roots","session-naming","state-auth-borrowing",
                   "fmx-distribution","hosted-full-ci"]:
    merge("carry/"+dep,"carry/launch-control-continuity")
print("  launch-control-continuity:", git("rev-parse","--short","HEAD").stdout.strip())
for n,dep in [("local-gate-support","launch-control-continuity"),("state-system-prompts","local-gate-support")]:
    git("checkout","-q","carry/"+n); merge("carry/"+dep,"carry/"+n)
    print(f"  {n}: {git('rev-parse','--short','HEAD').stdout.strip()}")
git("checkout","-q","carry/acp-voice-control")
for dep in ["fmx-work-control","ade-event-feed"]:
    merge("carry/"+dep,"carry/acp-voice-control")
print("  acp-voice-control:", git("rev-parse","--short","HEAD").stdout.strip())
C="/Volumes/Scratch/fx-credential-authority-20260903/carry"
git("checkout","-q","carry/codex-credential-authority",cwd=C)
merge("carry/libfx-provider-authorization","carry/codex-credential-authority",cwd=C)
print("  codex-credential-authority:", git("rev-parse","--short","HEAD",cwd=C).stdout.strip())
print("REPLAY DONE")
