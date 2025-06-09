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
                path = splitToken.next().?;
                method = .GET;
            }
            if (mem.startsWith(u8, token, "POST")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .POST;
            }
            if (mem.startsWith(u8, token, "PATCH")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .PATCH;
            }
            if (mem.startsWith(u8, token, "DELETE")) {
                var splitToken = mem.splitSequence(u8, token, " ");
                path = splitToken.next().?;
                method = .DELETE;
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
