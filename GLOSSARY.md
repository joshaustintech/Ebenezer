# Ebenezer

A static site generator, inspired by Jekyll and compiled by Spinel into a single binary.

## Language

**Built-in**:
A capability that ships inside the Ebenezer binary and is always available, such as Liquid templating, CommonMark rendering and site search.
_Avoid_: plugin, extension, component, add-on

### Content

**Collection**:
A named set of Documents kept in one folder (such as `_posts/` or `_docs/`) that share settings. Collections are the core unit of content.
_Avoid_: section, content type

**Unrouted Collection**:
A Collection whose Documents get no URL of their own but can still be listed from templates, such as `_authors/`. (The config also accepts `headless` as a synonym.)
_Avoid_: unpublished collection, hidden collection, data collection

**Document**:
One content file that belongs to a Collection.
_Avoid_: entry, item, record

**Excerpt**:
A short rendered summary of a Document or Page. It comes from front matter, from the content before the excerpt marker, or from the first paragraph.
_Avoid_: summary, teaser, description

**Dated Collection**:
A Collection whose Documents take their date from the filename and are ordered newest first, with newer and older neighbours. `posts` is dated by default.
_Avoid_: blog collection, chronological collection

**Post**:
A Document in the built-in `posts` Collection.
_Avoid_: article, blog entry

**Page**:
A standalone file outside any Collection that starts with front matter, such as `about.md` or `index.html`.
_Avoid_: static page, document (for these files)

**Static File**:
A file outside Collections and `_data/` that has no front matter, such as an image, stylesheet or `robots.txt`. It is copied to the output unchanged.
_Avoid_: asset, raw file

**Data File**:
A structured YAML, JSON or CSV file in `_data/` that templates read as site data. It is not content and gets no URL.
_Avoid_: config file, fixture

**Draft**:
Content left out of a build unless drafts are requested. It is either placed under `_drafts/` or marked `draft: true` in its front matter.
_Avoid_: unpublished, hidden

### Grouping and generated output

**Taxonomy**:
A named way of grouping content, declared in the site config (such as `tags` or `categories`). Documents and Pages list their Terms in front matter.
_Avoid_: classification, label set

**Term**:
One value within a Taxonomy, such as `ruby` within `tags`. Each Term gets its own listing page.
_Avoid_: tag (when meaning the general concept), keyword

**Generated Page**:
An output page that no source file corresponds to, created by Ebenezer itself, such as a Term's listing page.
_Avoid_: virtual page, synthetic page
**Feed**:
A Generated Page that syndicates a Dated Collection, in Atom or RSS format.
_Avoid_: channel, stream

**Sitemap**:
The Generated Page `/sitemap.xml`, which lists every routed Document and Page that isn't a Draft.
_Avoid_: site index

### Templates

**Layout**:
A template in `_layouts/` that wraps rendered content. A Layout may itself be wrapped by another Layout.
_Avoid_: theme, wrapper, master page

**Include**:
A reusable template fragment in `_includes/` that is inserted into other templates, optionally with arguments.
_Avoid_: partial, snippet, component
