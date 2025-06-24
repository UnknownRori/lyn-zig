const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");

const hl = @import("./handler.zig");
const Handler = hl.Handler;

pub const MiddlewareProvider = struct {
    _middleware: std.StringHashMap(Handler),
    _allocator: mem.Allocator,

    const Self = @This();

    pub fn init(allocator: mem.Allocator) Self {
        const middleware = std.StringHashMap(Handler).init(allocator);
        return Self{
            ._middleware = middleware,
            ._allocator = allocator,
        };
    }
};
