# Map: Ebenezer v1

Label: wayfinder:map

## Destination

A build-ready **v1 spec** for Ebenezer: a Jekyll-inspired, simplified static site generator whose shipped artifact is a native binary compiled by Spinel. The map is done when nothing is left to decide before someone builds v1.

## Notes

- Domain: static site generation in Ruby, constrained to the subset Spinel can compile. Any third-party Ruby must also compile under Spinel.
- The shipped artifact is a Spinel-compiled binary. Running on CRuby is nice to have for development, not a requirement.
- Borrow Jekyll's conventions (front matter, `_layouts/`, `_posts/`, `_config.yml`, …) but promise no Jekyll compatibility.
- v1 targets any kind of site: blogs, small sites, docs portals, sites with multiple collections.
- Skills for every session: `grilling` + `domain-modeling` for grilling tickets; `research` for research tickets. Keep `GLOSSARY.md` current as content-model terms settle.
- Tracker: local markdown (`.scratch/ebenezer-v1/`). Ask one grilling question at a time.

## Decisions so far

<!-- one line per resolved ticket: [title](issues/NN-slug.md): gist -->

## Not yet specified

- **Config schema**: what goes in `_config.yml`, defaults, and how it overrides per collection or directory.
- **Module architecture**: how the reader, renderer and writer pipeline is split into modules, given Spinel's constraints.
- **Asset handling**: Sass/CSS processing, fingerprinting, or plain copy-through.
- **Incremental builds and performance targets**: what "fast" means, measured how.
- **Error reporting**: diagnostics for bad front matter and template errors.
- **Testing strategy**: how to test code that has to compile under Spinel.
- **Distribution and packaging**: how the binary is built and shipped per platform.

## Out of scope

- Plugin system: ruled out for v1 by the user.
- Jekyll compatibility: Ebenezer borrows conventions only; existing Jekyll sites are not promised to build.
- Building v1 itself: the map ends at the spec.
