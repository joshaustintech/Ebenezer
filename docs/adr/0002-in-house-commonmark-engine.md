# Write our own CommonMark-compliant Markdown engine

Ebenezer renders Markdown with its own engine, written in Spinel-compatible Ruby and 1:1 compliant with the CommonMark specification (https://commonmark.org). Spinel ships no Markdown library. Each existing option has a catch: motion-markdown-it compiles but isn't behaviour-verified, kramdown needs a fork to remove `method_missing`, and spinel-commonmarker means shipping C code. We chose to write our own because then the conformance bar (the spec's own examples) is the definition of done, there is no C in the build, and there is no third-party code to keep patching.

## Considered Options

- motion-markdown-it (pure Ruby, plausible but unverified under Spinel)
- A kramdown fork (not CommonMark; needs its `method_missing` removed)
- spinel-commonmarker (cmark-gfm compiled from C)
