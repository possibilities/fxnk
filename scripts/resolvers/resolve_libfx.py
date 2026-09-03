"""Union the four libfx adjacency conflicts this cycle keeps re-presenting."""
import re, sys

def _hunk(text):
    return re.search(r"<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n", text, re.S)

def resolve(path):
    s = open(path).read()
    m = _hunk(s)
    if not m: return False
    ours, theirs = m.group(1), m.group(2)
    if path.endswith("napi_core_main.zig") or path.endswith("wasm_core_main.zig"):
        merged = theirs + ours                      # both import sets
    elif path.endswith("NAPI.md"):
        merged = ours + "\n" + theirs               # both prose paragraphs
    elif path.endswith("browser.js") or path.endswith("node.js"):
        merged = ("export { encodeXtermKeyEvent, fxSdkApiVersion, listModels, "
                  "supportsJspi, xtermAdapter };\nexport const libfxApiVersion = 3;\n")
    else:
        return False
    s = s[:m.start()] + merged + s[m.end():]
    open(path,'w').write(s)
    return "<<<<<<<" not in s

if __name__ == "__main__":
    ok = True
    for p in sys.argv[1:]:
        r = resolve(p)
        print(("resolved " if r else "UNRESOLVED ") + p)
        ok = ok and r
    sys.exit(0 if ok else 1)
