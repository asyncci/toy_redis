const std = @import("std");
const lib = @import("lib.zig");

pub fn main() !void {
    const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    try std.os.setsockopt(sock, std.os.SOL.SOCKET, std.os.SO.REUSEADDR, &[_]u8{ 1, 0, 0, 0 });
    const addr = std.net.Address.initIp4([_]u8{ 127, 0, 0, 1 }, 1234);
    try std.os.connect(sock, &addr.any, addr.getOsSockLen());
    //try lib.setNonBlock(sock);
    //try lib.writeAll(sock, "helwo");

    while (true) {
        const response = try oneQuery(sock, "wlasdl");
        std.debug.print("{s}\n", .{response});
    }

    try std.os.shutdown(sock, std.os.ShutdownHow.both);
}
fn writeQuery(fd: i32, text: []const u8) !void {
    const wbuf = try lib.encode(text);
    try lib.writeAll(fd, wbuf);
}
fn readQuery(fd: i32) ![]const u8 {
    var rbuf = std.mem.zeroes([4 + lib.maxMsg]u8);
    try lib.readAll(fd, &rbuf, 4);

    const len: u32 = @bitCast(rbuf[0..4].*);
    if (len > lib.maxMsg) return error.ReadTooLong;

    try lib.readAll(fd, rbuf[4..], len);
    return rbuf[4..(4 + len)];
}

fn oneQuery(fd: i32, text: []const u8) ![]const u8 {
    try writeQuery(fd, text);
    return try readQuery(fd);
}
