# Fork Pagefind into Spinel Ruby for site search

Ebenezer gives every site static search by forking Pagefind (https://github.com/pagefind/pagefind) and porting it to Spinel-compatible Ruby, instead of asking users to install the Rust Pagefind binary separately. Ebenezer should be a single self-contained binary, and search is something most sites want. Pagefind's browser-side runtime (JavaScript/WASM) can't itself be Ruby. Which parts are ported, and which parts are carried over as static assets, is an open question on the Ebenezer v1 map.
