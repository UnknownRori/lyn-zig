const std = @import("std");
const mem = @import("std").mem;

const httpLib = @import("http.zig");
const HTTPMethod = httpLib.HTTPMethod;

/// This struct hold information about the client request
/// All of the content is dynamically allocated and it will deallocated automatically
/// when the request is completed
pub const Request = struct {
    userAgent: []const u8,
    method: HTTPMethod,
    path: []const u8,
    body: []const u8,
    params: std.StringHashMap([]const u8),
    cookies: std.StringHashMap([]const u8),
    headers: std.StringHashMap([]const u8),
    /// Inherited from [`Server`] if it's created by [`Server`]
    _allocator: mem.Allocator,

    const Self = @This();

    // ------- INTERNAL FUNCTION -------

    /// This function will parse
    pub fn parseFromBuffer(allocator: mem.Allocator, buffer: []const u8) !Self {
        var split = mem.splitSequence(u8, buffer, "\r\n\r\n");

        const header = split.peek().?;
        var headerToken = mem.splitSequence(u8, header, "\r\n");
        var userAgent: []const u8 = "";
        var method: HTTPMethod = .GET;
        var path: []const u8 = "";
        const params = std.StringHashMap([]const u8).init(allocator);
        var headers = std.StringHashMap([]const u8).init(allocator);
        var cookies = std.StringHashMap([]const u8).init(allocator);
        std.debug.print("{s}\n", .{buffer});

        while (headerToken.next()) |token| {
            if (mem.startsWith(u8, token, "User-Agent:")) {
                var splitToken = mem.splitSequence(u8, token, ": ");
                _ = splitToken.next().?;
                userAgent = splitToken.next().?;
            } else if (mem.startsWith(u8, token, "Cookie:")) {
                var splitToken = mem.splitSequence(u8, token, ": ");
                _ = splitToken.next();
                const cookie = splitToken.next().?;
                var cookieTokens = mem.splitSequence(u8, cookie, "; ");
                while (cookieTokens.next()) |cookieToken| {
                    var pairToken = mem.splitSequence(u8, cookieToken, "=");
                    const key = pairToken.next();
                    const value = pairToken.next();

                    try cookies.put(key.?, value.?);
                }
            } else if (mem.startsWith(u8, token, "GET")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                _ = splitToken.next().?;
                path = splitToken.next().?;
                method = .GET;
            } else if (mem.startsWith(u8, token, "POST")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .POST;
            } else if (mem.startsWith(u8, token, "PATCH")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .PATCH;
            } else if (mem.startsWith(u8, token, "DELETE")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .DELETE;
            }

            if (mem.containsAtLeast(u8, token, 1, ":")) {
                var splitToken = mem.splitSequence(u8, token, ": ");
                const key = splitToken.next();
                const value = splitToken.next();
                if (key == null or value == null) {
                    continue;
                }
                try headers.put(key.?, value.?);
            }
        }

        const body = split.next().?;
        return Self{
            .userAgent = userAgent,
            .path = path,
            .method = method,
            .body = body,
            .params = params,
            .headers = headers,
            .cookies = cookies,
            ._allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.cookies.deinit();
        self.headers.deinit();
        self.params.deinit();
    }
};

// ------- INTERNAL FUNCTION -------
fn createStringFromSlice(allocator: mem.Allocator, buffer: []const u8) !std.ArrayList(u8) {
    var str = try std.ArrayList(u8).initCapacity(allocator, buffer.len);
    try str.appendSlice(buffer);
    return str;
}
