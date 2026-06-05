//! Text objects resolve to a `Range`: `iw`/`aw` (word), `i"`/`a"` (quotes),
//! `ip`/`ap` (paragraph), `i(`/`a(` (brackets), etc. The leading `i`/`a` selects
//! inner vs. "a" (around / including delimiters or trailing whitespace).
const Range = @import("operator.zig").Range;

pub const Scope = enum { inner, around }; // i / a

// TODO Phase 4: pub fn resolve(scope, kind, cursor, text) Range
