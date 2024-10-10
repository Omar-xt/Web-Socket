const std = @import("std");
const utils = @import("utils.zig");
const nServer = @import("nServer.zig");

// const Event = utils

const Vec2 = struct {
    x: i32,
    y: i32,
};

const shapeType = enum {
    Circle,
    Rectangle,
};

const Circle = struct {
    pos: Vec2,
    rad: i32,

    pub fn get(x: i32, y: i32, radius: i32) Renderable {
        return Renderable{ .Circle = Circle{
            .pos = .{ .x = x, .y = y },
            .rad = radius,
        } };
    }
};

const Rectangle = struct {
    pos: Vec2,
    size: Vec2,

    pub fn get(x: i32, y: i32, w: i32, h: i32) Renderable {
        return Renderable{ .Rectangle = Rectangle{
            .pos = .{ .x = x, .y = y },
            .size = .{ .x = w, .y = h },
        } };
    }
};

pub const RenderConfig = struct {
    shape: ?shapeType = null,
    pos: ?Vec2 = null,
    size: ?Vec2 = null,
    rad: ?i32 = null,
};

pub const Renderable = union(enum) {
    Circle: Circle,
    Rectangle: Rectangle,
};

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const ip = "127.0.0.1";
    const port = 8080;

    var server = nServer.init(.{
        .ip = ip,
        .port = port,
    }, alloc);
    try server.listen();

    var readBuf: [1024]u8 = undefined;
    var len = try server.readNext(&readBuf);
    if (len != null) {
        std.debug.print("{s}\n", .{readBuf[0..len.?]});
    }

    len = try server.readNext(&readBuf);
    if (len != null) {
        std.debug.print("{s}\n", .{readBuf[0..len.?]});
    }

    try server.emit(.{
        .name = "create_obj",
        .rObj = Circle.get(100, 100, 20),
    });

    try server.emit(.{
        .name = "create_obj",
        .rObj = Rectangle.get(300, 100, 50, 50),
    });

    // var writeBuf: [128]u8 = undefined;
    var count: usize = 0;
    while (true) {
        len = try server.readNext(&readBuf);
        if (len != null) {
            std.debug.print("{s}\n", .{readBuf[0..len.?]});
        }

        // try server.write(try std.fmt.bufPrint(&writeBuf, "{d}", .{count}));
        // const val = try std.fmt.bufPrint(&writeBuf, "{d}", .{count});
        // try server.emit(.{ .name = "move", .val = val });

        count += 1;

        std.time.sleep(1e9 / 10);
    }
}
