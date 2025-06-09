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

    pub fn hello(self: *Self, _: *lib.Request, res: *lib.Response) !void {
        _ = try res.json(lib.HTTPStatus.Ok, .{
            .message = self.message,
        });
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var helloWorldController = HelloWorldController.init("Hello World!");
    var pingPongController = HelloWorldController.init("Ping Pong");

    var router = lib.Router.init(allocator);
    try router.get("/", &helloWorldController, HelloWorldController.hello);
    try router.get("/ping", &pingPongController, HelloWorldController.hello);

    var server = try lib.App.init(allocator, lib.AppConfig{
        .port = 8000,
        .host = "127.0.0.1",
        .router = router,
    });
    try server.listen();

    const leaks = gpa.detectLeaks();
    std.debug.print("has leaks : {}", .{leaks});
}
