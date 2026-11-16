# Fork Pagefind's browser runtime into Elm

Pagefind's browser side, meaning its WASM search core, `pagefind.js` API and default UI, can't be Ruby, so we fork it into Elm instead of shipping upstream's JavaScript and WASM unchanged. Ebenezer then owns its entire search stack: a Spinel Ruby indexer plus an Elm search runtime, both built-ins.

## Considered Options

- **Bundle Pagefind's browser assets unchanged.** Least work, but it ties Ebenezer to upstream's index format and Rust build.
- **Compile the search core with Spinel's wasm32-wasi target.** Keeps it in Ruby, but needs a WASI shim in the browser and is unproven.

## Consequences

- The Elm port has to reimplement what the WASM core does, not just the UI: decoding the index, stemming, scoring and excerpts.
- The Elm compiler is needed to build Ebenezer. Site authors don't need it, because the compiled JavaScript is embedded in the binary.
