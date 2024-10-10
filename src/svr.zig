fn buildWebSocketFrame(message: []const u8) []u8 {
    // Buffer for the WebSocket frame
    var frame: [128]u8 = undefined;
    var frame_len: usize = 0;

    // 1. FIN (1 bit) + RSV1, RSV2, RSV3 (1 bit each) + Opcode (4 bits)
    // For a text frame: FIN = 1, RSV1-3 = 0, Opcode = 0x1 (text frame)
    frame[0] = 0b10000001; // 1000 0001 -> FIN=1, Opcode=0x1 (text)
    frame_len += 1;

    // 2. Mask (1 bit, set to 0) + Payload length (7 bits)
    const msg_len = message.len;
    if (msg_len <= 125) {
        // Short payload, encode directly in 7 bits
        frame[1] = @intCast(msg_len); // Mask bit is 0, so just msg_len
        frame_len += 1;
    } else if (msg_len <= 65535) {
        // Extended payload length (126)
        frame[1] = 126; // Mask bit is 0, so 126
        frame[2] = @intCast((msg_len >> 8) & 0xFF); // Higher byte
        frame[3] = @intCast(msg_len & 0xFF); // Lower byte
        frame_len += 3;
    } else {
        // Extended payload length (127), 64-bit length (unlikely for most cases)
        frame[1] = 127;
        // Write the 8 bytes of length (most significant first)
        for (0..8) |i| {
            frame[2 + i] = @intCast((msg_len >> (56 - @as(u6, @intCast(i)) * 8)) & 0xFF);
        }
        frame_len += 9;
    }

    // 3. Payload data (unmasked, since it's from the server)
    for (0..msg_len) |i| {
        frame[frame_len + i] = message[i];
    }
    frame_len += msg_len;

    return frame[0..frame_len]; // Return the frame slice
}
