const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");

const BoundHandler = *fn (*const anyopaque, *root.Request, *root.Response) anyerror!void;

pub const Handler = struct {
    /// Function pointer of the instance
    method: root.HTTPMethod,
    path: []const u8,
    instance: usize,
    handler: usize,

    const Self = @This();

    pub fn init(method: root.HTTPMethod, path: []const u8, instance: *anyopaque, handler: anytype) !Handler {
        // INFO : Inspired from https://github.com/zigzap/zap/blob/master/src/router.zig
        comptime {
            const handlerInfo = @typeInfo(@TypeOf(handler));
            const f = blk: {
                if (handlerInfo == .@"fn") {
                    break :blk handlerInfo.@"fn";
                }
                @compileError("Expected handler to be a function pointer. Found " ++
                    @typeName(@TypeOf(handler)));
            };

            if (f.params.len != 3) {
                @compileError("Expected handler to have three paramters");
            }
            const arg_type1 = f.params[1].type.?;
            if (arg_type1 != *root.Request) {
                @compileError("Expected handler's second argument to be of type *lyn.Request. Found " ++
                    @typeName(arg_type1));
            }
            const arg_type2 = f.params[2].type.?;
            if (arg_type2 != *root.Response) {
                @compileError("Expected handler's third argument to be of type *lyn.Response. Found " ++
                    @typeName(arg_type2));
            }

            const ret_info = @typeInfo(f.return_type.?);
            if (ret_info != .error_union) {
                @compileError("Expected handler's return type to be !void. Found " ++
                    @typeName(f.return_type.?));
            }

            const payload = @typeInfo(ret_info.error_union.payload);
            if (payload != .void) {
                @compileError("Expected handler's return type to be !void. Found " ++
                    @typeName(f.return_type.?));
            }
        }

        return Self{
            .path = path,
            .instance = @intFromPtr(instance),
            .handler = @intFromPtr(&handler),
            .method = method,
        };
    }

    pub fn isMatch(self: Self, req: *root.Request) bool {
        if (self.method != req.method) return false;

        var handlerUrl = std.mem.splitSequence(u8, self.path, "/");
        var requestUrl = std.mem.splitSequence(u8, req.path, "/");

        while (requestUrl.next()) |reqUrl| {
            const handUrl = handlerUrl.next();
            if (handUrl == null) return false;

            if (std.mem.eql(u8, handUrl.?, reqUrl)) {
                //
            } else if (std.mem.startsWith(u8, handUrl.?, "{") and std.mem.endsWith(u8, handUrl.?, "}")) {
                // Parse the params
            } else {
                return false;
            }
        }
        return true;
    }

    pub fn call(self: Self, req: *root.Request, res: *root.Response) !void {
        try @call(.auto, @as(BoundHandler, @ptrFromInt(self.handler)), .{
            @as(*anyopaque, @ptrFromInt(self.instance)),
            req,
            res,
        });
    }
};
