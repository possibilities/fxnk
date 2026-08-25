# Fx Prompt Field Guide

An interactive, critical reading of the 36 rules in Fx's base system prompt.
The source wording is preserved exactly from Integration commit
`309a0e5ae420a625cb4ec6f77250f9f234284edf`; purpose, behavior, risks,
negative examples, criticisms, and improvement ideas are presented as a
separate editorial layer.

## Develop

Requires Node.js `>=22.13.0`.

```bash
npm install
npm run dev
```

## Verify

```bash
npm test
```

The rendered-page test confirms the finished product metadata and key content.
When updating the prompt snapshot, also compare every displayed `text` entry in
`app/page.tsx` with the bullet text in `src/builtins/context.zig` from the exact
Fx revision being documented.

## Build the wiki artifact

```bash
npm run build
npm run wiki:bundle
agentwiki publish ./wiki-dist --name fx-prompt-field-guide \
  --kind bundle --title "Fx Prompt Field Guide" \
  --tag fx,prompt,system-prompt,guide --json
```

`wiki:bundle` turns the Vinext worker output into a self-contained static
bundle with relative asset paths, suitable for the wiki's immutable artifact
server. `dist/` and `wiki-dist/` are generated and ignored.
