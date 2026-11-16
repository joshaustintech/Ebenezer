# Pagefind port scope

Type: grilling
Status: open
Blocked by: 03, 13

## Question

Ebenezer ports Pagefind as two built-ins: a Spinel Ruby indexer and an Elm browser runtime (see [Pagefind browser runtime](15-pagefind-browser-runtime.md)). What do they cover in v1?
- **Features:** multilingual, filters, metadata, sorting, weighting, `data-pagefind-*` attributes, excerpts, CJK.
- **Index format:** do we keep Pagefind's on-disk index format, so either half could be swapped for upstream's, or define our own?
- **Browser API:** does the Elm runtime keep the `pagefind.js` / `PagefindUI` API, or define its own, and how do sites embed it and theme it?
- **Build:** when indexing runs in the build, and how it is configured.
- **Upstream:** how both forks track upstream.
