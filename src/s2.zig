const std = @import("std");
const lib = @import("lib.zig");
const os = std.os;
const net = std.net;

pub fn main() !void {
    const fd = try os.socket(os.AF.INET, os.SOCK.STREAM, 0);
    try os.setsockopt(fd, os.SOL.SOCKET, os.SO.REUSEADDR, &[_]u8{ 1, 0, 0, 0 });

    const addr = net.Address.initIp4([_]u8{ 0, 0, 0, 0 }, 1234);
    try os.bind(fd, &addr.any, addr.getOsSockLen());
    try os.listen(fd, 4096);

    var pollArray: [10]os.pollfd = undefined;
    const pfd: os.pollfd = .{
        .fd = fd,
        .events = os.POLL.IN,
        .revents = 0,
    };
    pollArray[0] = pfd;

    var index: u8 = 1;

    while (true) {
        _ = try os.poll(&pollArray, 3000);

        for (1..index) |ind| {
            const pfd_c = pollArray[ind];

            switch (pfd_c.revents) {
                os.POLL.IN => {
                    var buf: [100]u8 = undefined;
                    try lib.readAll(pfd_c.fd, &buf, 5);
                    std.debug.print("read from [{}]: {s}\n", .{ fd, buf });
                },
                else => {},
            }
        }

        std.debug.print("lazy one current: {}\n", .{pollArray[0].revents});
        if (pollArray[0].revents == os.POLL.IN) {
            if (index < 10) {
                const conn = try os.accept(fd, null, null, 0);
                pollArray[index] = .{
                    .fd = conn,
                    .events = os.POLL.IN,
                    .revents = 0,
                };

                std.debug.print("connection!\n", .{});
                index += 1;
            }
        }
    }
}
