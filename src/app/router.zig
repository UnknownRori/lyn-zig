const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");

const BoundHandler = *fn (*const anyopaque, root.Request, *root.Response) anyerror!void;

const Handler = struct {
    /// Function pointer of the instance
    method: root.HTTPMethod,
    path: []const u8,
    instance: usize,
    handler: usize,
};

pub const Router = struct {
    _routes: std.ArrayList(Handler),
    _allocator: mem.Allocator,
    const Self = @This();

    pub fn init(allocator: mem.Allocator) Self {
        return Self{
            ._routes = std.ArrayList(Handler).init(allocator),
            ._allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self._routes.deinit();
    }

    pub fn get(self: *Self, path: []const u8, instance: *anyopaque, handler: anytype) !void {
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
            if (arg_type1 != root.Request) {
                @compileError("Expected handler's second argument to be of type lyn.Response. Found " ++
                    @typeName(arg_type1));
            }
            const arg_type2 = f.params[2].type.?;
            if (arg_type2 != *root.Response) {
                @compileError("Expected handler's third argument to be of type lyn.Response. Found " ++
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

        try self._routes.append(Handler{
            .path = path,
            .instance = @intFromPtr(instance),
            .handler = @intFromPtr(&handler),
            .method = root.HTTPMethod.GET,
        });
    }

    pub fn resolve(self: *Self, req: root.Request, res: *root.Response) !void {
        // TODO : resolve the route properly
        const handler = self._routes.getLast();

        try @call(.auto, @as(BoundHandler, @ptrFromInt(handler.handler)), .{
            @as(*anyopaque, @ptrFromInt(handler.instance)),
            req,
            res,
        });
    }
};
