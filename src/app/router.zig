const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");

const hl = @import("./handler.zig");
const Handler = hl.Handler;

pub const Router = struct {
    _routes: std.ArrayList(Handler),
    _not_found: ?Handler,
    _allocator: mem.Allocator,
    const Self = @This();

    pub fn init(allocator: mem.Allocator) Self {
        return Self{
            ._not_found = null,
            ._routes = std.ArrayList(Handler).init(allocator),
            ._allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self._routes.deinit();
    }

    pub fn set_404(self: *Self, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(root.HTTPMethod.GET, "", instance, handler);
        self._not_found = handlerObj;
    }

    pub fn get(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(root.HTTPMethod.GET, path, instance, handler);
        try self._routes.append(handlerObj);
    }

    pub fn post(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(root.HTTPMethod.POST, path, instance, handler);
        try self._routes.append(handlerObj);
    }

    pub fn patch(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(root.HTTPMethod.PATCH, path, instance, handler);
        try self._routes.append(handlerObj);
    }

    pub fn delete(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(root.HTTPMethod.DELETE, path, instance, handler);
        try self._routes.append(handlerObj);
    }

    pub fn resolve(self: *Self, req: *root.Request, res: *root.Response) !void {
        for (self._routes.items) |route| {
            if (route.isMatch(req)) {
                return try route.call(req, res);
            }
        }

        if (self._not_found != null) {
            return try self._not_found.?.call(req, res);
        }

        _ = try res.json(root.HTTPStatus.NotFound, .{
            .type = "error",
            .message = "Not found",
        });
    }
};
