# Templating language

Type: grilling
Status: resolved
Blocked by: 01, 02, 03

## Question

What templating language do layouts and includes use: a Liquid subset, ERB-style, Mustache-style, or something custom? Given Spinel's limits (no eval?), how are templates compiled or interpreted at build time?

## Answer

Decided by the user: **fork Shopify's Liquid (https://github.com/Shopify/liquid) so it compiles under Spinel.** Layouts and includes are written in Liquid. Writing an in-house interpreter was rejected. The libraries research found that Liquid needs a moderate fork: it builds a filter class at run time, `include`s modules into it from inside a method, inspects its own methods, and looks up variables with `send`. How far the fork goes is now its own ticket, [Liquid fork scope](08-liquid-fork-scope.md).
