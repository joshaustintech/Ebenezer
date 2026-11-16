# Spinel-compatible Markdown, YAML and templating libraries

Research for ticket `.scratch/ebenezer-v1/issues/02-spinel-compatible-libraries.md`.
Researched 2026-11-15.

## Question

Which existing Ruby libraries for Markdown, YAML and templating are pure Ruby
and could plausibly compile under Spinel? Which are ruled out by C
extensions, heavy metaprogramming or `eval`? What dynamic features does each
one use?

## Short answer

- **YAML: use Spinel's bundled `psych`.** It is a pure-Ruby rewrite of
  Psych plus libyaml that ships with the compiler. `Psych.safe_load` works
  for strings, numbers, symbols, booleans, nil, arrays and hashes. It
  cannot build a Date or Time, and it reads only the first document of a
  stream. The real `psych` gem is a C extension and cannot be used. No
  other pure-Ruby YAML parser is a live option.
- **Markdown: the best pure-Ruby option is `motion-markdown-it`.** It is a
  CommonMark port of markdown-it, and it uses almost no dynamic features.
  `kramdown` (with `kramdown-parser-gfm`) is plausible after a small fork
  that removes its `method_missing` entry point and its runtime
  `define_method`. There is also a non-pure-Ruby route:
  [`spinel-commonmarker`](https://github.com/roundhouse-rb/spinel-commonmarker),
  an existing Spinel port that compiles cmark-gfm from vendored C.
  `redcarpet`, `commonmarker` (Rust), `rdiscount` and the other C-backed
  gems are ruled out as they stand.
- **Templating: nothing works off the shelf.** Every mainstream Ruby engine
  except Liquid (ERB, Erubi, Erubis, Tilt, Mustache, Haml, Slim, Mote,
  Tenjin) turns the template into Ruby source and `eval`s it. Spinel
  refuses that by design. Spinel's bundled `erb` package only substitutes
  `<%= name %>` from a Hash. **Liquid** is the one engine built as an
  interpreter, which is the shape Spinel needs. It still needs a fork: its
  filter system builds classes and `include`s modules at run time, and it
  uses method reflection.

## Spinel's restrictions (what we tested against)

Primary source: [matz/spinel](https://github.com/matz/spinel) at commit
`afe2a920fd66fb9e16df7b3356f9cf29b4546418` (2026-11-16 JST). Spinel is a
whole-program AOT compiler. It infers types, emits C, and links against
libc and libm. It is MIT licensed
([README](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/README.md)).
The authoritative list of limits is
[`docs/limitations.md`](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md)
(cited below as `L#line`).

| Feature | Spinel behaviour | Source |
|---|---|---|
| `eval`, `instance_eval(str)`, `class_eval(str)` | Refused at compile time. The block forms (`instance_eval { }`) compile. A literal-string `class_eval` in a class body is expanded at compile time. Code in a `RUBY_ENGINE == "spinel"` else-branch is dropped before analysis. | [L54](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L54), [L57](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L57) |
| `method_missing` | Never dispatched. Defining it only warns, so a library that relies on it compiles but fails when the missing method is called. | [L55](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L55) |
| `define_method` | Works with a literal name, with an unrolled literal list, and with a class-body macro whose literal arguments build the name. A computed name or body is refused in reachable code. `send(:define_method, name)` is not refused, but it defines nothing that can be called. | [L59-L60](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L59) |
| `send` / `public_send` with a computed name | Partially supported. It becomes a static dispatch over the names the program uses or the methods the receiver's class has. An unmatched name raises `NoMethodError`. A literal name resolves fully. | [L205-L246](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L205) |
| `const_get` with a run-time name | Becomes a static dispatch over the program's constants. The result is a boxed (poly) value. | [L1679](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L1679) |
| `autoload` | Supported for literal or `__dir__`-relative paths. The file loads when the program starts, not on first use. | [L1951](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L1951) |
| `ObjectSpace` (`each_object`, `count_objects`) | Unsupported. Finalizers work. | [L62](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L62) |
| `binding` as an object | Unsupported, except `binding.local_variable_get(:literal)`. | [L64](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L64) |
| Changing a class at run time from a method (`K.include(M)`, `K.define_method`) | Refused inside a method, block or condition. The same statements work in a class body or at top level. | [L93](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L93) |
| `Class.new(parent)` | Works when the superclass is a constant. A non-constant superclass is refused. | [L68](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L68) |
| Reflection (`methods`, `instance_variables`, computed `instance_variable_get`) | Partial: it is answered from compile-time tables. | [L102](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L102) |
| C extensions (gem `ext/`) | Gem-style native extensions are not loaded. Native code enters through Spinel's own FFI DSL or through C that a spin package carries. | [docs/FFI.md](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/FFI.md), [docs/spin.md#native-c-in-a-package](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/spin.md) |
| A third-party pure-Ruby library | Added with `-I dir` or a `spin.toml` dependency. Its `.rb` files are spliced into the whole-program compile, and no manifest is needed. | [docs/require.md "Providing your own feature"](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/require.md) |
| `require` with a path computed at run time | Loads only files the program was compiled with. Otherwise it raises `LoadError`, or answers `nil` or `false` under the default load model. | [L108](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L108) |
| Encodings | UTF-8 and ASCII-8BIT only. | [L202](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L202) |

One more flag is useful for vendored libraries: `--defer-refusals`, or the
magic comment `# spinel: defer-refusals` at the top of a file, turns the
eligible compile-time refusals in that file into run-time
`NotImplementedError`. A vendored library can then keep an unsupported
method that our code never calls
([L36-L43](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L36)).

### What Spinel itself ships or demonstrates

- **Packages bundled with the compiler** ([`packages/`](https://github.com/matz/spinel/tree/afe2a920fd66fb9e16df7b3356f9cf29b4546418/packages)).
  The ones relevant here are `psych`, `yaml`, `erb`, `strscan`, `stringio`,
  `rexml`, `json`, `cgi`, `set`, `date`, `bigdecimal`, `pathname`,
  `fileutils`, `find`, `optparse` and `time`. The limitations table gives
  the list of stdlib that ships this way
  ([L107](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L107)).
- **Bundled YAML.** The package is Psych and libyaml's emitter written in
  Ruby. It cannot build a Date or Time, cannot build tagged objects under
  `unsafe_load`, does not support `freeze: true` or `Psych.parse`, and has
  no node or event API. Those raise `NotImplementedError`. Otherwise it
  loads "as Psych 5.3.1 does"
  ([L111](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L111);
  header of [`packages/psych/psych.rb`](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/packages/psych/psych.rb), 1,621 lines).
  It reads block and flow collections, every scalar style, anchors and
  aliases, merge keys, and "the first document of a stream". YAML front
  matter is a single document, so this is enough.
- **Bundled ERB.** "ERB templates with Ruby code in a tag ... unsupported
  ... a template is compiled at runtime, which needs eval."
  `ERB#result_with_hash` renders only `<%= name %>`, comments and
  `trim_mode: "-"`, plus `ERB::Util` escaping
  ([L110](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L110);
  [`packages/erb/erb.rb`](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/packages/erb/erb.rb), 155 lines).
- **Gem compatibility.** The README says Spinel "compiles certain gems into
  your program". It points to the
  [SpinelGems survey](https://github.com/OriPekelman/spinelgems), which
  measures which RubyGems compile, and to
  [awesome-spinel](https://github.com/aristotelesbr/awesome-spinel), a list
  of ported gems
  ([README "ecosystem" list](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/README.md)).
  The official [spin-index](https://github.com/matz/spin-index) lists only
  `pg`, `redis` and `spinel_kit` today. The limitations doc also uses
  sqlite3, racc and activesupport's `blank.rb` as worked examples.
- **Spinel's test suite** contains a fixture modelled on a Markdown class's
  `define_method` extension macro
  ([`test/class_method_define_method_macro.rb`](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/test/class_method_define_method_macro.rb)).
  It also contains a regression test taken from Tep's Mustache code
  ([`test/typed_hash_caller_no_body_widen.rb`](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/test/typed_hash_caller_no_body_widen.rb)).

### SpinelGems survey (empirical lower bound)

[OriPekelman/spinelgems](https://github.com/OriPekelman/spinelgems) at
`d981e359d086fc3d4367a053e1318a039f0dc4d4`. I used the
`survey-2814693f/compat.jsonl` run (Spinel rev `2814693f`, 2026-11-11). For
each gem the survey compiles its `lib/` entry points and scans the result.
Verdicts, per
[`docs/cli.md`](https://github.com/OriPekelman/spinelgems/blob/d981e359d086fc3d4367a053e1318a039f0dc4d4/docs/cli.md):

- `clean`: it compiles. Nothing is run.
- `risky`: it compiles, but uses constructs Spinel silently degrades.
- `rejected`: it does not compile, or it is a known C extension.

`clean` does **not** mean it works. The survey's README says to trust only
`verified`, and none of the gems below is `verified`.

## Per-library findings

How these were checked: each gem was fetched from rubygems.org
(`https://rubygems.org/gems/<name>/versions/<version>`) and unpacked. I
grepped `lib/**/*.rb` for each dynamic feature and read every hit. Line
references are paths inside the gem. Licences and dependencies come from
each gemspec.

### Markdown

| Library (version) | Pure Ruby? | Dynamic features (where) | Runtime deps | Licence | Survey | Verdict |
|---|---|---|---|---|---|---|
| **motion-markdown-it** 13.0.1 ([repo](https://github.com/digitalmoksha/motion-markdown-it)) | Yes. 56 files, about 7.7k LOC. It is a port of markdown-it 13.0.1 (CommonMark plus GFM tables and strikethrough). | Two `self.send(name)` calls over preset component names (`index.rb:375,378`). Rules are lambdas kept in constant arrays and hashes (`parser_inline.rb:14-38`, `renderer.rb:261`); Spinel supports closures in containers. There is no `eval`, `method_missing`, `define_method` or `const_get`. A RubyMotion branch sits behind `if defined?(Motion::Project::Config)` (`motion-markdown-it.rb:3`). | mdurl-rb, uc.micro-rb, linkify-it-rb. All three are pure Ruby and `clean` in the survey. | MIT | risky (`send`) | **Plausible.** This is the strongest pure-Ruby candidate. |
| **kramdown** 2.5.2 ([repo](https://github.com/gettalong/kramdown)) | Yes. 55 files, about 8.5k LOC. | `Document#method_missing` provides `to_html` and the other `to_*` methods (`document.rb:113-121`), and Spinel never dispatches it. `Utils::Configurable#configurable` calls `singleton_class.send(:define_method, …)` with computed names inside a method (`utils/configurable.rb:30-37`). Computed `const_get` picks the parser and converter (`document.rb:102,116`; `utils.rb:40`). There are 19 literal `autoload`s (`parser.rb`, `converter.rb`, `utils.rb`). Computed `send("convert_#{type}")` and `send(@dispatcher[type])` appear in the converters (`converter/html.rb:58,71` and others). The `template` option uses `ERB` with `instance_eval { binding }` (`converter/base.rb:135`). | rexml ≥ 3.4.4. Spinel bundles `rexml`, and kramdown uses only `REXML::Parsers::BaseParser` regexps. | MIT | risky (`instance_eval`, `binding`, `method_missing`, `define_method`, `send`) | **Needs a small fork.** Call `Kramdown::Converter::Html.convert(root, opts)` directly instead of `Document#to_html`. Replace `Configurable` with explicit methods. Drop the `template` option and the LaTeX, man and syntax-highlighter paths. The remaining `send` and `const_get` uses fall within Spinel's static-dispatch support. |
| **kramdown-parser-gfm** 1.1.0 ([repo](https://github.com/kramdown/parser-gfm)) | Yes. 3 files, 290 LOC. | None. | kramdown | MIT | clean | **Plausible**, but only together with a forked kramdown. |
| **redcarpet** 3.6.1 ([repo](https://github.com/vmg/redcarpet)) | No. It is a C extension (`ext/redcarpet`, sundown). | `define_method method` in `render_strip.rb:24`. | none | MIT | rejected (c-extension) | **Ruled out as it stands.** It could be re-ported the way spinel-commonmarker was, but nobody has done that. |
| **commonmarker** 2.9.0 ([repo](https://github.com/gjtorikian/commonmarker)) | No. It is a Rust extension (`ext/commonmarker/Cargo.toml`, comrak through rb_sys). | Computed `define_singleton_method` (`config.rb:93`). | rb_sys | MIT | **clean, which is misleading**: the scan saw only the 354-line Ruby wrapper, and the native part cannot load under Spinel. | **Ruled out.** |
| **spinel-commonmarker** ([repo](https://github.com/roundhouse-rb/spinel-commonmarker)) | No. It is a Spinel port of the commonmarker 2.x API over cmark-gfm 0.29.0.gfm.13, which it vendors and compiles with the package. Its README says this needs "a C compiler; nothing else". | Written for Spinel. | none (vendored C) | MIT. The vendored cmark-gfm is BSD-2-Clause and others. | n/a | **Plausible** if we accept C in the build. Per its README: the default options make a bare `to_html` raise, 22 spec examples differ, and it has no `sourcepos` or syntax highlighting. It does not say whether footnotes are supported. |
| **rdiscount** 2.2.7.5 | No. It is a C extension (Discount). | n/a | none | BSD-3-Clause | rejected (c-extension) | **Ruled out.** |
| **maruku** 0.7.3 | Yes. About 7.5k LOC, and no longer maintained. | `method_missing` that forwards through `send` (`input/charsource.rb:240-245`). `instance_eval(code)` on a string (`input/parse_doc.rb:113`). `attr_accessor` added through `send` on a singleton (`element.rb:61-63`). | none | MIT | risky | **Ruled out in practice**: it would need a fork, and it is unmaintained. |
| bluecloth, markly, rpeg-markdown | No (C) | n/a | n/a | n/a | rejected (c-extension) | **Ruled out.** |
| rdoc (its Markdown parser) 8.0.0 | Yes | `binding`, `define_method`, `class_eval` | several | Ruby | rejected (analyze timeout) | **Ruled out.** |

### YAML

| Library (version) | Pure Ruby? | Dynamic features | Deps | Licence | Survey | Verdict |
|---|---|---|---|---|---|---|
| **Spinel bundled `psych`** ([packages/psych](https://github.com/matz/spinel/tree/afe2a920fd66fb9e16df7b3356f9cf29b4546418/packages/psych)) | Yes. Parser and emitter are both Ruby, and it ships with the compiler. | Written for Spinel. | none | MIT (Spinel's). The scalar rules are copied from Psych, which is also MIT. | n/a | **Plausible. This is the default choice.** Load front matter with `safe_load`. Dates such as `date: 2024-01-15` cannot become Date objects: under `safe_load` they raise `DisallowedClass` as Psych does, and with Date permitted they raise `NotImplementedError` ([L111](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L111)). Ebenezer should read dates as strings and parse them itself. |
| **psych** gem 5.4.0 ([repo](https://github.com/ruby/psych)) | No. It is a C extension over libyaml (`ext/psych`). | `class_eval <<~RUBY` (`class_loader.rb:39`, `tree_builder.rb:44`). Computed `define_method` (`handlers/recorder.rb:34`). Computed `const_get` (`class_loader.rb:38,69-71`). Computed `send` (`visitors/yaml_tree.rb:132`, `visitors/to_ruby.rb:187`). | stringio, date | MIT | rejected (c-extension) | **Ruled out.** Spinel's bundled package replaces it under the same name. |
| **yaml** gem 0.4.0 | A shim that requires `psych`. | none | psych | not checked | rejected | **Not needed.** Spinel bundles `yaml`, which loads its `psych`. |
| **safe_yaml** 1.0.5 ([repo](https://github.com/dtao/safe_yaml)) | Yes, but it is built on Psych and Syck internals. | `module_eval` of a string monkeypatch (`syck_node_monkeypatch.rb:40,42`). | Psych at run time | MIT | rejected | **Ruled out**, and unnecessary: the bundled `safe_load` already does this job. |
| **ya2yaml** 0.31 | Yes. 375 LOC. | none | none | MIT | clean | It only writes YAML and has no parser, so it is **not useful** for reading front matter or config. |
| syck | No (C) | n/a | n/a | n/a | rejected | **Ruled out.** |

I found no maintained pure-Ruby YAML parser on rubygems.org besides
Spinel's own package. The others are either built on Psych or Syck, or
only write YAML.

### Templating

The pattern is consistent. Engines that compile a template into Ruby source
and then `eval` it are ruled out by Spinel's design ("a template is
compiled at runtime, which needs eval",
[L110](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L110)).
Only an engine that interprets a parsed template at run time can work.

| Library (version) | Pure Ruby? | Dynamic features (where) | Deps | Licence | Survey | Verdict |
|---|---|---|---|---|---|---|
| **Liquid** 5.13.0 ([repo](https://github.com/Shopify/liquid)) | Yes. 64 files, about 7k LOC. It is an interpreter: templates are parsed into node objects and rendered, with no `eval` anywhere. | Each `Environment` builds a class at run time and mixes filter modules into it from a method: `Class.new(StrainerTemplate).tap { klass.add_filter(...) }` (`environment.rb:79-80`), where `add_filter` calls `include(filter)` (`strainer_template.rb:17-27`). Spinel refuses changing a class like this from a method ([L93](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L93)). Method reflection: `public_instance_methods` and `private_instance_methods` (`strainer_template.rb:20,27`; `drop.rb:72-79`). The filter name in `invoke` is sent with `send(method, *args)` (`strainer_template.rb:52`). Variable lookup sends a key taken from the template to the object (`object.send(key)`, `variable_lookup.rb:71`). `define_singleton_method` appears at `tag.rb:21`. `liquid_method_missing` is an ordinary method, not Ruby's hook. | strscan ≥ 3.1.1 and bigdecimal. Spinel bundles both. | MIT | rejected (analyze-failed; listed risk: `send`) | **Needs a fork, moderate effort.** Replace the strainer with one static filter class (or a `case` dispatch) built at compile time. Restrict variable lookup to Hash, Array and Drop values with an explicit `[]` protocol instead of `send`. Remove the reflection-based Drop whitelist. Its parse-then-render design is the right shape for Spinel. |
| **Mustache** 1.1.2 ([repo](https://github.com/mustache/mustache)) | Yes. 1.5k LOC. | `render` builds `"def render(ctx) #{compile} end"` and runs it with `instance_eval` (`template.rb:36-41`), which Spinel fundamentally refuses. Computed `define_method` (`parser.rb:69`). Computed `send("scan_tag_#{type}")` and `send("on_#{…}")` (`parser.rb:160`, `generator.rb:95`). `const_get` (`mustache.rb:258-278`). | none | MIT | rejected | **Ruled out as it stands.** The Mustache spec is small, so a fresh interpreter would be cheap to write. Tep's Mustache subset ([SINATRA_COMPAT.md](https://github.com/OriPekelman/tep/blob/4fea8d5aee890635bc1c8359abe08dff78b8b649/SINATRA_COMPAT.md)) compiles templates when the app is built, so it does not fit templates that users supply at run time. |
| **ERB**, CRuby's gem (erb 5.0.2 / 6.0.6, [repo](https://github.com/ruby/erb)) | Mostly. It has an optional C escape extension (`ext/erb/escape`). | `ERB#result` evals the generated source with a `binding`. | none | Ruby / BSD-2-Clause | rejected (c-extension) | **Ruled out.** |
| **ERB**, Spinel's bundled package | Yes | n/a | none | MIT | n/a | **Plausible only for plain `<%= name %>` substitution.** There are no conditionals, loops or expressions, which is not enough for layouts. |
| **Erubi** 1.13.1 ([repo](https://github.com/jeremyevans/erubi)) | Yes. 448 LOC. | Produces Ruby source for the caller to `eval`. Also `eval("''")` at load time (`erubi.rb:17`) and `define_method(:h, ERB::Escape.instance_method(...))` (`erubi.rb:22`). | none | MIT | rejected | **Ruled out.** |
| **Erubis** 2.7.0 | Yes | `eval`, `instance_eval`, `binding`, `ObjectSpace` | none | MIT | risky | **Ruled out.** |
| **Tilt** 2.8.0 ([repo](https://github.com/jeremyevans/tilt)) | Yes, but it is only an adapter layer over other engines. | Compiles each template into a method with `class_eval(method_source)` (`template.rb:432-472`). `eval(class_name)` (`mapping.rb:336`). Computed `autoload` (`mapping.rb:179`). `define_method` with a block taken from an argument (`template.rb:575`). | engines | MIT | rejected | **Ruled out.** It is also pointless here, because every engine it wraps is eval-based. |
| Mote 1.3.1, Tenjin 0.7.1, Slim 5.2.2, Haml 7.2.0, Temple 0.10.4, Cadenza, Liquor, curly-templates, handlebars / ruby-handlebars | Yes | Mote runs `instance_eval` on generated source (`mote.rb:53`). The others use `eval`, `class_eval` or `binding` (survey risk lists). | various | various | risky or rejected | **Ruled out.** |

## Uncertainties and gaps

- **I compiled nothing.** Building Spinel locally was not permitted in
  this session. The verdicts rest on Spinel's documented rules plus the
  SpinelGems compile-and-scan run (which does not execute any code). No
  library here is behaviour-`verified`. Ticket 04 (toolchain spike) should
  compile motion-markdown-it, kramdown and kramdown-parser-gfm, a
  Liquid fork, and the bundled `psych`, and diff their output against CRuby.
- **Liquid's "analyze-failed".** The survey reports only that analysis
  failed, not which construct caused it. I believe the cause is the
  run-time strainer class plus `include` (Spinel's docs refuse that
  pattern), but this is my inference, not something I confirmed. More
  blockers may appear once that is fixed.
- **motion-markdown-it's lambda tables.** Its rule lambdas name their
  second parameter differently (`startLine` vs `silent`) but have the same
  arity. Spinel's "typed array holds one kind of element" rule
  ([L1048](https://github.com/matz/spinel/blob/afe2a920fd66fb9e16df7b3356f9cf29b4546418/docs/limitations.md#L1048))
  should accept them as Procs, but I have not confirmed this. Its two
  computed `send`s sit on a configuration path.
- **kramdown under `--defer-refusals`.** I did not confirm whether
  kramdown's `singleton_class.send(:define_method, …)` is refused, deferred
  or silently ignored by the current compiler. Spinel's docs say
  `send(:define_method, name)` "is not refused", so the likely failure is a
  `NoMethodError` when `Converter.syntax_highlighter(...)` is called.
- **The survey's commonmarker verdict.** `clean` for a Rust-extension gem
  looks like a false positive in the survey's static C-extension check,
  which apparently only looks for C sources. Do not treat it as evidence.
- **spinel-commonmarker.** I read only its README, not its source. The
  repo description says "over the system cmark-gfm" while the README says
  the library is vendored; I took the README as authoritative.
- **Spinel moves fast.** The project says revisions land daily. The
  limitations doc is pinned here to `afe2a920`, and its "Now supported"
  section shows the rules loosen over time. Re-check before committing to
  a fork.

## Sources

- Spinel: https://github.com/matz/spinel (commit `afe2a920fd66fb9e16df7b3356f9cf29b4546418`). Files used: `README.md`, `docs/limitations.md`, `docs/require.md`, `docs/spin.md`, `docs/FFI.md`, `packages/psych/psych.rb`, `packages/erb/erb.rb`, `packages/rexml/rexml.rb`, `test/class_method_define_method_macro.rb`, `test/typed_hash_caller_no_body_widen.rb`
- spin-index: https://github.com/matz/spin-index
- SpinelGems survey: https://github.com/OriPekelman/spinelgems (commit `d981e359d086fc3d4367a053e1318a039f0dc4d4`). Files used: `survey-2814693f/compat.jsonl`, `docs/cli.md`
- awesome-spinel: https://github.com/aristotelesbr/awesome-spinel
- spinel-commonmarker: https://github.com/roundhouse-rb/spinel-commonmarker
- Tep: https://github.com/OriPekelman/tep (commit `4fea8d5aee890635bc1c8359abe08dff78b8b649`), `SINATRA_COMPAT.md`
- Gem sources, unpacked from rubygems.org:
  [kramdown 2.5.2](https://rubygems.org/gems/kramdown/versions/2.5.2),
  [kramdown-parser-gfm 1.1.0](https://rubygems.org/gems/kramdown-parser-gfm/versions/1.1.0),
  [motion-markdown-it 13.0.1](https://rubygems.org/gems/motion-markdown-it/versions/13.0.1),
  [redcarpet 3.6.1](https://rubygems.org/gems/redcarpet/versions/3.6.1),
  [commonmarker 2.9.0](https://rubygems.org/gems/commonmarker/versions/2.9.0),
  [rdiscount 2.2.7.5](https://rubygems.org/gems/rdiscount/versions/2.2.7.5),
  [maruku 0.7.3](https://rubygems.org/gems/maruku/versions/0.7.3),
  [psych 5.4.0](https://rubygems.org/gems/psych/versions/5.4.0),
  [safe_yaml 1.0.5](https://rubygems.org/gems/safe_yaml/versions/1.0.5),
  [ya2yaml 0.31](https://rubygems.org/gems/ya2yaml/versions/0.31),
  [liquid 5.13.0](https://rubygems.org/gems/liquid/versions/5.13.0),
  [mustache 1.1.2](https://rubygems.org/gems/mustache/versions/1.1.2),
  [tilt 2.8.0](https://rubygems.org/gems/tilt/versions/2.8.0),
  [erubi 1.13.1](https://rubygems.org/gems/erubi/versions/1.13.1),
  [erubis 2.7.0](https://rubygems.org/gems/erubis/versions/2.7.0),
  [erb 5.0.2](https://rubygems.org/gems/erb/versions/5.0.2),
  [mote 1.3.1](https://rubygems.org/gems/mote/versions/1.3.1)
