const std = @import("std");
const mem = @import("std").mem;
const builtin = @import("builtin");
const net = @import("std").net;
const stdout = std.io.getStdOut().writer();

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
        try stdout.print("Listening on http://{}", .{self._server.listen_address});
        defer self._server.deinit();

        while (true) {
            const client = try self._server.accept();
            defer client.stream.close();

            try stdout.print("Connected to new client - {}", .{client.address});

            const message = try client.stream.reader().readAllAlloc(self._allocator, 1024);
            defer self._allocator.free(message);

            try stdout.print("{} says {s}\n", .{ client.address, message });
        }
    }
};
