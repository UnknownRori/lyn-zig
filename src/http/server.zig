const std = @import("std");
const mem = @import("std").mem;
const builtin = @import("builtin");
const net = @import("std").net;
const stdout = std.io.getStdOut().writer();

const http = @import("http.zig");
const requestLib = @import("request.zig");
const Request = requestLib.Request;
const responseLib = @import("response.zig");
const Response = responseLib.Response;

pub const REQUEST_MAX_BUFFER = 2048;

// fn defaultResponse(_: Request, res: Response) !Response {
//     return try res.json(200, struct {
//         message: "Hello World!",
//     });
// }

pub const ServerConfig = struct {
    host: []const u8,
    port: u16,
    // onRequest: fn (req: Request, res: Response) ?Response,
    const Self = @This();

    /// Init the [`ServerConfig`] with default configuration
    /// NOTE : Do Not use this if you want to custom response
    pub fn init(host: []const u8, port: u16) Self {
        return Self{
            .host = host,
            .port = port,
            // .onRequest = defaultResponse,
        };
    }
};

/// This struct is building block of TCP connection server
pub const Server = struct {
    _socket: net.Address,
    _server: net.Server,
    _allocator: mem.Allocator,
    // _onRequest: fn (req: Request) void,
    const Self = @This();

    /// This function create server and this function require allocator
    /// that threadsafe to safely allocate memory to receive data from client.
    ///
    /// SAFETY : Thread-safe [`std.mem.Allocator`]
    pub fn init(allocator: mem.Allocator, config: ServerConfig) !Self {
        const addr = try net.Ip4Address.parse(config.host, config.port);
        const socket = net.Address{
            .in = addr,
        };
        return Self{
            ._socket = socket,
            ._server = undefined,
            ._allocator = allocator,
        };
    }

    pub fn listen(self: *Self) !void {
        self._server = try self._socket.listen(.{ .reuse_address = true });
        try stdout.print("Listening on http://{}\n", .{self._server.listen_address});
        defer self._server.deinit();

        while (true) {
            const client = try self._server.accept();
            defer client.stream.close();

            try stdout.print("Connected to new client - {}\n", .{client.address});
            const buffer = try self._allocator.alloc(u8, REQUEST_MAX_BUFFER);
            defer self._allocator.free(buffer);

            _ = try client.stream.read(buffer);

            try self.handleRequest(client.stream, buffer);
        }
    }

    // ------- INTERNAL FUNCTION -------

    fn handleRequest(self: *Self, stream: net.Stream, buffer: []const u8) !void {
        const request = try Request.parseFromBuffer(self._allocator, buffer);
        var response = Response.init(self._allocator);
        _ = try response.json(http.HTTPStatus.Ok, .{
            .name = "Hello, World",
        });
        _ = request;
        // response = self._onRequest(request, response);

        try response.send(stream);
        response.deinit();
    }
};
