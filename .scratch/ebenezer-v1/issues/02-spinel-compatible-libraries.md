# Spinel-compatible Markdown, YAML and templating libraries

Type: research
Status: resolved
Blocked by:

## Question

Which existing Ruby libraries for Markdown (kramdown, redcarpet, commonmarker…), YAML (Psych, pure-Ruby parsers), and templating (Liquid, ERB, Mustache, Tilt…) are pure Ruby and plausibly compile under Spinel, and which are ruled out (C extensions, heavy metaprogramming, eval)? Note what each library's dynamic-feature usage is.

## Answer

Findings: branch `research/spinel-compatible-libraries`, file `.scratch/ebenezer-v1/research/spinel-compatible-libraries.md` (rules pinned to matz/spinel @ afe2a920). Nothing was compiled; the verdicts come from reading the sources plus the SpinelGems survey, which only checks that a gem compiles.

- **YAML:** use Spinel's bundled pure-Ruby `psych`. It can't build Date/Time objects, so front-matter dates must be read as strings, and it reads only the first document. The `psych` gem (C), safe_yaml and syck are ruled out.
- **Markdown:**
  - motion-markdown-it is the best pure-Ruby option.
  - kramdown needs a small fork to remove its `method_missing` and computed `define_method`.
  - spinel-commonmarker is an existing port that compiles cmark-gfm from C, if C is acceptable.
  - redcarpet, commonmarker 2.x and maruku are ruled out.
- **Templating:** no engine runs unmodified. Liquid needs a moderate fork (it builds a filter class at run time and calls `send`). Mustache, ERB, Erubi, Tilt, Haml and Slim are ruled out, since they all eval generated Ruby. The real choice is forking Liquid or writing a small interpreter.
- For the toolchain spike: actually compile motion-markdown-it, kramdown, spinel-commonmarker and bundled psych, and diff their output against CRuby.
