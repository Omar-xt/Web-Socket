const std = @import("std");
const Handshake = @import("Handshake.zig");
const utils = @import("utils.zig");

pub const Server = struct {
    config: Config,
    server: std.net.Server,
    client: std.net.Server.Connection,
    alloc: std.mem.Allocator,

    const Self = @This();

    const Config = struct {
        ip: []const u8,
        port: u16 = 8008,
    };

    fn init(config: Config, alloc: std.mem.Allocator) Self {
        return Self{
            .config = .{ .ip = config.ip, .port = config.port },
            .server = undefined,
            .client = undefined,
            .alloc = alloc,
        };
    }

    fn lister(self: *Self) !void {
        const addr = try std.net.Address.parseIp4(self.config.ip, self.config.port);
        self.server = try addr.listen(.{ .reuse_port = true, .force_nonblocking = true });

        self.client = blk: {
            while (true) {
                const cl = self.server.accept() catch |err| {
                    if (err == error.WouldBlock) continue;
                    return err;
                };

                break :blk cl;
            }
        };

        try self.handshake();
    }

    fn handshake(self: Self) !void {
        var readBuf: [1024]u8 = undefined;
        const len = try self.client.stream.read(&readBuf);

        var state = Handshake.Handshake.State{
            .len = len,
            .buf = readBuf[0..len],
            .pool = undefined,
            .headers = try Handshake.KeyValue.init(self.alloc, 10),
        };

        const handsk = try Handshake.Handshake.parse(&state);

        if (handsk) |h| {
            const res = Handshake.Handshake.createReply(h.key);
            _ = try self.client.stream.write(&res);
        }
    }

    fn read(self: Self, buf: []u8) !usize {
        const len = try self.client.stream.read(buf);
        return utils.decode(buf[0..len], self.alloc);
    }

    fn write(self: Self, buf: []const u8) !void {
        const msg = try utils.encode(buf, self.alloc);
        defer self.alloc.free(msg);
        _ = try self.client.stream.write(msg);
    }
};
