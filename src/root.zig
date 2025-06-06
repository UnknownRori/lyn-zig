const std = @import("std");
const mem = @import("std").mem;
const builtin = @import("builtin");
const net = @import("std").net;
const stdout = std.io.getStdOut().writer();

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

pub const REQUEST_MAX_BUFFER = 2048;
pub const HTTPMethod = enum {
    GET,
    POST,
    DELETE,
    PATCH,
};

pub const ServerConfig = struct {
    host: []const u8,
    port: u16,
    const Self = @This();

    pub fn init(host: []const u8, port: u16) Self {
        return Self{
            .host = host,
            .port = port,
        };
    }
};

pub const Server = struct {
    _socket: net.Address,
    _server: net.Server,
    _allocator: mem.Allocator,
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
        _ = request;

        try stream.writeAll("HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 1\n\nA");
    }
};

/// This struct hold information about the client request
/// All of the content is dynamically allocated and it will deallocated automatically
/// when the request is completed
pub const Request = struct {
    userAgent: []const u8,
    method: HTTPMethod,
    path: []const u8,
    body: []const u8,
    params: std.ArrayList([]const u8),
    /// Inherited from [`Server`] if it's created by [`Server`]
    _allocator: mem.Allocator,

    const Self = @This();

    // ------- INTERNAL FUNCTION -------

    /// This function will parse
    pub fn parseFromBuffer(allocator: mem.Allocator, buffer: []const u8) !Self {
        var split = mem.splitSequence(u8, buffer, "\r\n\r\n");

        const header = split.peek().?;
        const headerStr = try createStringFromSlice(allocator, header);
        var headerToken = mem.splitSequence(u8, headerStr.items, "\r\n");
        var userAgent: []const u8 = "";
        var method: HTTPMethod = .GET;
        var path: []const u8 = "";
        const params = std.ArrayList([]const u8).init(allocator);

        while (headerToken.next()) |token| {
            if (mem.startsWith(u8, token, "User-Agent:")) {
                var splitToken = mem.splitSequence(u8, token, ":");
                userAgent = splitToken.next().?;
            }
            if (mem.startsWith(u8, token, "GET")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .GET;
            }
            if (mem.startsWith(u8, token, "POST")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .POST;
            }
        }

        const body = split.next().?;
        return Self{
            .userAgent = userAgent,
            .path = path,
            .method = method,
            .body = body,
            .params = params,
            ._allocator = allocator,
        };
    }
};

// ------- INTERNAL FUNCTION -------
fn createStringFromSlice(allocator: mem.Allocator, buffer: []const u8) !std.ArrayList(u8) {
    var str = try std.ArrayList(u8).initCapacity(allocator, buffer.len);
    try str.appendSlice(buffer);
    return str;
}
