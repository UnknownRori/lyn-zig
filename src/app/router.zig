const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");

const hl = @import("./handler.zig");
const Handler = hl.Handler;
const rt = @import("./route.zig");
const Route = rt.Route;
const MiddlewareProvider = root.MiddlewareProvider;

pub const RouteConfig = struct {
    middleware: std.ArrayList([]const u8),
};

pub const Router = struct {
    _routes: std.ArrayList(Route),
    _not_found: ?Handler,
    _allocator: mem.Allocator,
    const Self = @This();

    pub fn init(allocator: mem.Allocator) Self {
        return Self{
            ._not_found = null,
            ._routes = std.ArrayList(Route).init(allocator),
            ._allocator = allocator,
        };
    }

    pub fn set_404(self: *Self, instance: *anyopaque, handler: anytype) !void {
        const handlerObj = try Handler.init(root.HTTPMethod.GET, "/_404", instance, handler);
        self._not_found = handlerObj;
    }

    pub fn add(self: *Self, method: root.HTTPMethod, path: []const u8, instance: *anyopaque, handler: anytype, routeConfig: ?RouteConfig) !void {
        const handlerObj = try Handler.init(instance, handler);
        var routeObj = try Route.init(self._allocator, method, path, handlerObj);
        if (routeConfig != null) {
            for (routeConfig.?.middleware.items) |middlewareName| {
                try routeObj.middleware(middlewareName);
            }
        }

        try self._routes.append(routeObj);
    }

    pub fn get(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype, config: ?RouteConfig) !void {
        try self.add(root.HTTPMethod.GET, path, instance, handler, config);
    }

    pub fn post(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype, config: ?RouteConfig) !void {
        try self.add(root.HTTPMethod.POST, path, instance, handler, config);
    }

    pub fn patch(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype, config: ?RouteConfig) !void {
        try self.add(root.HTTPMethod.PATCH, path, instance, handler, config);
    }

    pub fn delete(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype, config: ?RouteConfig) !void {
        try self.add(root.HTTPMethod.DELETE, path, instance, handler, config);
    }

    pub fn resolve(self: *Self, middlewareProvider: MiddlewareProvider, req: *root.Request, res: *root.Response) !void {
        for (self._routes.items) |route| {
            if (route.isMatch(req)) {
                for (route._middleware.items) |middleware| {
                    const middlewareHandler = middlewareProvider.get(middleware);
                    if (middlewareHandler != null) {
                        try middlewareHandler.?.call(req, res);
                    }
                }

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

    pub fn deinit(self: *Self) void {
        for (self._routes.items) |route| {
            route.deinit();
        }
        self._routes.deinit();
    }
};
