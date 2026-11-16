# Pagefind architecture: what it's made of, and what Ebenezer can port

Research for ticket `13-pagefind-architecture`. It covers what a Spinel Ruby indexer port involves and, because the scope grew, what an Elm port of the browser side involves.

**Pinned to:** Pagefind **v1.6.0**, commit [`860a4ea`](https://github.com/pagefind/pagefind/tree/v1.6.0) (tagged 2026-11-01). Every `pagefind` link below points at that tag. Spinel facts are pinned to `matz/spinel` commit [`afe2a92`](https://github.com/matz/spinel/tree/afe2a920fd66fb9e16df7b3356f9cf29b4546418) (2026-11-16). Elm package facts come from package.elm-lang.org as of 2026-11-15.

Sources: the repository source, the docs source under `docs/content/docs/` (this is what pagefind.app is built from), `CHANGELOG.md`, and the Elm package registry's `docs.json` and README files. No secondary write-ups were used.

Base URL used below: `PF = https://github.com/pagefind/pagefind/blob/v1.6.0`

---

## 1. Summary

- **Licence: MIT.** The root `LICENSE` reads "Copyright 2022 Pagefind" ([PF/LICENSE](https://github.com/pagefind/pagefind/blob/v1.6.0/LICENSE)), and the `pagefind` and `pagefind_web` crates declare `license = "MIT"`. The stemmer crate `pagefind_stem` is `MIT AND BSD-3-Clause` because it carries Snowball-generated code ([PF/pagefind_stem/Cargo.toml](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_stem/Cargo.toml)). A fork has to keep both notices.
- **Three Rust crates.** The Cargo workspace contains `pagefind` (the CLI indexer) and `pagefind_stem` (Snowball stemmers behind per-language features). It deliberately excludes `pagefind_web`, the search core compiled to WASM ([PF/Cargo.toml](https://github.com/pagefind/pagefind/blob/v1.6.0/Cargo.toml)). The TypeScript is in `pagefind_web_js` (the `pagefind.js` API) and `pagefind_ui/{default,modular,component}`. Wrappers live in `wrappers/{node,python}`.
- **The index format is internal and undocumented.** None of the user docs mention `pf_meta`, `pf_index`, `pf_fragment` or the CBOR layout. The only description is code comments in `pagefind_web/src/{metadata,index}.rs`, and those comments are already out of date: they omit `group_hash`, `meta_fields`, `additional_variants` and `meta_locs`.
- **The format changes within 1.x.** 1.5.0 added delta-encoding ("index chunks are now ~45% smaller") and diacritic variants. 1.6.0 added fragment grouping through `max_fragments` ([PF/CHANGELOG.md](https://github.com/pagefind/pagefind/blob/v1.6.0/CHANGELOG.md)). The only versioning is a generator version string. The JS logs a warning when versions differ but carries on. The WASM's own check is commented out.
- **On-disk layout.** `pagefind-entry.json` is plain JSON. `pagefind.<hash>.pf_meta`, `index/*.pf_index` and `filter/*.pf_filter` are gzip-wrapped CBOR. `fragment/*.pf_fragment` is gzip-wrapped JSON. Every gzip payload starts with the 12-byte magic string `pagefind_dcd` ([PF/pagefind/src/output/mod.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind/src/output/mod.rs)).
- **The browser side can be reused unchanged** against a different indexer's output, as long as that indexer reproduces the files byte-for-byte in structure, and also reproduces the tokenisation, normalisation and Snowball stemming. The WASM stems the query with the same `pagefind_stem` code, so a stemming mismatch quietly loses matches.
- **The browser assets are not separate release artefacts.** `pagefind.js`, the worker, the UIs and the 30-odd per-language `.wasm.gz` files are built into `pagefind/vendor/` (which is not in git) and embedded into the binary with `include_bytes!` ([PF/pagefind/src/output/mod.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind/src/output/mod.rs), [PF/pagefind_web/local_build.sh](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web/local_build.sh)). To vendor them, either build them, take them from the published crate (whose `include` lists `/vendor`), or capture them from a `pagefind` run.
- **WASM search core (`pagefind_web`, about 2,500 lines of Rust).** It decodes the CBOR, holds the index, stems the query, finds prefix extensions, scores with a tunable BM25 variant, and handles filters (bitsets), sorts and phrase ("exact") search. It does **not** decompress anything, fetch anything, build excerpts or highlight. All of that is in JS.
- **JS API (`pagefind_web_js`, about 2,000 lines of TypeScript plus 339 lines of vendored fflate).** It fetches files, gunzips with fflate, segments the query with `Intl.Segmenter`, drives the WASM through wasm-bindgen glue, and loads fragments. It also builds excerpts and sub-results, merges multisite indexes, and runs the search in a Web Worker.
- **UIs.** The Component UI (`<pagefind-*>` web components, new in 1.5, about 6,000 lines of TS and 1,500 lines of CSS) is now the headline UI. The Svelte "Default UI" (`new PagefindUI(...)`, about 1,200 lines) and the Modular UI are marked `legacy_ui: true` in the docs but are "available and supported for now" (CHANGELOG 1.5.0). The UIs share 46 translation files.
- **Heavy-lifting Rust dependencies.** `lol_html` (Cloudflare's streaming HTML rewriter) does the parsing. `pagefind_stem` (vendored Snowball, about 29,400 lines of generated code) does the stemming. `flate2` (gzip at `Compression::best()`) does the compression and `minicbor` the encoding. `unicode-segmentation` and `unicode-normalization` handle text, and `icu_segmenter` handles CJK and Thai, but only under the `extended` feature. `sha-1` produces the content-hash filenames and `rayon` and `tokio` provide parallelism ([PF/pagefind/Cargo.toml](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind/Cargo.toml)).
- **Indexer size.** About 6,400 lines of Rust in `pagefind/src`. Of that, the core to port is about 4,500: fossick, which parses and splits words (2,990), index (996), output (491) and fragments (29). The CLI, config, logging, serve and service-mode code accounts for the remaining 1,900 or so. Stemmers are about 29,400 lines of generated code on top.
- **Spinel's `wasm32-wasi` target cannot replace the WASM core as it stands.** It builds WASI preview-1 *programs* to run under wasmtime, `node:wasi` or "a browser with a WASI shim". `docs/wasm.md` documents no reactor mode or exported functions, which a library called from JS needs. Wasm builds also have a 32-bit `Integer`, a 64 MB GC slab by default and require exception handling ([spinel/docs/wasm.md](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/wasm.md)). The point no longer matters much now that the browser side is going to Elm.
- **Spinel already has what the indexer's encoding stage needs.** It ships `zlib` (its own inflate and deflate, with deflate limited to fixed-Huffman), `digest` (SHA-1), `json` and `unicode_normalize` as pre-installed packages ([spinel/packages](https://github.com/matz/spinel/tree/afe2a920fd66fb9e16df7b3356f9cf29b4546418/packages)). Still missing: CBOR (small to write), an HTML tokenizer, Snowball stemmers (Snowball has a C backend that could be carried through FFI), and UAX #29 word segmentation.
- **Elm side.** gzip inflate is covered: `folkertdev/elm-flate` and `folkertdev/elm-tiny-inflate` both export `inflateGZip`. CBOR is covered by `elm-toulouse/cbor` or `elm-cardano/cbor`. No Elm package implements **Snowball** stemming. `rluiten/stemmer` and `ggb/porterstemmer` are classical Porter, which is not the Snowball `english` algorithm that Pagefind uses. Stemming is therefore the hardest part of an Elm port.

---

## 2. The indexer (`pagefind` crate)

### 2.1 Crate and module layout

| Path | Lines | Role |
|---|---:|---|
| `pagefind/src/fossick/parser.rs` | 928 | Streams HTML through `lol_html`. Handles `data-pagefind-*` attributes (`body`, `ignore`, `meta`, `default-meta`, `filter`, `sort`, `weight`, `title`, `index-attrs`), and collects anchors, headings and auto-weights. |
| `pagefind/src/fossick/mod.rs` | 1,410 | Per-page pipeline: language detection, optional ICU segmentation for zh/ja/th, the weight stack (`weight_multiplier = 24.0`, `weight_max = 10.0`), and word positions. |
| `pagefind/src/fossick/splitting.rs` | 652 | Word normalisation, diacritic folding (NFD), compound and camelCase splitting, katakana suffixes, emoji, bigrams for segmented text, and stemming. |
| `pagefind/src/index/mod.rs` | 876 | Builds the inverted index, delta-encodes, chunks, hashes, handles collisions, and groups fragments. |
| `pagefind/src/index/index_{words,metadata,filter}.rs` | 120 | `minicbor` `#[derive(Encode)]` structs. These are the **de facto format spec**. |
| `pagefind/src/fragments/mod.rs` | 29 | The serde struct for the fragment JSON. |
| `pagefind/src/output/{mod,entry}.rs` | 491 | Writes files, gzips with the magic prefix, and embeds the browser assets. |
| `pagefind/src/service/*` | 624 | stdin/stdout JSON with base64 payloads, used by the Node and Python wrappers (`addHTMLFile`, `addCustomRecord`, `writeFiles`, …). |
| `lib.rs`, `options.rs`, `runner.rs`, `logging.rs`, `serve.rs`, … | 1,270 | CLI (`clap`), config (`twelf`: env, toml, yaml, json), and a dev server (`actix-web`, behind the `serve` feature). |

Feature flags: `default = ["serve"]`, and `extended = ["dep:icu_segmenter"]`. The released `pagefind_extended` binary is built with `--features extended` ([PF/.github/workflows/release.yml](https://github.com/pagefind/pagefind/blob/v1.6.0/.github/workflows/release.yml)). Integration tests are 397 `*.toolproof.yml` files under `pagefind/integration_tests/`. They are black-box tests that drive the binary and a browser, which makes them a usable conformance suite for a port.

### 2.2 Pipeline (from `index/mod.rs::build_indexes`)

1. **Fossick each page.** Extract the body, then build a weighted, positioned word list, plus meta, filters, sorts and anchors.
2. **Group by language.** Each language gets its own index.
3. **Fragments.** Each page's `PageFragmentData` (`url`, `content`, `word_count`, `filters`, `meta`, `anchors`) is serialised to JSON. It is named `<lang>_<sha1 prefix>`, starting at 7 hex characters and extended on collision. With `max_fragments`, pages are bundled into `<lang>_group_<hash>` files, and each page's `group_hash` points at its group.
4. **Word map.** For each word, record its pages, and for each page its `locs`. Locations are sorted with the default weight first. Weight changes are written inline as `-(weight)-1` followed by an absolute position, and the rest are deltas. `meta_locs` uses negative values as field-ID markers. Each word also stores `additional_variants`, which are diacritic forms carrying their own page lists.
5. **Chunk.** Words are sorted, then split by an accumulated-size counter (`index_chunk_size`). Each `MetaChunk` records `from` and `to` as shortest distinguishing prefixes (`get_prefixes`).
6. **Delta-encode page numbers** within each word's page list, then CBOR-encode each chunk and name it `<lang>_<sha1 prefix>`.
7. **Filters.** One CBOR file per filter key, holding the values and their page lists.
8. **Meta.** One CBOR `MetaIndex` per language, named `pagefind.<lang>_<hash>.pf_meta`.
9. **Entry.** `pagefind-entry.json` lists `{version, languages: {lang: {hash, wasm, page_count}}, include_characters}`.

There is a quirk in `utils::full_hash`. It formats each SHA-1 byte with `{:x?}`, which does not zero-pad, so the "hash" is not standard hex. It doesn't need reproducing. File names are opaque to the browser, which only follows the hashes stored in meta, and nothing verifies them.

### 2.3 On-disk format (v1.6.0)

Every file listed below as gzip is `gzip(b"pagefind_dcd" ++ payload)`. The JS checks for the magic string before and after gunzip, so serving the files already decompressed also works ([PF/pagefind_web_js/lib/coupled_search.ts](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web_js/lib/coupled_search.ts) `decompress`). The WASM files are stored with the same prefix and gzipped at build time.

```
pagefind/
  pagefind-entry.json                 JSON  {version, languages{lang:{hash,wasm|null,page_count}}, include_characters[]}
  pagefind.<lang>_<h>.pf_meta         gz+CBOR MetaIndex
  index/<lang>_<h>.pf_index           gz+CBOR WordIndex
  filter/<lang>_<h>.pf_filter         gz+CBOR FilterIndex
  fragment/<lang>_<h>.pf_fragment     gz+JSON PageFragmentData   (or a {hash: fragment} map when grouped)
  wasm.<lang>.pagefind / wasm.unknown.pagefind   gz(magic ++ wasm)
  pagefind.js, pagefind-worker.js, pagefind-highlight.js
  pagefind-ui.{js,css}, pagefind-modular-ui.{js,css}, pagefind-component-ui.{js,css}
```

CBOR schemas. `minicbor` derive encodes each struct as an array indexed by `#[n(i)]`:

- `MetaIndex = [version: str, pages: [MetaPage], index_chunks: [MetaChunk], filters: [MetaFilter], sorts: [MetaSort], meta_fields: [str]]`
  - `MetaPage = [hash, word_count: u32, group_hash]`. The decoder reads `group_hash` only when the array has three fields ([PF/pagefind_web/src/metadata.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web/src/metadata.rs)).
  - `MetaChunk = [from, to, hash]`, `MetaFilter = [filter, hash]`, `MetaSort = [sort, [page_no]]`
- `WordIndex = [[PackedWord]]`, with `PackedWord = [word, [PackedPage], [PackedVariant]]`, `PackedPage = [page_delta, locs: [i32], meta_locs: [i32]]` and `PackedVariant = [form, [PackedPage]]` ([PF/pagefind/src/index/index_words.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind/src/index/index_words.rs)).
- `FilterIndex = [filter, [[value, [page_no]]]]` ([PF/pagefind/src/index/index_filter.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind/src/index/index_filter.rs)).

**Versioned?** Only through the version string, in `MetaIndex.version` and the entry JSON. The JS compares the entry version with its own `pagefind_version` and calls `console.warn` on a mismatch. In `pagefind_web/src/lib.rs::search`, the generator-version check is commented out: `// return "ERROR: Version mismatch".into();`. The decoder is lenient about optional trailing fields, but nothing promises the format is stable.

**Documented?** No. `docs/content/docs/*.md` describes the HTML attributes, configuration and the JS and UI APIs, but not the file format. The Node and Python APIs (`getFiles`, `writeFiles`) treat the bundle as opaque ([PF/docs/content/docs/node-api.md](https://github.com/pagefind/pagefind/blob/v1.6.0/docs/content/docs/node-api.md)).

---

## 3. The browser side

### 3.1 What the WASM core (`pagefind_web`) does

The exports are wasm-bindgen functions taking a raw `*mut SearchIndex` ([PF/pagefind_web/src/lib.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web/src/lib.rs)): `init_pagefind(meta_bytes)`, `load_index_chunk`, `load_filter_chunk`, `add_synthetic_filter`, `request_indexes(query)`, `request_filter_indexes`, `request_all_filter_indexes`, `filters`, `set_ranking_weights`, `enter_playground_mode`, and `search(query, original_query, filter, sort, exact, exact_diacritics)`, which returns a JSON string.

| Concern | Where it runs | Notes |
|---|---|---|
| Fetching chunks | **JS** | `request_indexes` returns the chunk hashes whose `from..to` covers the query terms, and JS fetches them. |
| Decompression | **JS** | gzip, inflated by vendored **fflate** in `gz.js` (MIT, © Arjun Barrett). The WASM receives raw CBOR. |
| CBOR decoding | WASM | A hand-rolled `minicbor` `Decoder` with macros (`metadata.rs`, `index.rs`, `filter_index.rs`). It undoes the page-number and location deltas. |
| Query segmentation | **JS** | `Intl.Segmenter` (word and grapheme) plus `include_characters`. Diacritic stripping in JS is `normalize("NFD")` with mark removal. |
| Stemming | WASM | `pagefind_stem`, one WASM build per language plus `unknown`, which doesn't stem. `stems_from_term` and `find_word_extensions` do prefix matching on the last term. |
| Scoring | WASM | BM25 with `term_saturation` (k1), `page_length` (b) and `term_frequency` interpolation, plus `word_length_bonus` (term similarity), a diacritic bonus and meta-field weights ([PF/pagefind_web/src/search.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web/src/search.rs)). Weights are set at run time ([PF/docs/content/docs/ranking.md](https://github.com/pagefind/pagefind/blob/v1.6.0/docs/content/docs/ranking.md)). |
| Phrase search | WASM | `exact_term`, which uses positions. |
| Filters | WASM | `bit-set`. Supports `any`, `all`, `none` and `not` operators, nested objects and arrays, and counts per value, both filtered and unfiltered ([PF/pagefind_web/src/filter.rs](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web/src/filter.rs)). |
| Sorting | WASM | Precomputed page orders taken from `MetaIndex.sorts`. |
| Excerpts and highlighting | **JS** | `excerpt.ts` and `sub_results.ts` run over the fragment content, using the word locations the WASM returns. Page highlighting is a separate `pagefind-highlight.js`. |
| Fragments, multisite, worker | **JS** | `coupled_search.ts` (1,037 lines), `search_wrapper.ts` and `pagefind_worker.ts`. |

The JS↔WASM binding is the wasm-bindgen `--target no-modules` glue that `wasm-pack` generates. It is inlined into `pagefind.js` at index time as `WEB_JS` (`local_build.sh`, `output/mod.rs`). Replacing the WASM with anything else means replacing that glue too.

### 3.2 How sites consume it (the surface an Elm port has to decide on)

- **The JS API**, from [PF/docs/content/docs/api.md](https://github.com/pagefind/pagefind/blob/v1.6.0/docs/content/docs/api.md) and [PF/pagefind_web_js/lib/public_search_api.ts](https://github.com/pagefind/pagefind/blob/v1.6.0/pagefind_web_js/lib/public_search_api.ts). Sites call `const pagefind = await import("/pagefind/pagefind.js")`, and the module exports `options`, `init`, `destroy`, `mergeIndex`, `search`, `debouncedSearch`, `preload`, `filters` and `createInstance`. `search()` returns `{results: [{id, score, words, data: async () => …}], unfilteredResultCount, filters, totalFilters, timings}`, and `data()` returns `{url, content, excerpt, plain_excerpt, meta, filters, anchors, sub_results, word_count, …}`. The bundle path is derived from `import.meta.url`.
- **Component UI**, the current recommended UI ([PF/docs/content/docs/search-ui.md](https://github.com/pagefind/pagefind/blob/v1.6.0/docs/content/docs/search-ui.md)). Sites add `<link href="/pagefind/pagefind-component-ui.css">` and `<script type="module" src="/pagefind/pagefind-component-ui.js">`, then use elements such as `<pagefind-modal>`, `<pagefind-modal-trigger>`, `<pagefind-searchbox>`, `<pagefind-input>`, `<pagefind-results>`, `<pagefind-summary>`, `<pagefind-filter-dropdown>`, `<pagefind-filter-pane>` and `<pagefind-keyboard-hints>`, linked by an `instance="…"` attribute. Styling is through CSS variables. It is also published on npm as `@pagefind/component-ui`.
- **Default UI (legacy)** ([PF/docs/content/docs/ui-usage.md](https://github.com/pagefind/pagefind/blob/v1.6.0/docs/content/docs/ui-usage.md), [ui.md](https://github.com/pagefind/pagefind/blob/v1.6.0/docs/content/docs/ui.md)). Sites add `<script src="/pagefind/pagefind-ui.js">` and call `new PagefindUI({element: "#search", showSubResults, showImages, excerptLength, processTerm, processResult, translations, …})`. Styling uses the `--pagefind-ui-*` CSS variables.
- **Modular UI**: `pagefind-modular-ui.js`. It is also legacy.

### 3.3 Browser-side size

| Component | Lines |
|---|---:|
| `pagefind_web/src` (Rust → WASM) | 2,498, of which `search.rs` is 962 and `lib.rs` 588 |
| `pagefind_web_js/lib` | 2,336, including 339 of vendored fflate |
| `pagefind_ui/component` | about 6,000 TS + 1,500 CSS |
| `pagefind_ui/default` | 1,390 (Svelte 4, of which 1,175 is in `svelte/`) |
| `pagefind_ui/modular` | 1,095 |
| `pagefind_ui/translations` | 46 JSON files |

Counts were taken at v1.6.0 with `wc -l`, excluding `node_modules`, `_dev_files` and tests.

### 3.4 Can the browser side be reused unchanged against another indexer's output?

Yes, mechanically: the JS and WASM read only the files in §2.3. To get the same results, the other indexer must also:

1. Emit the CBOR structs exactly as above (array-encoded, same field order, deltas, weight and meta markers).
2. Produce the same indexed word forms: normalisation, diacritic variants, compound parts and Snowball stems. The WASM stems the **query** with `pagefind_stem` and looks up `from..to` prefix ranges, so an index stemmed differently returns too few or wrong hits.
3. Pin itself to one Pagefind release's assets, because the format has changed between minor releases (§2.3).

---

## 4. Porting the indexer to Spinel Ruby

What Spinel already provides as pre-installed packages, at `afe2a92`:

| Need | Pagefind uses | Spinel | Gap |
|---|---|---|---|
| gzip | `flate2` (best compression) | `packages/zlib`: its own C, not a libz binding. "Inflate is complete … Deflate is LZ77 with a hash chain emitting fixed-Huffman blocks" ([sp_zlib.c](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/packages/zlib/sp_zlib.c)) | Valid output, but larger files than Pagefind's. |
| SHA-1 | `sha-1` | `packages/digest` (`sha1.rb`, backed by `lib/sp_crypto.c`) | None |
| JSON | `serde_json` | `packages/json` | None |
| NFD and diacritic folding | `unicode-normalization` | `packages/unicode_normalize` | Check coverage. |
| CBOR | `minicbor` | None | Small to write. Only array, uint/nint, text and the derive layout are needed. |
| HTML parsing | `lol_html` | None (`rexml` is XML only) | Write a tolerant tokenizer in Ruby, or carry a C parser through FFI. Pagefind needs only a streaming tokenizer with selector matching, not a DOM. |
| Stemming | Snowball (Rust output) | None | Snowball has a C backend, so its generated C could be carried through FFI. It must be the same Snowball version and algorithms (`english`, not `porter`). |
| Word segmentation | `unicode-segmentation` (UAX #29) | Unknown | Needs word-break property tables. |
| CJK and Thai segmentation | `icu_segmenter` (dictionary-based, `extended` only) | None | Defer it: the default binary doesn't have it either. |
| Parallelism | `rayon`, `tokio` | Threads exist natively, but not on wasm | Single-threaded is fine. |

Suggested scope, smallest first:

1. **CBOR, the format writer and gzip.** Port `index/` and `output/`, about 1,500 lines, and validate by reading Pagefind's own fixtures back.
2. **Fossick minus CJK.** Port `fossick/` and `splitting.rs`, about 3,000 lines of Rust, which will be more lines of Ruby once the `lol_html` work is replaced.
3. **Stemming through Snowball C via FFI**, starting with English.
4. Then everything else: the service mode, `serve` (Ebenezer has its own dev server), multi-format config and `extended`.

Spinel limits that matter: no `eval` or `method_missing` (the serde-style derive has to be written by hand), and only libc and libm are linked, so all C must be carried.

---

## 5. Can Spinel `wasm32-wasi` replace the WASM search core?

Not plausibly as of `afe2a92` ([spinel/docs/wasm.md](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/wasm.md)):

- It targets **WASI preview 1** hosts (wasmtime, `node:wasi`, "a browser with a WASI shim"). Pagefind's JS instantiates a wasm-bindgen module and calls exported functions on it, which needs a reactor or library build that exports Ruby methods. `docs/wasm.md` documents none, and no "reactor" or export mechanism turned up in Spinel's docs, `src` or `lib`.
- `Integer` is 32 bits on wasm32. The default GC slab adds 64 MB to the memory size (tunable with `SPINEL_GC_SLAB_MB`). The engine has to support the standardised exception-handling proposal, or the build must use `--exceptions=abort`. There are no threads.
- Even if those were solved, the wasm-bindgen glue would still need replacing.

With the browser side going to Elm, this question is mostly moot.

---

## 6. An Elm port of the browser side

### 6.1 What the Elm port would have to reimplement

All of it, because Elm can't call the WASM synchronously. The alternative is to keep the WASM behind ports or a custom element, which is asynchronous and keeps the wasm-bindgen JS. Ordered by difficulty:

1. **Snowball stemming of the query, matching the indexer exactly.** This is the hard part (§6.2).
2. **Ranking.** Port `search.rs` (962 lines) faithfully: BM25 variant, word-length bonus, diacritic bonus, meta-field weights, prefix extension and phrase matching.
3. **CBOR decoding** of meta, word and filter chunks, including undoing the deltas and parsing the weight and meta markers.
4. **gzip inflate**, then strip the magic prefix.
5. **Filters and sorts.** Set operations over page numbers. Elm has no bitset in core, but `Set Int` or a packed `Array` would do.
6. **Excerpt and sub-result building.** Port `excerpt.ts`, `sub_results.ts` and `highlight.ts`, about 330 lines.
7. **Query segmentation.** `Intl.Segmenter` isn't available from Elm. Use a port, or whitespace splitting plus `include_characters`. CJK quality depends on it.
8. **The UI.** Rebuild whichever subset of Component UI or Default UI behaviour is wanted, plus translations.
9. **Fetch orchestration, multisite merging, worker offload and preloading.**

### 6.2 Elm packages: what exists (package.elm-lang.org, 2026-11-15)

| Need | Package | What it gives | Caveat |
|---|---|---|---|
| Bytes | `elm/bytes` (core) | `Bytes.Decode` and `Encode` | None |
| gzip inflate | [`folkertdev/elm-flate` 2.0.6](https://package.elm-lang.org/packages/folkertdev/elm-flate/2.0.6/) | `Flate.inflateGZip`, `inflate`, `inflateZlib`, `crc32` and deflate | Speed on large chunks is untested. |
| gzip inflate | [`folkertdev/elm-tiny-inflate` 1.1.2](https://package.elm-lang.org/packages/folkertdev/elm-tiny-inflate/1.1.2/) | `Inflate.inflateGZip` | Inflate only, so smaller. |
| CBOR | [`elm-toulouse/cbor` 4.0.1](https://package.elm-lang.org/packages/elm-toulouse/cbor/4.0.1/) | `Cbor.Decode` (RFC 7049) | None |
| CBOR | [`elm-cardano/cbor` 1.0.0](https://package.elm-lang.org/packages/elm-cardano/cbor/1.0.0/) | `Cbor.Decode` (RFC 8949), `arrayHeader` and record builders | None |
| Stemming | [`rluiten/stemmer` 1.0.4](https://package.elm-lang.org/packages/rluiten/stemmer/1.0.4/) | `Stemmer.stem`, "an implementation of the porter stemmer" (README) | Classical Porter, **not** Snowball `english`, so it won't match the index. |
| Stemming | [`ggb/porterstemmer` 1.0.3](https://package.elm-lang.org/packages/ggb/porterstemmer/1.0.3/) | Classical Porter | Same caveat. |
| Stemming | [`eniac314/french-stemmer` 1.0.0](https://package.elm-lang.org/packages/eniac314/french-stemmer/1.0.0/) | French "Porter" | Not verified against Snowball `french`. |
| Diacritics | [`8n8/elm-string-normalize`](https://package.elm-lang.org/packages/8n8/elm-string-normalize/1.0.0/), [`kuon/elm-string-normalize`](https://package.elm-lang.org/packages/kuon/elm-string-normalize/1.0.6/), [`algebraicsystems/elm-unicode-normalize`](https://package.elm-lang.org/packages/algebraicsystems/elm-unicode-normalize/1.1.0/) | Diacritic removal, or full Unicode normalisation | Folding must match the indexer's. |

The search was a keyword sweep of `package.elm-lang.org/search.json` (2,086 packages) for flate, gzip, inflate, cbor, stem, snowball, porter, normaliz, segment, bitset and unicode. **No Snowball implementation was found.** The options are:

1. Write an Elm backend for the Snowball compiler. Snowball is a code generator, and its site says a "Javascript backend [was] merged" ([snowballstem.org](https://snowballstem.org/)).
2. Call Snowball's generated **JavaScript** stemmer through a port. This works, but it is asynchronous and outside Elm.
3. Hand-port Snowball `english` to Elm and test it against Snowball's published vocabulary lists.
4. Have the Ruby indexer and the Elm client share a different stemmer. This gives up drop-in compatibility with upstream's index.

---

## 7. Implications for Ebenezer

- **Pick one compatibility target and pin it.** Either Ebenezer writes the Pagefind v1.6.0 on-disk format and can lean on upstream's JS, UI and toolproof tests, or it owns the format end to end (Ruby indexer plus Elm client). Now that the client is going to Elm, owning the format is cheap. The upstream format is undocumented and changes between minor versions, so there is little to gain by staying byte-compatible beyond reusing the test fixtures during development.
- **The stemmer is the shared contract.** Whatever algorithm the Ruby indexer uses, the Elm client must use exactly the same one. Snowball C (indexer, through FFI) together with a Snowball-derived Elm or JS stemmer (client) is the only route that keeps upstream's ranking behaviour.
- **The split of work is not where you'd expect.** Most of the browser "core" (fetching, gunzip, excerpts, sub-results, segmentation) is already JS rather than WASM. An Elm port replaces both `pagefind_web` and `pagefind_web_js`, about 4,500 lines combined, plus whatever UI is wanted.
- **Deferral candidates:** `extended` CJK and Thai segmentation, multisite `mergeIndex`, service mode, playground, `max_fragments` grouping, and the legacy Default and Modular UIs.
- **Licence:** MIT plus BSD-3-Clause for Snowball. Keep the notices in the fork and in shipped assets. fflate is MIT if `gz.js` is vendored.

---

## 8. Uncertainties

- **Weight encoding.** `positions_to_packed_page` treats `25` as the default weight, but the fossicker's `weight_multiplier` is `24.0`. I didn't trace where 25 comes from. Confirm with a decoded fixture before porting.
- **Line counts** are raw `wc -l` output, including comments and Rust `#[cfg(test)]` modules (`index/mod.rs` has tests inline). Treat them as about ±15%.
- **The Spinel wasm reactor and export finding** is based on `docs/wasm.md` and a grep of `docs/`, `src/` and `lib/` at `afe2a92`. A mechanism might exist without documentation.
- **Spinel's `unicode_normalize` coverage** and its fixed-Huffman deflate ratio, compared with `flate2::Compression::best()`, were not measured.
- **Elm package performance** (elm-flate and CBOR decoding on index chunks of hundreds of KB) and the French stemmer's agreement with Snowball were not tested.
- **The pagefind.app pages** were read from the repo's `docs/content` at the tag, not from the live site. They may differ slightly from what is deployed.
- **The published crate's `/vendor`** (the `include` list) was not downloaded to confirm the WASM and JS are inside it. The release workflow suggests so, because it runs `cargo publish` after building the wasm.
