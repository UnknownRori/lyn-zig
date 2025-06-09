# Lyn

Lyn is a simple minimalistic web framework inspired by Express.js and Laravel in development,
the point of this framework is to make development of backend or maybe frontend in Zig to be
not very painful.

## Getting Started

Make sure you have Zig 0.14

In your Zig project run
```sh
zig fetch --save "git+https://github.com/UnknownRori/lyn-zig#master"
```

Then add on your build.zig function

```zig
const lyn = b.dependency("lyn", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("lyn", lyn.module("lyn"));
```

## Examples

Example hello world

```zig
const std = @import("std");
const lib = @import("lyn");

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
```

## Development

Make sure you have Zig 0.14

```sh
# Clone the repository and enter to directory
git clone https://github.com/UnknownRori/lyn-zig
cd lyn-zig

# Run the project, it will start the server
zig build run
```

## License

This project is licensed using MIT License
