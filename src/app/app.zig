const std = @import("std");
const mem = std.mem;

const serverLib = @import("../http/server.zig");

const root = @import("../root.zig");

pub const AppConfig = struct {
    host: []const u8,
    port: u16,
    router: root.Router,
    middleware: root.MiddlewareProvider,
};

pub const App = struct {
    _server: root.Server,
    _router: root.Router,
    _allocator: mem.Allocator,
    _middlewareProvider: root.MiddlewareProvider,

    const Self = @This();

    pub fn init(allocator: mem.Allocator, config: AppConfig) !Self {
        var app = Self{
            ._router = config.router,
            ._middlewareProvider = config.middleware,
            ._allocator = allocator,
            ._server = undefined,
        };

        app._server = try root.Server.init(allocator, root.ServerConfig{
            .host = config.host,
            .port = config.port,
            .ctx = undefined,
            .onRequest = App.handler,
        });

        return app;
    }

    pub fn listen(self: *Self) !void {
        self._server._ctx = self;

        try self._server.listen();
    }

    // ------- INTERNAL FUNCTION -------
    fn handler(ctx: *anyopaque, req: *root.Request, res: *root.Response) anyerror!void {
        const self: *Self = @alignCast(@ptrCast(ctx));

        try self._router.resolve(req, res);
    }
};
