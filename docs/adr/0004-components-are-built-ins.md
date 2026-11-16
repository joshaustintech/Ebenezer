# Liquid, CommonMark and Pagefind ship as built-ins, not separate components

The Liquid fork, the CommonMark engine and the Pagefind port all ship inside the Ebenezer binary and source tree as built-ins. They are not separate gems, spin packages or repos that users assemble themselves. Spinel resolves `require` when it compiles and has no RubyGems at run time, so separate packages buy users nothing, and one binary is the product. The trade-off is that the forks can't easily be reused outside Ebenezer, and their upstream changes have to be merged into Ebenezer's own tree.
