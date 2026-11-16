# Pagefind port scope

Type: grilling
Status: open
Blocked by: 03, 13

## Question

Ebenezer ports Pagefind as two built-ins: a Spinel Ruby indexer and an Elm browser runtime (see [Pagefind browser runtime](15-pagefind-browser-runtime.md)). What do they cover in v1?
- **Features:** multilingual, filters, metadata, sorting, weighting, `data-pagefind-*` attributes, excerpts, CJK.
- **Index format:** do we keep Pagefind's on-disk index format, so either half could be swapped for upstream's, or define our own? Research: the upstream format is undocumented and changed in 1.5 and 1.6.
- **Browser API:** does the Elm runtime keep the `pagefind.js` / `PagefindUI` API, or define its own, and how do sites embed it and theme it?
- **Stemming:** which languages v1 stems, and how the Ruby indexer and Elm runtime are guaranteed to stem identically. Options: Snowball C via FFI paired with a Snowball-derived Elm port, Snowball's JS output called through a port, or our own stemmer on both sides.
- **Build:** when indexing runs in the build, and how it is configured.
- **Upstream:** how both forks track upstream.
