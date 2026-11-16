# YAML strategy

Type: grilling
Status: open
Blocked by: 01, 02, 04

## Question

For YAML (front matter, _config.yml, data files): use Spinel's bundled psych as is, vendor a patched copy, or write an in-house parser? Which YAML subset is supported, and how are dates handled, given that bundled psych raises on unquoted dates?

(The Markdown half of this ticket was decided separately: see [Markdown engine](09-markdown-engine.md).)
