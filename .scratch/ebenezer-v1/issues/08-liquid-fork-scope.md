# Liquid fork scope

Type: grilling
Status: open
Blocked by: 03, 04

## Question

Ebenezer forks Shopify/liquid to compile under Spinel. Decide what the fork is:
- Which upstream version it is based on.
- Whether it keeps full Liquid semantics or a defined subset of tags and filters.
- How the Spinel blockers get replaced, for example static filter tables in place of the run-time filter class, and explicit variable lookup in place of `send`.
- How it tracks upstream.
- Which Jekyll-flavoured tags and filters Ebenezer adds on top (`include`, `relative_url`, `date_to_xmlschema`, …).

(Packaging is already decided: the fork is a built-in inside Ebenezer's tree. See [Built-in components](11-built-in-components.md).)
