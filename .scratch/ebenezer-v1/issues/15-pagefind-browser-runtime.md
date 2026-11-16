# Pagefind browser runtime

Type: grilling
Status: resolved
Blocked by:

## Question

Pagefind's browser side (WASM search core, JS API, default UI) can't be Ruby. What runs in the visitor's browser?

## Answer

Decided by the user: **fork Pagefind's browser side into Elm.** See [ADR 0005](../../../docs/adr/0005-pagefind-browser-runtime-in-elm.md). The Elm port reimplements what the WASM core does, not just the UI. The compiled JavaScript is embedded in the Ebenezer binary as part of the search built-in. What the port covers belongs to [Pagefind port scope](14-pagefind-port-scope.md).
