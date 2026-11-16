# v1 content model

Type: grilling
Status: resolved
Blocked by:

## Question

Which content concepts are in v1 and what does each mean precisely: pages, posts, collections, data files, static files, drafts, permalinks, pagination, taxonomies (tags/categories), layouts, includes, front matter? Settle the terms in GLOSSARY.md.

## Answer

Terms are defined in [GLOSSARY.md](../../../GLOSSARY.md).

1. **Collections** are the core unit. `posts` is a built-in Dated Collection. Standalone files with front matter are **Pages**.
2. **Dated** is a setting any Collection can turn on. It takes the date from the filename, sorts newest first and gives newer/older neighbours. It is on by default only for `posts`.
3. **Collections route by default.** `routed: false` makes an **Unrouted Collection**. `headless: true` is an accepted alias, and the two conflicting is a config error.
4. **Data Files** live in `_data/` as YAML, JSON or CSV. Subfolders become nested keys (`site.data.team.core`).
5. **Front matter decides how a file is handled**, as in Jekyll. With front matter it is a Page; without, a **Static File** copied unchanged. Names starting with `_` or `.` are never output, and `exclude:`/`include:` override.
6. **Drafts:**
   - `_drafts/` mirrors the site's layout and can hold anything. For example, `_drafts/_docs/x.md` is a doc and `_drafts/_data/nav.yml` is a Data File. Publishing a draft means moving it out of `_drafts/`.
   - `draft: true` in front matter also makes a file a Draft, and `draft: false` doesn't override the folder.
   - Drafts are left out unless `--drafts` is passed. `ebenezer new` sets `draft: true`.
7. **Future-dated Documents** are left out of `build` unless `--future` is passed. `serve` includes them by default.
8. **Order in collections that aren't dated:**
   - Documents named in the collection's `order:` list come first, in list order.
   - The rest follow by `sort_by: <key>` if set (Documents missing the key go last), otherwise by filename.
9. **URLs** come from patterns only and are always pretty: `/x/` is written as `x/index.html`.
   - Defaults: Posts `/:year/:month/:day/:slug/`, other collections `/:collection/:path/`, Pages `/:path/`.
   - Precedence: front matter `permalink:` beats the collection's `permalink:` pattern, which beats the default.
   - Placeholders: `:collection :path :slug :title :year :month :day`.
10. **Taxonomies** are declared in the site config (`taxonomies: [tags, categories]`). Each **Term** gets a **Generated Page** at `/:taxonomy/:term/` using the `taxonomy` layout, and templates read them as `site.taxonomies.<name>`.
11. **Pagination:** a Page paginates any collection with `paginate: {collection, per_page}`. Later pages are at `<page url>/page/N/`. Term pages paginate automatically with a site-wide `per_page`. Templates get `paginator` with `items`, `page`, `total_pages`, `previous_url` and `next_url`.
12. **Layouts and Includes:**
    - **Layouts** (`_layouts/`) chain via `layout:`. With no `layout:`, a Document uses the layout named after its collection if it exists, otherwise `default`, and a Page uses `default`. `layout: none` renders with no layout.
    - **Includes** (`_includes/`) take arguments.
    - A missing Layout or Include is a build error.
13. **`defaults:`** in the config lists scopes (`path` glob and/or `collection`) with values. The most specific scope wins, and a file's own front matter always wins.
14. **Excerpts:** every Document and Page has one, taken from front matter `excerpt:`, else the content before `<!--more-->` (the marker is configurable), else the first paragraph. It is rendered to HTML.
15. **Feeds and Sitemap** are built-in Generated Pages.
    - Every Dated Collection gets Atom (`/:collection/feed.xml`) and RSS 2.0 (`/:collection/rss.xml`). The posts feeds are at `/feed.xml` and `/rss.xml`.
    - `feed:` takes `both` (default), `atom`, `rss` or `false`.
    - `/sitemap.xml` lists routed, non-Draft output. A file opts out with `sitemap: false`.
16. **One language per site** (`lang:` in the config), used by the HTML `lang` attribute and by search stemming. Multilingual content is out of scope.
17. **Render order:** Liquid, then CommonMark (only for `.md` and `.markdown`), then the Layout chain. `liquid: false` in front matter skips Liquid.
