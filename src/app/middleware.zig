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

    pub fn register(self: *Self, name: []const u8, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(instance, handler);
        try self._middleware.put(name, handlerObj);
    }

    pub fn get(self: Self, name: []const u8) ?Handler {
        return self._middleware.get(name);
    }
};
