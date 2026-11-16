# Pagefind architecture

Type: research
Status: resolved
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

## Answer

Findings: branch `research/pagefind-architecture`, file `.scratch/ebenezer-v1/research/pagefind-architecture.md`. Pinned to Pagefind v1.6.0 (860a4ea) and matz/spinel afe2a92.

- **Licence:** MIT. The stemmer carries Snowball code under BSD-3-Clause, so keep both notices.
- **Indexer:** about 6,400 lines of Rust. It parses HTML with `lol_html` and handles `data-pagefind-*` attributes, then builds a chunked inverted index. Output files are gzip-wrapped CBOR, plus gzip-wrapped JSON fragments.
- **Index format:** undocumented and versioned only by a string. It changed in both 1.5 and 1.6, so it isn't a stable contract.
- **Browser side:** the WASM core (about 2,500 lines) does CBOR decoding, stemming, BM25 scoring, phrases, filters and sorts. The JS (about 2,000 lines) does fetching, gunzip, segmentation, excerpts and the worker. The UIs are a further 1,100 to 7,500 lines. The Elm port reimplements roughly 4,500 lines plus whatever UI we keep.
- **Spinel's WASM target can't replace the core.** It builds standalone programs, not libraries that JavaScript can call, and uses 32-bit integers.
- **Ruby indexer pieces:**
  - Spinel already ships inflate and a weak deflate, SHA-1, JSON and unicode_normalize.
  - Missing: CBOR, an HTML tokenizer, Snowball, and Unicode word segmentation.
- **Elm packages:**
  - gzip: elm-flate and elm-tiny-inflate.
  - CBOR: elm-toulouse/cbor.
  - Stemming: no Snowball implementation exists. The Porter stemmers available would not match the index.
- **The stemmer is the real contract between indexer and client.** Both sides must stem identically.
- **Can wait:** CJK and Thai segmentation, multisite merge, and the legacy UIs. The 397 upstream integration tests could serve as a conformance suite.
