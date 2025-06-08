const std = @import("std");
const mem = @import("std").mem;

const httpLib = @import("http.zig");
const HTTPStatus = httpLib.HTTPStatus;

pub const Response = struct {
    status: HTTPStatus,
    contentType: ?[]const u8,
    body: ?[]const u8,
    _allocator: mem.Allocator,

    const Self = @This();

    pub fn init(allocator: mem.Allocator) Self {
        return Self{
            .status = HTTPStatus.Ok,
            .contentType = null,
            .body = null,
            ._allocator = allocator,
        };
    }

    pub fn json(self: *Self, code: HTTPStatus, content: anytype) !*Self {
        self.status = code;
        if (self.body != null) {
            self._allocator.free(self.body.?);
        }

        self.body = try std.json.stringifyAlloc(self._allocator, content, .{});
        self.contentType = "application/json";

        return self;
    }

    /// This function commit the content of this struct to corresponding stream
    /// It will require some allocation to properly create response stream
    ///
    /// NOTE : DO NOT USE THIS FUNCTION SINCE IT'S FOR INTERNAL USE ONLY
    pub fn send(self: Self, stream: std.net.Stream) !void {
        var strResponse = try std.ArrayList(u8).initCapacity(self._allocator, 1024);
        defer strResponse.deinit();

        const httpCode = try std.fmt.allocPrint(self._allocator, "HTTP/1.1 {} {s}\r\n", .{ @intFromEnum(self.status), "OK" });
        try strResponse.appendSlice(httpCode);
        self._allocator.free(httpCode);

        if (self.body != null) {
            const contentType = try std.fmt.allocPrint(self._allocator, "Content-Type: {s}\r\n", .{self.contentType.?});
            try strResponse.appendSlice(contentType);
            self._allocator.free(contentType);

            const contentLength = try std.fmt.allocPrint(self._allocator, "Content-Length: {}\r\n\r\n", .{self.body.?.len});
            try strResponse.appendSlice(contentLength);
            self._allocator.free(contentLength);

            try strResponse.appendSlice(self.body.?);
        }

        _ = try stream.write(strResponse.items);
    }

    /// Deallocate any allocation made and cause this entire data to be invalidate.
    pub fn deinit(self: Self) void {
        if (self.body != null) {
            self._allocator.free(self.body.?);
        }
    }
};
