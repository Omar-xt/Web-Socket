const std = @import("std");
const mn = @import("main.zig");

pub const Event = struct {
    name: []const u8,
    val: ?[]const u8 = null,
    obj: ?mn.RenderConfig = null,
    rObj: ?mn.Renderable = null,
};

pub fn encode(msg: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const firstByte: u8 = 129;
    var secByte: u8 = 0;

    const out_len = msg.len + 2;
    var lenBit: u8 = 0;

    if (msg.len > 125 and msg.len <= 65535) {
        lenBit = 2;
        secByte = 126;
    } else if (msg.len > 65535) {
        lenBit = 8;
        secByte = 127;
    } else secByte = @intCast(msg.len);

    const out = try alloc.alloc(u8, out_len + lenBit);
    // defer alloc.free(out);

    out[0] = firstByte;
    out[1] = secByte;

    switch (lenBit) {
        2 => std.mem.writeInt(u16, out[2..4], @intCast(msg.len), .big),
        8 => std.mem.writeInt(u64, out[2..10], @intCast(msg.len), .big),
        else => {},
    }

    @memcpy(out[2 + lenBit ..], msg);

    return out;
}

pub fn decode(msg: []u8, alloc: std.mem.Allocator) !usize {
    if (msg.len == 0) return 0;

    // const firstByte = msg[0];
    const secByte = msg[1];

    std.debug.print("{any}", .{msg});

    var mask_start: u8 = 2;
    const payloadLength = secByte - 128;
    var msgLen: u64 = payloadLength;
    var outLen: usize = 0;

    // std.debug.print("{any} : {d}\n", .{ msg, payloadLength });

    switch (payloadLength) {
        126 => {
            mask_start += 2;
            msgLen = std.mem.readInt(u16, msg[2..4], .big);
        },
        127 => {
            mask_start += 8;
            msgLen = try std.fmt.parseInt(u64, msg[2..10], 10);
        },
        else => {},
    }

    // std.debug.print("length: {d}\n", .{msgLen});
    // std.debug.print("{any}\n", .{mask});

    const out = try alloc.alloc(u8, msgLen);
    defer alloc.free(out);

    const mask_end = mask_start + 4;
    const mask = msg[mask_start..mask_end];

    const payloadEnd = mask_end + payloadLength;
    for (msg[mask_end..payloadEnd], 0..) |m, ind| {
        out[ind] = m ^ mask[ind % 4];
    }

    @memcpy(msg[0..out.len], out);
    outLen += out.len;

    if (msg.len > payloadEnd) {
        const len = try decode(msg[payloadEnd..], alloc);
        outLen += len + 1;

        const buf = try alloc.alloc(u8, len);
        defer alloc.free(buf);

        msg[out.len] = '\n';
        @memcpy(buf, msg[payloadEnd .. payloadEnd + len]);
        @memcpy(msg[out.len + 1 .. out.len + len + 1], buf);
    }

    return outLen;
}
