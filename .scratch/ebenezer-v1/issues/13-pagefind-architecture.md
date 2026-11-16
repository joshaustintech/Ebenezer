# Pagefind architecture

Type: research
Status: open
Blocked by:

## Question

How is Pagefind built, and which parts could be ported to Spinel Ruby?
- How the indexer works and how it is split into crates.
- Its on-disk index format (fragments, chunked index, filters, metadata), and whether it is versioned or documented.
- What runs in the browser (the WASM search core, JS API, default UI), and whether the browser side could be reused unchanged against an index produced by a Ruby indexer.
- Which Rust dependencies do the heavy lifting (HTML parsing, stemming, compression).
- Its licence.
- How big the indexer is in lines of code.
- Whether Spinel's wasm32-wasi target could plausibly stand in for the WASM search core.
