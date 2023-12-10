extern fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?[*]anyopaque;
extern fn roc_realloc(ptr: [*]anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?[*]anyopaque;
extern fn roc_dealloc(ptr: [*]anyopaque, alignment: u32) callconv(.C) void;
extern fn roc_panic(c_ptr: [*]anyopaque, tag_id: u32) callconv(.C) void;
extern fn roc_dbg(loc: [*]anyopaque, msg: [*]anyopaque, src: [*]anyopaque) callconv(.C) void;
extern fn roc_memset(dst: [*]anyopaque, c: i32, n: usize) callconv(.C) ?[*]anyopaque;

pub const alloc = roc_alloc;
pub const realloc = roc_realloc;
pub const dealloc = roc_dealloc;
pub const panic = roc_panic;
pub const dbg = roc_dbg;
pub const memset = roc_memset;

pub const Result = @import("result.zig").Result;
pub const Storage = @import("storage.zig").Storage;
