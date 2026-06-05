//! One terminal cell: a codepoint plus its style. The screen is a flat array of
//! these; the renderer diffs cell-by-cell against the previous frame.
pub const Cell = struct {
    cp: u21 = ' ',
    style: Style = .{},
};

pub const Style = struct {
    fg: Color = .default,
    bg: Color = .default,
    bold: bool = false,
    underline: bool = false,
    reverse: bool = false,
};

pub const Color = union(enum) {
    default,
    indexed: u8, // 256-color palette
    rgb: struct { r: u8, g: u8, b: u8 }, // truecolor
};
