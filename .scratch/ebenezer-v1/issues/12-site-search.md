# Site search

Type: grilling
Status: resolved
Blocked by:

## Question

Does Ebenezer provide site search, and how?

## Answer

Decided by the user: **fork Pagefind (https://github.com/pagefind/pagefind) and port it to Spinel-compatible Ruby, shipped as a built-in.** See [ADR 0003](../../../docs/adr/0003-fork-pagefind-into-spinel-ruby.md). What the port covers is [Pagefind port scope](14-pagefind-port-scope.md), which waits on [Pagefind architecture](13-pagefind-architecture.md).
