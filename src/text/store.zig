//! The swappable text-storage interface. `GapBuffer` implements this today; a
//! chunked rope can implement the same vtable later as a literal drop-in. The
//! per-call indirection is negligible next to terminal I/O.
pub const TextStore = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        len: *const fn (ptr: *anyopaque) usize,
        byteAt: *const fn (ptr: *anyopaque, off: usize) u8,
        insert: *const fn (ptr: *anyopaque, off: usize, bytes: []const u8) anyerror!void,
        delete: *const fn (ptr: *anyopaque, start: usize, end: usize) void,
    };

    pub fn len(self: TextStore) usize {
        return self.vtable.len(self.ptr);
    }
    pub fn byteAt(self: TextStore, off: usize) u8 {
        return self.vtable.byteAt(self.ptr, off);
    }
    pub fn insert(self: TextStore, off: usize, bytes: []const u8) anyerror!void {
        return self.vtable.insert(self.ptr, off, bytes);
    }
    pub fn delete(self: TextStore, start: usize, end: usize) void {
        self.vtable.delete(self.ptr, start, end);
    }
};
