# Fork Pagefind into Spinel Ruby for site search

Ebenezer gives every site static search by forking Pagefind (https://github.com/pagefind/pagefind) and porting it to Spinel-compatible Ruby, instead of asking users to install the Rust Pagefind binary separately. Ebenezer should be a single self-contained binary, and search is something most sites want. The browser-side runtime can't be Ruby; it is forked into Elm (ADR 0005).
