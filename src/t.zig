// const std = @import("std");
// const utils = @import("utils.zig");
// const nServer = @import("nServer.zig");

// pub fn main() !void {
// const alloc = std.heap.page_allocator;

// const ip = "127.0.0.1";
// const port = 8080;

// var server = nServer.init(.{
//     .ip = ip,
//     .port = port,
// }, alloc);
// try server.listen();

// var readBuf: [1024]u8 = undefined;
// var len = try server.readNext(&readBuf);
// if (len != null) {
// std.debug.print("{s}\n", .{readBuf[0..len.?]});
// }

// len = try server.readNext(&readBuf);
// if (len != null) {
//     std.debug.print("{s}\n", .{readBuf[0..len.?]});
// }

// var count: usize = 0;
// while (true) {
//     len = try server.readNext(&readBuf);
//     if (len != null) {
//         std.debug.print("{s}\n", .{readBuf[0..len.?]});
//     }

//     try server.write("HAy");

//     len = try server.read(&readBuf);

//     if (count == 10) {
//         try nServer.setBlock(server.client_fd);
//     }

//     count += 1;

//     std.time.sleep(2e9);
// }
// }
