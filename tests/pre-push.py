#!/usr/bin/env python3
"""Small local Git fixtures only; no dependencies, builds, servers, or network."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("static_hook", str(ROOT / ".githooks/pre-push"))
spec = importlib.util.spec_from_loader(loader.name, loader)
hook = importlib.util.module_from_spec(spec)
loader.exec_module(hook)


class PushChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="pre-push-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.git("init", "-q")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "test")
        (self.repo / ".githooks").mkdir()
        (self.repo / "scripts").mkdir()
        (self.repo / ".githooks/checks.json").write_text(json.dumps({
            "inputs": ["scripts", "contract.txt"],
            "command": ["bash", "scripts/check.sh"],
        }))
        (self.repo / "scripts/check.sh").write_text("#!/bin/bash\nset -eu\ngrep -Fx good contract.txt\n")
        (self.repo / "contract.txt").write_text("good\n")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args], stderr=subprocess.PIPE).decode().strip()

    def commit(self):
        self.git("add", ".")
        self.git("commit", "-qm", "fixture")
        return self.git("rev-parse", "HEAD")

    def check(self, sha):
        return subprocess.run(["python3", str(ROOT / ".githooks/pre-push"), "--revision", sha],
                              cwd=self.repo, capture_output=True, text=True)

    def test_committed_failure_cannot_be_hidden_by_working_fix(self):
        (self.repo / "contract.txt").write_text("bad\n")
        sha = self.commit()
        (self.repo / "contract.txt").write_text("good\n")
        before = self.git("status", "--porcelain")
        self.assertNotEqual(self.check(sha).returncode, 0)
        self.assertEqual(self.git("status", "--porcelain"), before)

    def test_good_commit_ignores_dirty_tree_and_cleans_snapshot(self):
        sha = self.commit()
        (self.repo / "contract.txt").write_text("bad\n")
        result = self.check(sha)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.repo / "contract.txt").read_text(), "bad\n")

    def test_deletions_and_duplicate_tips(self):
        sha = "a" * 40
        self.assertEqual(hook.revisions([
            f"refs/heads/a {sha} refs/heads/a {'b' * 40}",
            f"refs/heads/b {sha} refs/heads/b {'b' * 40}",
            f"(delete) {'0' * 40} refs/heads/c {'c' * 40}",
        ]), [sha])

    def test_busy_lock_fails_and_kernel_releases_it(self):
        with (self.root / "lock").open("a") as first, (self.root / "lock").open("a") as second:
            hook.acquire(first, seconds=0)
            with self.assertRaisesRegex(RuntimeError, "busy"):
                hook.acquire(second, seconds=0.01)
            first.close()
            hook.acquire(second, seconds=0)

    def test_deadline_stops_child(self):
        with self.assertRaises(subprocess.TimeoutExpired):
            hook.run(["bash", "-c", "sleep 5"], deadline=time.monotonic() + 0.03)

    def test_oversize_snapshot_is_refused_before_checker(self):
        (self.repo / "contract.txt").write_bytes(b"x" * (hook.MAX_BYTES + 1))
        result = self.check(self.commit())
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exceeds 8 MiB", result.stderr)

    def test_snapshot_rejects_escaping_symlink(self):
        (self.repo / "scripts/escape").symlink_to("../../outside")
        result = self.check(self.commit())
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink escapes", result.stderr)

    def test_installer_preserves_existing_hook(self):
        install = ROOT / "scripts/install-hooks.sh"
        (self.repo / "scripts/install-hooks.sh").write_bytes(install.read_bytes())
        existing = self.repo / ".git/hooks/pre-push"
        existing.write_text("keep me\n")
        result = subprocess.run(["bash", "scripts/install-hooks.sh"], cwd=self.repo, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(existing.read_text(), "keep me\n")

    def test_installer_covers_linked_worktree_and_real_push(self):
        (self.repo / "scripts/install-hooks.sh").write_bytes((ROOT / "scripts/install-hooks.sh").read_bytes())
        installed = self.repo / ".githooks/pre-push"
        installed.write_bytes((ROOT / ".githooks/pre-push").read_bytes())
        installed.chmod(0o755)
        self.commit()
        subprocess.run(["bash", "scripts/install-hooks.sh"], cwd=self.repo, check=True, capture_output=True)
        worktree = self.root / "linked"
        self.git("worktree", "add", "-qb", "linked", str(worktree))
        remote = self.root / "remote.git"
        subprocess.run(["git", "init", "--bare", "-q", str(remote)], check=True)
        self.git("remote", "add", "fixture", str(remote))
        result = subprocess.run(["git", "push", "fixture", "HEAD"], cwd=worktree, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        (worktree / "contract.txt").write_text("bad\n")
        subprocess.run(["git", "commit", "-qam", "bad"], cwd=worktree, check=True)
        result = subprocess.run(["git", "push", "fixture", "HEAD"], cwd=worktree, capture_output=True)
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
