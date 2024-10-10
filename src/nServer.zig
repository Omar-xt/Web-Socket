const std = @import("std");
const utils = @import("utils.zig");
const Handshake = @import("Handshake.zig");

const posix = std.posix;

const Self = @This();

const Config = struct {
    ip: []const u8,
    port: u16 = 8008,
};

config: Config,
server_fd: posix.socket_t,
client_fd: posix.socket_t,
client: std.net.Server.Connection,
write_buf: std.ArrayList(u8),
alloc: std.mem.Allocator,

pub fn init(config: Config, alloc: std.mem.Allocator) Self {
    return Self{
        .config = .{ .ip = config.ip, .port = config.port },
        .server_fd = undefined,
        .client_fd = undefined,
        .client = undefined,
        .write_buf = std.ArrayList(u8).init(alloc),
        .alloc = alloc,
    };
}

pub fn listen(self: *Self) !void {
    // self.server_fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, posix.IPPROTO.TCP);

    var addr = try std.net.Address.parseIp4(self.config.ip, self.config.port);
    var sock_len = addr.getOsSockLen();

    const ser = try addr.listen(.{ .reuse_port = true });
    self.server_fd = ser.stream.handle;

    // try posix.bind(self.server_fd, &addr.any, sock_len);
    // try posix.listen(self.server_fd, 3);

    self.client_fd = try posix.accept(self.server_fd, &addr.any, &sock_len, posix.SOCK.CLOEXEC);
    self.client = std.net.Server.Connection{ .address = undefined, .stream = .{ .handle = self.client_fd } };

    try self.handshake();

    try setNonBlock(self.client_fd, 0);
}

pub fn setNonBlock(sock: posix.socket_t, _: u32) !void {
    var fl_flags = posix.fcntl(sock, posix.F.GETFL, 0) catch |err| switch (err) {
        error.FileBusy => unreachable,
        error.Locked => unreachable,
        error.PermissionDenied => unreachable,
        error.DeadLock => unreachable,
        error.LockedRegionLimitExceeded => unreachable,
        else => |e| return e,
    };
    fl_flags |= 1 << @bitOffsetOf(posix.O, "NONBLOCK");
    _ = posix.fcntl(sock, posix.F.SETFL, fl_flags) catch |err| switch (err) {
        error.FileBusy => unreachable,
        error.Locked => unreachable,
        error.PermissionDenied => unreachable,
        error.DeadLock => unreachable,
        error.LockedRegionLimitExceeded => unreachable,
        else => |e| return e,
    };
    // std.debug.print("gtj : {d}\n", .{fl_flags});
}

pub fn setBlock(sock: posix.socket_t) !void {
    _ = posix.fcntl(sock, posix.F.SETFL, 2) catch |err| switch (err) {
        error.FileBusy => unreachable,
        error.Locked => unreachable,
        error.PermissionDenied => unreachable,
        error.DeadLock => unreachable,
        error.LockedRegionLimitExceeded => unreachable,
        else => |e| return e,
    };
}

pub fn handshake(self: Self) !void {
    var readBuf: [1024]u8 = undefined;
    const len = try posix.read(self.client_fd, &readBuf);

    var state = Handshake.Handshake.State{
        .len = len,
        .buf = readBuf[0..len],
        .pool = undefined,
        .headers = try Handshake.KeyValue.init(self.alloc, 10),
    };

    const handsk = try Handshake.Handshake.parse(&state);

    if (handsk) |h| {
        const res = Handshake.Handshake.createReply(h.key);
        _ = try posix.write(self.client_fd, &res);
        // _ = try self.client.stream.write(&res);
    }
}

pub fn readNext(self: Self, buf: []u8) !?usize {
    const len = posix.read(self.client_fd, buf) catch |err| {
        if (err == error.WouldBlock) return null;
        return err;
    };
    return try utils.decode(buf[0..len], self.alloc);
}

pub fn read(self: Self, buf: []u8) !usize {
    const len = blk: while (true) {
        const l = posix.read(self.client_fd, buf) catch |err| {
            if (err == error.WouldBlock) continue;
            return err;
        };
        break :blk l;
    };
    return try utils.decode(buf[0..len], self.alloc);
}

pub fn write(self: Self, buf: []const u8) !void {
    const msg = try utils.encode(buf, self.alloc);
    defer self.alloc.free(msg);
    _ = try posix.write(self.client_fd, msg);
}

pub fn emit(self: *Self, event: utils.Event) !void {
    try std.json.stringify(event, .{ .emit_null_optional_fields = false }, self.write_buf.writer());
    defer self.write_buf.clearRetainingCapacity();

    std.debug.print("{s}\n", .{self.write_buf.items});

    try self.write(self.write_buf.items);

    // const msg = try utils.encode(self.write_buf.items, self.alloc);
    // defer self.alloc.free(msg);

    // _ = try posix.write(self.client_fd, msg);
}

// pub fn emit_obj(self: *Self, obj: utils.Event2) !void {

// }
