const std = @import("std");
const Frame = @import("Frame.zig").Frame;
const Message = @import("Message.zig").Message;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn Writer(comptime WriterType: type) type {
    return struct {
        writer: WriterType,
        buf: []u8,
        allocator: Allocator,

        const Self = @This();

        const writer_buffer_len = 4096;

        pub fn init(allocator: Allocator, inner_writer: WriterType) !Self {
            return .{
                .allocator = allocator,
                .buf = try allocator.alloc(u8, writer_buffer_len),
                .writer = inner_writer,
            };
        }

        pub fn pong(self: *Self, payload: []const u8) !void {
            assert(payload.len < 126);
            const frame = Frame{ .fin = 1, .opcode = .pong, .payload = payload, .mask = 1 };
            const bytes = frame.encode(self.buf, 0);
            try self.writer.writeAll(self.buf[0..bytes]);
        }

        pub fn close(self: *Self, code: u16, payload: []const u8) !void {
            assert(payload.len < 124);
            const frame = Frame{ .fin = 1, .opcode = .close, .payload = payload, .mask = 1 };
            const bytes = frame.encode(self.buf, code);
            try self.writer.writeAll(self.buf[0..bytes]);
        }

        pub fn message(self: *Self, encoding: Message.Encoding, payload: []const u8, compressed: bool) !void {
            var sent_payload: usize = 0;
            // send multiple frames if needed
            while (true) {
                const first_frame = sent_payload == 0;

                var fin: u1 = 1;
                const rsv1: u1 = if (compressed and first_frame) 1 else 0;

                // use frame payload that fits into write_buf
                var frame_payload = payload[sent_payload..];
                if (frame_payload.len + Frame.max_header > self.buf.len) {
                    frame_payload = frame_payload[0 .. self.buf.len - Frame.max_header];
                    fin = 0;
                }
                const opcode = if (first_frame) encoding.opcode() else Frame.Opcode.continuation;

                // create frame
                const frame = Frame{ .fin = fin, .rsv1 = rsv1, .opcode = opcode, .payload = frame_payload, .mask = 1 };
                // encode frame into write_buf and send it to stream
                const bytes = frame.encode(self.buf, 0);
                try self.writer.writeAll(self.buf[0..bytes]);
                std.debug.print("buf: {any}\n", .{self.buf[0..bytes]});
                // loop if something is left
                sent_payload += frame_payload.len;
                if (sent_payload >= payload.len) {
                    break;
                }
            }
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buf);
        }
    };
}
