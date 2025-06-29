const std = @import("std");
const lib = @import("lyn_zig_lib");

const HelloWorldController = struct {
    message: []const u8,
    const Self = @This();

    pub fn init(message: []const u8) Self {
        return Self{
            .message = message,
        };
    }

    pub fn hello(self: *Self, req: *lib.Request, res: *lib.Response) !void {
        _ = try res.json(lib.HTTPStatus.Ok, .{
            .message = self.message,
            .userAgent = req.userAgent,
        });
    }
};

const UserAgentMiddleware = struct {
    const Self = @This();

    pub fn init() Self {
        return Self{};
    }

    pub fn hello(_: *Self, req: *lib.Request, _: *lib.Response) !void {
        req.userAgent = "Nyan";
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var middlewareProvider = lib.MiddlewareProvider.init(allocator);
    var userAgentMiddleware = UserAgentMiddleware.init();
    try middlewareProvider.register("user-agent", &userAgentMiddleware, UserAgentMiddleware.hello);

    var helloWorldController = HelloWorldController.init("Hello World!");
    var pingPongController = HelloWorldController.init("Ping Pong");

    var router = lib.Router.init(allocator);
    var middleware = std.ArrayList([]const u8).init(allocator);
    try middleware.append("user-agent");

    try router.get("/", &helloWorldController, HelloWorldController.hello, .{ .middleware = middleware });
    try router.get("/ping", &pingPongController, HelloWorldController.hello, null);

    var server = try lib.App.init(allocator, lib.AppConfig{
        .port = 8000,
        .host = "127.0.0.1",
        .router = router,
        .middleware = middlewareProvider,
    });
    try server.listen();

    const leaks = gpa.detectLeaks();
    std.debug.print("has leaks : {}", .{leaks});
}
