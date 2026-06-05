//! Entry point: parse args, create the editor, run the main loop, clean up.
const std = @import("std");
const ziv = @import("ziv");

pub fn main(init: std.process.Init) !void {
    // The arena lives as long as the process — fine for editor-lifetime data.
    // (Per-frame scratch and growable buffers get their own allocators later.)
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const path: ?[]const u8 = if (args.len > 1) args[1] else null;

    var editor = try ziv.Editor.init(arena, path);
    defer editor.deinit();

    try editor.run();
}
