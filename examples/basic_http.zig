const std = @import("std");
const lib = @import("lyn_zig_lib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try lib.Server.init(allocator, lib.ServerConfig.init("127.0.0.1", 8000));
    try server.listen();

    const leaks = gpa.detectLeaks();
    std.debug.print("has leaks : {}", .{leaks});
}
