const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");
const hl = @import("./handler.zig");
const Handler = hl.Handler;

const BoundHandler = *fn (*const anyopaque, *root.Request, *root.Response) anyerror!void;

pub const Route = struct {
    /// Function pointer of the instance
    method: root.HTTPMethod,
    path: []const u8,
    handler: Handler,
    _middleware: std.ArrayList([]const u8),

    const Self = @This();

    pub fn init(allocator: mem.Allocator, method: root.HTTPMethod, path: []const u8, handler: Handler) !Route {
        return Self{
            .path = path,
            .handler = handler,
            .method = method,
            ._middleware = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn isMatch(self: Self, req: *root.Request) bool {
        if (self.method != req.method) return false;

        var handlerUrl = std.mem.splitSequence(u8, self.path, "/");
        var requestUrl = std.mem.splitSequence(u8, req.path, "/");

        while (requestUrl.next()) |reqUrl| {
            const handUrl = handlerUrl.next();
            if (handUrl == null) return false;

            if (std.mem.eql(u8, handUrl.?, reqUrl)) {
                //
            } else if (std.mem.startsWith(u8, handUrl.?, "{") and std.mem.endsWith(u8, handUrl.?, "}")) {
                // Parse the params
            } else {
                return false;
            }
        }
        return true;
    }

    pub fn middleware(self: *Self, name: []const u8) !void {
        try self._middleware.append(name);
    }

    pub fn call(self: Self, req: *root.Request, res: *root.Response) !void {
        try @call(.auto, @as(BoundHandler, @ptrFromInt(self.handler.handler)), .{
            @as(*anyopaque, @ptrFromInt(self.handler.instance)),
            req,
            res,
        });
    }

    pub fn deinit(self: *Self) void {
        self._middleware.deinit();
    }
};
