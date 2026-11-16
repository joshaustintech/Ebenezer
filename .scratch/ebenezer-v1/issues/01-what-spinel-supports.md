# What does Spinel support?

Type: research
Status: resolved
Blocked by:

## Question

What exactly can Spinel compile? Cover: the Ruby language subset (eval, define_method, method_missing, send, blocks/procs, Regexp, string encodings, exceptions), which stdlib ships (File, Dir, YAML/Psych, ERB, Socket, Time), whether gems and C extensions are supported and how, the toolchain and build commands, platforms targeted, and project maturity/licence. Use primary sources (the Spinel repo, docs, author statements).

## Answer

Findings: branch `research/what-spinel-supports`, file `.scratch/ebenezer-v1/research/what-spinel-supports.md` (sources: matz/spinel @ afe2a92, MIT).

- Spinel compiles Ruby to C and links only libc and libm. There is no RubyGems and no run-time `require`. Libraries are source trees compiled into the binary (`-I`, `spin.toml`) and must fit the subset.
- Refused: `eval` and string `instance_eval`/`class_eval`, and `define_method` with a computed name. `method_missing` is never dispatched. A computed `send` becomes a fixed dispatch. Blocks, procs, closures and exceptions work, but release builds have no backtraces.
- Regexp: a built-in engine with lookaround, named groups and Unicode, at most 31 capture groups. Strings are UTF-8 or binary only.
- File, Dir and FileUtils cover what a generator needs. TCP sockets and real threads work, but there is no WEBrick or Rack.
- YAML: a Ruby port of Psych. **An unquoted date such as `2024-01-01` raises**, which affects front matter directly.
- ERB: effectively unusable (it needs eval). **Ebenezer needs its own interpreted template language.**
- No Markdown library is bundled. Options: write one in the subset, or wrap cmark via FFI or a C package.
- Platforms: Linux and macOS in CI, plus wasm32-wasi. Two releases so far (2026.09, 2026.10); the project is fast-moving.
- Verify in the toolchain spike: YAML dates, ERB, a socket server, `Dir.glob`, compile time.
