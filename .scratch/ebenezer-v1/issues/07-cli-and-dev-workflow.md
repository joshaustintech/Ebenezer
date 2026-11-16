# CLI and dev workflow

Type: grilling
Status: open
Blocked by: 01, 03

## Question

Which commands does v1 ship (build, serve, watch, new, clean…), with what flags, and can Spinel support what serve/watch need (sockets, file-system events or polling)?

From the content model: `ebenezer new` creates the new Markdown file with `draft: true` set by default.
From the content model: `build` leaves out future-dated documents unless `--future` is passed; `serve` includes them by default.
