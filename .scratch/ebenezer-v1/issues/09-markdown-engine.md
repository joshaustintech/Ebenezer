# Markdown engine

Type: grilling
Status: resolved
Blocked by:

## Question

Which Markdown engine does Ebenezer use: an existing library (motion-markdown-it, a forked kramdown, spinel-commonmarker) or one written in-house?

## Answer

Decided by the user: **build our own Markdown engine, 1:1 compliant with the CommonMark specification (https://commonmark.org).** It is written in Spinel-compatible Ruby. The existing libraries surveyed in [Spinel-compatible Markdown, YAML and templating libraries](02-spinel-compatible-libraries.md) were rejected. See [ADR 0002](../../../docs/adr/0002-in-house-commonmark-engine.md). What exactly conformance covers is now its own ticket, [CommonMark conformance scope](10-commonmark-conformance-scope.md).
