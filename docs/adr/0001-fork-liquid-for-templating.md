# Fork Shopify's Liquid for templating

Layouts and includes are written in Liquid, using our own fork of Shopify/liquid that compiles under Spinel. Spinel refuses `eval`, so ERB, Erubi, Tilt, Haml, Slim and Mustache are all unusable. Stock Liquid fails too: it builds a filter class at run time and looks up variables with `send`. We chose to fork Liquid over writing our own template interpreter, because Liquid gives authors familiar, Jekyll-style templates. The cost is that we own a fork and have to keep it in step with upstream.

## Considered Options

- **A small in-house template interpreter.** Less to port, but site authors get no familiar syntax.
- **Spinel's bundled ERB.** It supports only `<%= name %>` from a Hash, with no logic in tags.
