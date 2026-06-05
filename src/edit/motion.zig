//! Motions: given the cursor and a count, compute a target offset. When invoked
//! under an operator they also yield a `Range` (with charwise/linewise and
//! inclusive/exclusive semantics that match vim).
const Range = @import("operator.zig").Range;

/// The motions ziv will support, grouped roughly by phase.
pub const Kind = enum {
    // Phase 2: basics
    left, // h
    right, // l
    up, // k
    down, // j
    word_fwd, // w
    word_back, // b
    word_end, // e
    line_start, // 0
    line_end, // $
    first_line, // gg
    last_line, // G
    find_char_fwd, // f{char}
    till_char_fwd, // t{char}
    // TODO: W B E, %, paragraph/sentence, search n/N, etc.
};

// TODO Phase 2: pub fn resolve(kind, cursor, count, text) Range
