const std = @import("std");

pub fn main() !void {
    const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    const addr = std.net.Address.initIp4([_]u8{ 127, 0, 0, 1 }, 1234);
    try std.os.connect(sock, &addr.any, addr.getOsSockLen());

    const msg = "hello";
    _ = try std.os.write(sock, msg);

    const buf = std.mem.zeroes([64]u8);
    _ = try std.os.read(sock, &buf[0..]);
    std.debug.print("server says: {s}\n", .{buf});
}
