const std = @import("std");
const Frame = @import("Frame.zig").Frame;
const Allocator = std.mem.Allocator;

pub const Message = struct {
    pub const Encoding = enum {
        text,
        binary,

        pub fn opcode(self: Encoding) Frame.Opcode {
            return if (self == .text) Frame.Opcode.text else Frame.Opcode.binary;
        }
    };

    encoding: Encoding = .text,
    payload: []const u8,
    allocator: ?Allocator = null,

    const Self = @This();

    pub fn init(allocator: Allocator, encoding: Encoding, payload: []const u8) !Self {
        var self = Self{
            .allocator = allocator,
            .encoding = encoding,
            .payload = payload,
        };
        try self.validate();
        return self;
    }

    pub fn deinit(self: Self) void {
        if (self.allocator) |a| a.free(self.payload);
    }

    fn validate(self: Self) !void {
        if (self.encoding == .text)
            try Frame.assertValidUtf8(self.payload);
    }
};
