const serverLib = @import("http/server.zig");
const requestLib = @import("http/request.zig");
const responseLib = @import("http/response.zig");
const httpLib = @import("http/http.zig");
const appLib = @import("app/app.zig");
const routerLib = @import("app/router.zig");

pub const Server = serverLib.Server;
pub const ServerConfig = serverLib.ServerConfig;
pub const OnRequestHandler = serverLib.OnRequestHandler;
pub const Request = requestLib.Request;
pub const Response = responseLib.Response;
pub const HTTPMethod = httpLib.HTTPMethod;
pub const HTTPStatus = httpLib.HTTPStatus;

pub const App = appLib.App;
pub const AppConfig = appLib.AppConfig;
pub const Router = routerLib.Router;

// Re Export Used Library
pub const Datetime = @import("datetime").datetime;

// Refrences for HTTP Request
// Host: localhost:8000
// User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0
// Accept: */*
// Accept-Language: en,en-GB;q=0.8,ja;q=0.5,de;q=0.3
// Accept-Encoding: gzip, deflate, br, zstd
// DNT: 1
// Connection: keep-alive
// Cookie: phpMyAdmin=cb2bda84366332b27a9bfa73c805180f
// Sec-Fetch-Dest: empty
// Sec-Fetch-Mode: cors
// Sec-Fetch-Site: same-origin

test "Parse Request" {
    const std = @import("std");
    const expect = std.testing.expect;

    const request = ("Host: localhost:8000\r\n" ++
        "User-Agent: Testing\r\n\r\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var req = try Request.parseFromBuffer(allocator, request);
    defer req.deinit();

    try expect(std.mem.eql(u8, req.userAgent, "Testing"));
}
