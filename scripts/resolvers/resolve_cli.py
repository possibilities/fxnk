"""Union the credential control into the composed launch grammar."""
import sys
M = "carry/codex-credential-authority"
def sub(s, a, b):
    if a not in s:
        print("MISS:", a.splitlines()[0][:64]); return s, False
    return s.replace(a, b, 1), True
def resolve(path):
    s = open(path).read(); ok = True
    pairs = [
      ("<<<<<<< HEAD\n    allow_native_tools: bool = true,", "    allow_native_tools: bool = true,"),
      ("""    effective_system_prompt: ?[]u8 = null,\n=======\n    /// The inherited Codex credential channel. The descriptor number is the\n    /// only capability this control carries: nothing about the channel appears\n    /// in the environment, logs, telemetry, or crash output.\n    codex_credential_fd: ?u8 = null,\n>>>>>>> """+M+"\n",
       """    effective_system_prompt: ?[]u8 = null,\n    /// The inherited Codex credential channel. The descriptor number is the\n    /// only capability this control carries: nothing about the channel appears\n    /// in the environment, logs, telemetry, or crash output.\n    codex_credential_fd: ?u8 = null,\n"""),
      ("<<<<<<< HEAD\n    pub fn hasNativeToolSelection", "    pub fn hasNativeToolSelection"),
      ("""        return prompt;\n=======\n    pub fn hasCodexCredentialBrokerActivation(self: LaunchModifiers) bool {\n        return self.codex_credential_fd != null;\n>>>>>>> """+M+"\n    }\n};",
       """        return prompt;\n    }\n\n    pub fn hasCodexCredentialBrokerActivation(self: LaunchModifiers) bool {\n        return self.codex_credential_fd != null;\n    }\n};"""),
      ("<<<<<<< HEAD\n    var allow_native_tools = true;", "    var codex_credential_fd: ?u8 = null;\n    var allow_native_tools = true;"),
      ("""        append_paths.deinit(alloc);\n    }\n=======\n    var codex_credential_fd: ?u8 = null;\n>>>>>>> """+M+"\n",
       """        append_paths.deinit(alloc);\n    }\n"""),
      ("""<<<<<<< HEAD\n        } else if (std.mem.eql(u8, arg, "--no-native-tools")) {""",
       """        } else if (std.mem.eql(u8, arg, "--no-native-tools")) {"""),
      ("""            try dupeAndAppendPath(alloc, &append_paths, value);\n=======\n        } else if (std.mem.eql(u8, arg, "--codex-credential-fd")) {""",
       """            try dupeAndAppendPath(alloc, &append_paths, value);\n        } else if (std.mem.eql(u8, arg, "--codex-credential-fd")) {"""),
      ("""                return error.InvalidCodexCredentialFd;\n>>>>>>> """+M+"\n        } else {",
       """                return error.InvalidCodexCredentialFd;\n        } else {"""),
      ("<<<<<<< HEAD\n            .allow_native_tools = allow_native_tools,", "            .allow_native_tools = allow_native_tools,"),
      ("""            },\n=======\n            .codex_credential_fd = codex_credential_fd,\n>>>>>>> """+M+"\n",
       """            },\n            .codex_credential_fd = codex_credential_fd,\n"""),
      ("<<<<<<< HEAD\nfn canonicalizeStateHome", "fn canonicalizeStateHome"),
      ("""    return canonical;\n=======\n/// Standard input, output, and error are never a credential channel, and the\n/// number must stay inside the range the launch modifier can carry.\nfn parseCodexCredentialFd(value: []const u8) !u8 {\n    const parsed = try std.fmt.parseUnsigned(u8, value, 10);\n    if (parsed < 3) return error.InvalidCodexCredentialFd;\n    return parsed;\n>>>>>>> """+M+"\n}",
       """    return canonical;\n}\n\n/// Standard input, output, and error are never a credential channel, and the\n/// number must stay inside the range the launch modifier can carry.\nfn parseCodexCredentialFd(value: []const u8) !u8 {\n    const parsed = try std.fmt.parseUnsigned(u8, value, 10);\n    if (parsed < 3) return error.InvalidCodexCredentialFd;\n    return parsed;\n}"""),
      ("""<<<<<<< HEAD\n        if (std.mem.eql(u8, arg, "--context-limit") or""",
       """        if (std.mem.eql(u8, arg, "--context-limit") or"""),
      ("""            std.mem.eql(u8, arg, "--state-dir"))\n=======\n        if (std.mem.eql(u8, arg, "--context-limit") or std.mem.eql(u8, arg, "--add-dir") or\n            std.mem.eql(u8, arg, "--codex-credential-fd"))\n>>>>>>> """+M+"\n",
       """            std.mem.eql(u8, arg, "--codex-credential-fd") or\n            std.mem.eql(u8, arg, "--state-dir"))\n"""),
      ("""<<<<<<< HEAD\n            !std.mem.startsWith(u8, arg, "--system-prompt-file=") and""",
       """            !std.mem.startsWith(u8, arg, "--codex-credential-fd=") and\n            !std.mem.startsWith(u8, arg, "--system-prompt-file=") and"""),
      ("""            !std.mem.startsWith(u8, arg, "--state-dir="))\n=======\n            !std.mem.startsWith(u8, arg, "--codex-credential-fd=") and\n            !std.mem.eql(u8, arg, "--no-additional-dirs"))\n>>>>>>> """+M+"\n",
       """            !std.mem.startsWith(u8, arg, "--state-dir="))\n"""),
      ("<<<<<<< HEAD\n                .allow_acp_mcp = acp_opts.allow_acp_mcp,", "                .allow_acp_mcp = acp_opts.allow_acp_mcp,"),
      ("""                .home_override = global_args.modifiers.state_home,\n=======\n                .codex_credential_fd = global_args.modifiers.codex_credential_fd,\n>>>>>>> """+M+"\n",
       """                .home_override = global_args.modifiers.state_home,\n                .codex_credential_fd = global_args.modifiers.codex_credential_fd,\n"""),
      ("<<<<<<< HEAD\n        error.DuplicateNativeToolSuppression", "        error.DuplicateNativeToolSuppression"),
      ("""        error.MissingAppendSystemPromptFileValue => "--append-system-prompt-file requires a file path",\n=======\n        error.MissingCodexCredentialFd""",
       """        error.MissingAppendSystemPromptFileValue => "--append-system-prompt-file requires a file path",\n        error.MissingCodexCredentialFd"""),
      ("""only on interactive, resume, and acp launches",\n>>>>>>> """+M+"\n",
       """only on interactive, resume, and acp launches",\n"""),
    ]
    for a, b in pairs:
        s, hit = sub(s, a, b); ok = ok and hit
    open(path, 'w').write(s)
    left = s.count("<<<<<<<")
    print(f"{path}: {left} conflicts left")
    return left == 0
if __name__ == "__main__":
    sys.exit(0 if all(resolve(p) for p in sys.argv[1:]) else 1)
