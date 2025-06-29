const std = @import("std");
const mem = std.mem;

const root = @import("../root.zig");

const BoundHandler = *fn (*const anyopaque, *root.Request, *root.Response) anyerror!void;

pub const Handler = struct {
    /// Function pointer of the instance
    instance: usize,
    handler: usize,

    const Self = @This();

    pub fn init(instance: *anyopaque, handler: anytype) !Handler {
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
            .instance = @intFromPtr(instance),
            .handler = @intFromPtr(&handler),
        };
    }

    pub fn call(self: Self, req: *root.Request, res: *root.Response) !void {
        try @call(.auto, @as(BoundHandler, @ptrFromInt(self.handler)), .{
            @as(*anyopaque, @ptrFromInt(self.instance)),
            req,
            res,
        });
    }
};
