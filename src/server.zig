const std = @import("std");
const variable = 10;
const lib = @import("lib.zig");
const readAll = lib.readAll;
const writeAll = lib.writeAll;

const out = std.io.getStdOut();
const err = std.io.getStdErr();

var bufOut = std.io.bufferedWriter(out.writer());
var outWriter = bufOut.writer();

var bufErr = std.io.bufferedWriter(err.writer());
var errWriter = bufErr.writer();

pub fn main() !void {
    const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    try std.os.setsockopt(sock, std.os.SOL.SOCKET, std.os.SO.REUSEADDR, &[_]u8{ 1, 0, 0, 0 });
    const addr = std.net.Address.initIp4([_]u8{ 0, 0, 0, 0 }, 1234);

    try outWriter.print("{any}\n", .{addr});
    try bufOut.flush();

    try std.os.bind(sock, &addr.any, addr.getOsSockLen());
    try std.os.listen(sock, 4096);
    while (true) {
        var addr_accept: std.net.Ip4Address = undefined;
        var addr_size = addr_accept.getOsSockLen();
        const conn_fd = std.os.accept(sock, @ptrCast(&addr_accept.sa), &addr_size, 0) catch -1;

        while (conn_fd != -1) {
            _ = readRequest(conn_fd) catch |err_result| {
                try errWriter.print("connection from: {} -> {}\n", .{ addr_accept, err_result });
                break;
            };
            try sendRequest(conn_fd, "ola");
            try bufErr.flush();
            try bufOut.flush();
        }

        if (conn_fd != -1)
            std.os.close(conn_fd);
    }
}

fn readRequest(fd: i32) ![]const u8 {
    var rbuf = std.mem.zeroes([4 + lib.maxMsg + 1]u8);
    try readAll(fd, &rbuf, 4);
    var len: u32 = @bitCast(rbuf[0..4].*);
    if (len > lib.maxMsg) return error.TooLong;
    try outWriter.print("len: {}\n", .{len});

    try readAll(fd, rbuf[4..], len);
    try outWriter.print("text: {s}\n", .{rbuf[4..(4 + len)]});
    return rbuf[4 .. 4 + len];
}

fn sendRequest(fd: i32, comptime reply: []const u8) !void {
    var wbuf = std.mem.zeroes([4 + reply.len]u8);
    @memcpy(wbuf[0..4], @as(*const [4]u8, @ptrCast(&reply.len)));
    @memcpy(wbuf[4..], reply);
    try writeAll(fd, &wbuf);
}
