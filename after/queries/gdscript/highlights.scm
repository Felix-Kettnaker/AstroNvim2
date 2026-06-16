;extends

; tree-sitter-gdscript wraps `#region <label> ... #endregion` in a
; single (region) node. The `_region_start` / `_region_end` marker
; tokens are external hidden tokens, so the `#region` / `#endregion`
; lines themselves expose no inner nodes besides (region_label) to
; capture, and orphan comments immediately above `#endregion` are
; consumed by the external scanner — they don't surface as (comment).
; Without a fallback, all those spans fall back to Normal (white).
;
; Paint the whole (region) node as a comment-styled fallback at a LOW
; priority so the default highlights (priority 100) still win for real
; code, strings and keywords inside the region. Only the otherwise-
; uncaptured cells — the `#region` keyword, the orphan comment,
; `#endregion`, and the region label — actually render with this color.
;
; NOTE: We use the @comment.region subtype rather than plain @comment.
; The subtype still chains to the Comment highlight group (so it looks
; like a comment), but other plugins that key off the EXACT capture
; name "comment" — notably todo-comments.nvim's `is_comment` check —
; will correctly treat inner code as non-comment, preventing TODO
; multi-line highlighting from leaking through the whole region.
((region) @comment.region (#set! priority 90))
