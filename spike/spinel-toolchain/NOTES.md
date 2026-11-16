# Spinel toolchain spike (throwaway)

This is throwaway code for the "Spinel toolchain spike" ticket. It will never be merged.

- **Machine:** macOS 27.2 on arm64, Apple clang 21. CRuby 4.0.9 was used as the comparison.
- **Spinel:** tag `2026.10.25` (2814693f6), built from source with `make deps && make -j8`. That took 66s wall-clock, and `make deps` fetched prism 1.9.0 and rbs 4.0.1 from rubygems.org.

## Reproduce

```bash
git clone https://github.com/matz/spinel && cd spinel && git checkout 2026.10.25
make deps && make -j8
./spinel ../toy.rb -o toy && ./toy site out
./spinel -I probes/patched probes/dates4.rb -o dates4 && ./dates4
gem fetch liquid -v 5.14.0 && gem unpack liquid-5.14.0.gem
./spinel -I liquid-5.14.0/lib liquid/liquid_probe.rb -o lp   # 33 refusals
```

## Files

- `toy.rb`: reads `site/`, splits front matter, parses it with bundled psych, writes HTML, and copies Static Files. Output is byte-identical to CRuby's.
- `probes/`:
  - `dates*.rb`: YAML date handling.
  - `erb_probe.rb`: ERB.
  - `csv_probe.rb`: CSV.
  - `server.rb`: a threaded TCP HTTP server.
  - `patched/psych.rb`: bundled psych with a two-line patch that keeps dates and times as strings.
- `liquid/compile.log`: Spinel's 33 refusals when compiling unmodified Liquid 5.14.0.
