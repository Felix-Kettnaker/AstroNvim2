; attribute text object — outer only (aa).
; xml grammar's AttValue node includes the surrounding quotes and has no
; child node for the bare value, so there's no clean @attribute.inner.
; Use targets.vim `ciq` / `ci"` for the inside-quotes case.
(Attribute) @attribute.outer
