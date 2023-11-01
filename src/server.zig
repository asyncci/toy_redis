const std = @import("std");
const variable = 10;
const lib = @import("lib.zig");
const readAll = lib.readAll;
const writeAll = lib.writeAll;
const Allocator = std.mem.Allocator;

const out = std.io.getStdOut();
const err = std.io.getStdErr();

var bufOut = std.io.bufferedWriter(out.writer());
var outWriter = bufOut.writer();

var bufErr = std.io.bufferedWriter(err.writer());
var errWriter = bufErr.writer();

pub fn main() !void {
    //create socket
    const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    try std.os.setsockopt(sock, std.os.SOL.SOCKET, std.os.SO.REUSEADDR, &[_]u8{ 1, 0, 0, 0 });

    //bind ip address to socket
    const addr = std.net.Address.initIp4([_]u8{ 0, 0, 0, 0 }, 1234);
    try std.os.bind(sock, &addr.any, addr.getOsSockLen());

    try std.os.listen(sock, 4096);

    //non blocking mode enable for initial socket -> sock
    try lib.setNonBlock(sock);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var connections = lib.ConnectionsMap{};
    defer connections.deinit(lib.server_lib.fb_allocator);

    var poll_args = std.ArrayList(std.os.pollfd).init(allocator);
    defer poll_args.deinit();

    while (true) {
        poll_args.clearRetainingCapacity();
        //lazy socket
        try poll_args.append(.{ .fd = sock, .events = std.os.POLL.IN, .revents = 0 });

        var connectionsIt = connections.iterator();
        while (connectionsIt.next()) |conn| {
            const POLL = std.os.POLL;
            const pfd: std.os.pollfd = .{
                .fd = conn.key_ptr.*,
                .events = if (conn.value_ptr.state == .Request) POLL.IN else POLL.OUT,
                .revents = 0,
            };
            try poll_args.append(pfd);
        }

        std.debug.print("size: {}\n", .{poll_args.items.len});
        _ = try std.os.poll(poll_args.items, 1000);

        const nonLazy = poll_args.items[1..];
        for (nonLazy) |pfd| {
            var conn = connections.getPtr(pfd.fd);
            if (conn) |connection| {
                try lib.server_lib.connectionIO(pfd.fd, connection);

                if (connection.state == .End) {
                    std.os.close(pfd.fd);
                    _ = connections.swapRemove(pfd.fd);
                }
            }
        }

        if (poll_args.items[0].revents > 0)
            try lib.server_lib.newConnection(poll_args.items[0].fd, &connections);
    }
}
