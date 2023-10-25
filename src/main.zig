const std = @import("std");
const variable = 10;

pub fn main() !void {
    const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    try std.os.setsockopt(sock, std.os.SOL.SOCKET, std.os.SO.REUSEADDR, &[_]u8{ 1, 0, 0, 0 });
    const addr = std.net.Address.initIp4([_]u8{ 0, 0, 0, 0 }, 1234);

    std.debug.print("{any}\n", .{addr});
    try std.os.bind(sock, &addr.any, addr.getOsSockLen());
    try std.os.listen(sock, 4096);
    while (true) {
        const conn_fd = try std.os.accept(sock, null, null, 0);
        doSomething(conn_fd);
        std.os.close(conn_fd);
    }
}

fn doSomething(fd: i32) void {
    const buf = std.mem.zeroes([64]u8);
    const size_ = std.os.read(fd, buf);
    if (size_ < 0)
        return;

    std.debug.print("client says: \n", .{buf});

    const wbuf = "world!";
    std.os.write(fd, &wbuf);
}
