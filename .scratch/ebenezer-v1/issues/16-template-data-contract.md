# Template data contract

Type: grilling
Status: open
Blocked by:

## Question

What exactly do templates see? Settle:
- The objects and their fields: `site` (with `data`, `taxonomies`, the collections, `pages`, `static_files`, `time`, config values), `page` (or Document) fields, `paginator`, `content` and `layout`.
- How collections are exposed.
- Which Jekyll-style filters and tags beyond core Liquid are guaranteed in v1: `relative_url`, `absolute_url`, `date_to_xmlschema`, `where`, `sort`, `group_by`, `markdownify`, `slugify`, `jsonify`, `xml_escape`, …

This is the contract that [Liquid fork scope](08-liquid-fork-scope.md) has to implement.
