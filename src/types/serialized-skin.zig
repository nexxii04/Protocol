const std = @import("std");

const BinaryStream = @import("BinaryStream").BinaryStream;

const ClientData = @import("../login/types.zig").ClientData;
const SkinAnimation = @import("../login/types.zig").SkinAnimation;
const Uuid = @import("uuid.zig").Uuid;

pub const SerializedSkin = struct {
    pub fn write(stream: *BinaryStream, skin: *const ClientData, allocator: std.mem.Allocator, fallback_skin_id: []const u8) !void {
        try stream.writeVarString(skin.skin_id);

        try writeResourcePatch(stream, skin.skin_resource_patch, skin.arm_size, allocator);

        try writeSkinImage(stream, skin.skin_image_width, skin.skin_image_height, skin.skin_data, allocator);

        try stream.writeVarInt(@intCast(skin.animated_image_data.len));
        for (skin.animated_image_data) |anim| {
            try writeAnimation(stream, &anim, allocator);
        }

        try writeSkinImage(stream, skin.cape_image_width, skin.cape_image_height, skin.cape_data, allocator);

        try writeGeometryData(stream, skin.skin_geometry_data, allocator);
        try writeBase64Decoded(stream, skin.skin_geometry_data_engine_version, allocator);

        try writeBase64Decoded(stream, skin.skin_animation_data, allocator);
        try stream.writeVarString(skin.cape_id);
        // The client caches skins by this value. The skin's own id is stable
        // across sessions; the player uuid is only a fallback.
        try stream.writeVarString(if (skin.skin_id.len > 0) skin.skin_id else fallback_skin_id);

        try stream.writeUint8(if (std.ascii.eqlIgnoreCase(skin.arm_size, "slim")) 0 else 1);
        try stream.writeInt32(@bitCast(parseHexColor(skin.skin_color)), .Little);

        try stream.writeVarInt(@intCast(skin.persona_pieces.len));
        for (skin.persona_pieces) |piece| {
            try stream.writeVarString(piece.piece_id);
            try stream.writeInt32(@bitCast(pieceTypeOrdinal(piece.piece_type)), .Little);

            writePackId(stream, piece.pack_id) catch {
                try stream.write(&[_]u8{0} ** 16);
            };
            try stream.writeBool(piece.is_default);
            try stream.writeVarString(piece.product_id);
        }

        try stream.writeVarInt(@intCast(skin.piece_tint_colors.len));
        for (skin.piece_tint_colors) |tint| {
            try stream.writeVarString(pieceTypeWireName(tint.piece_type));
            for (tint.colors) |colour| {
                try stream.writeInt32(@bitCast(parseHexColor(colour)), .Little);
            }
        }

        try stream.writeBool(skin.premium_skin);
        try stream.writeBool(skin.persona_skin);
        try stream.writeBool(skin.cape_on_classic_skin);
        try stream.writeBool(true);
        try stream.writeBool(skin.override_skin);

        // There is no "false" state on the wire: an untrusted skin is "unset".
        try stream.writeVarString(if (skin.trusted_skin) "true" else "unset");

        try stream.writeVarString(skin.profile_hash);
    }

    fn writeAnimation(stream: *BinaryStream, anim: *const SkinAnimation, allocator: std.mem.Allocator) !void {
        try stream.writeUint32(@intCast(anim.image_width), .Little);
        try stream.writeUint32(@intCast(anim.image_height), .Little);
        const decoded = try decodeBase64String(allocator, anim.image);
        defer allocator.free(decoded);
        try stream.writeVarInt(@intCast(decoded.len));
        try stream.write(decoded);
        try stream.writeVarInt(@intCast(anim.animation_type));
        try stream.writeFloat32(@floatCast(anim.frames), .Little);
        try stream.writeVarInt(@intCast(anim.expression_type));
    }

    fn writeSkinImage(stream: *BinaryStream, width: i64, height: i64, data: []const u8, allocator: std.mem.Allocator) !void {
        try stream.writeUint32(@intCast(width), .Little);
        try stream.writeUint32(@intCast(height), .Little);
        if (data.len == 0) {
            try stream.writeVarInt(0);
            return;
        }
        const decoded = try decodeBase64String(allocator, data);
        defer allocator.free(decoded);
        try stream.writeVarInt(@intCast(decoded.len));
        try stream.write(decoded);
    }

    fn writeResourcePatch(stream: *BinaryStream, data: []const u8, arm_size: []const u8, allocator: std.mem.Allocator) !void {
        // The fallback has to match the arm width, or a slim skin is rendered
        // on the wide model and the arms break away from the body.
        const fallback: []const u8 = if (std.ascii.eqlIgnoreCase(arm_size, "slim"))
            "{\"geometry\":{\"default\":\"geometry.humanoid.customSlim\"}}"
        else
            "{\"geometry\":{\"default\":\"geometry.humanoid.custom\"}}";
        if (data.len == 0) {
            try stream.writeVarString(fallback);
            return;
        }

        const decoded = try decodeBase64String(allocator, data);
        defer allocator.free(decoded);

        if (decoded.len == 0) {
            try stream.writeVarString(fallback);
        } else {
            try stream.writeVarString(decoded);
        }
    }

    fn writeGeometryData(stream: *BinaryStream, data: []const u8, allocator: std.mem.Allocator) !void {
        if (data.len == 0) {
            try stream.writeVarString("{}");
            return;
        }
        const decoded = try decodeBase64String(allocator, data);
        defer allocator.free(decoded);
        if (decoded.len == 0) {
            try stream.writeVarString("{}");
        } else {
            try stream.writeVarString(decoded);
        }
    }

    fn writeBase64Decoded(stream: *BinaryStream, data: []const u8, allocator: std.mem.Allocator) !void {
        if (data.len == 0) {
            try stream.writeVarInt(0);
            return;
        }
        const decoded = try decodeBase64String(allocator, data);
        defer allocator.free(decoded);
        try stream.writeVarString(decoded);
    }

    fn decodeBase64String(allocator: std.mem.Allocator, data: []const u8) ![]u8 {
        if (data.len == 0) {
            return try allocator.alloc(u8, 0);
        }
        inline for (.{ std.base64.standard, std.base64.standard_no_pad, std.base64.url_safe, std.base64.url_safe_no_pad }) |decoder| {
            if (decoder.Decoder.calcSizeForSlice(data)) |decoded_len| {
                const decoded = try allocator.alloc(u8, decoded_len);
                if (decoder.Decoder.decode(decoded, data)) |_| {
                    return decoded;
                } else |_| {
                    allocator.free(decoded);
                }
            } else |_| {}
        }
        std.log.warn("[SKIN-B64] fallback to raw, len={d}", .{data.len});
        return try allocator.dupe(u8, data);
    }

    pub fn personaPieceOrdinal(name: []const u8) u32 {
        return pieceTypeOrdinal(name);
    }

    pub fn personaPieceWireName(name: []const u8) []const u8 {
        return pieceTypeWireName(name);
    }
};

/// Converts a login-data hex colour into the ARGB integer the skin codec
/// writes. SkinColor is "#rrggbb" while tint colors are ARGB ("#ffa12722")
/// and may omit leading digits entirely ("#0").
fn parseHexColor(hex: []const u8) u32 {
    var digits: []const u8 = hex;
    if (digits.len > 0 and digits[0] == '#') {
        digits = digits[1..];
    }

    const value = std.fmt.parseInt(u32, digits, 16) catch return 0;
    return value;
}

fn writePackId(stream: *BinaryStream, pack_id: []const u8) !void {
    if (pack_id.len == 36 or pack_id.len == 16) {
        try Uuid.write(stream, pack_id);
        return;
    }
    return error.InvalidUuidLength;
}

const PersonaPieceTypeEntry = struct { name: []const u8, ordinal: u32 };

/// Canonical names, exactly as the game spells them on the wire (the tint
/// keys use these). The login data prefixes them with `persona_` and spells
/// the hands as `persona_hand`.
const persona_piece_types = [_]PersonaPieceTypeEntry{
    .{ .name = "unknown", .ordinal = 0 },
    .{ .name = "skeleton", .ordinal = 1 },
    .{ .name = "body", .ordinal = 2 },
    .{ .name = "skin", .ordinal = 3 },
    .{ .name = "bottom", .ordinal = 4 },
    .{ .name = "feet", .ordinal = 5 },
    .{ .name = "dress", .ordinal = 6 },
    .{ .name = "top", .ordinal = 7 },
    .{ .name = "high_pants", .ordinal = 8 },
    .{ .name = "hands", .ordinal = 9 },
    .{ .name = "outerwear", .ordinal = 10 },
    .{ .name = "facial_hair", .ordinal = 11 },
    .{ .name = "mouth", .ordinal = 12 },
    .{ .name = "eyes", .ordinal = 13 },
    .{ .name = "hair", .ordinal = 14 },
    .{ .name = "hood", .ordinal = 15 },
    .{ .name = "back", .ordinal = 16 },
    .{ .name = "face_accessory", .ordinal = 17 },
    .{ .name = "head", .ordinal = 18 },
    .{ .name = "legs", .ordinal = 19 },
    .{ .name = "left_leg", .ordinal = 20 },
    .{ .name = "right_leg", .ordinal = 21 },
    .{ .name = "arms", .ordinal = 22 },
    .{ .name = "left_arm", .ordinal = 23 },
    .{ .name = "right_arm", .ordinal = 24 },
    .{ .name = "capes", .ordinal = 25 },
    .{ .name = "classic_skin", .ordinal = 26 },
    .{ .name = "emote", .ordinal = 27 },
    .{ .name = "coco", .ordinal = 28 },
    .{ .name = "unsupported", .ordinal = 29 },
};

fn stripPersonaPrefix(name: []const u8) []const u8 {
    const prefix = "persona_";
    if (name.len >= prefix.len and std.ascii.eqlIgnoreCase(name[0..prefix.len], prefix)) {
        return name[prefix.len..];
    }
    return name;
}

/// Compares two piece names ignoring case and underscores, so that
/// `persona_left_arm`, `LeftArm` and `leftarm` all match.
fn personaNameEquals(candidate: []const u8, canonical: []const u8) bool {
    var i: usize = 0;
    var j: usize = 0;
    while (true) {
        while (i < candidate.len and candidate[i] == '_') i += 1;
        while (j < canonical.len and canonical[j] == '_') j += 1;
        if (i == candidate.len or j == canonical.len) break;
        if (std.ascii.toLower(candidate[i]) != std.ascii.toLower(canonical[j])) return false;
        i += 1;
        j += 1;
    }
    return i == candidate.len and j == canonical.len;
}

/// The canonical wire name for a login piece type, or null when it is not a
/// known persona type.
fn personaWireName(name: []const u8) ?[]const u8 {
    const short = stripPersonaPrefix(name);
    for (persona_piece_types) |entry| {
        if (personaNameEquals(short, entry.name)) return entry.name;
    }
    if (personaNameEquals(short, "hand")) return "hands";
    return null;
}

fn pieceTypeWireName(name: []const u8) []const u8 {
    return personaWireName(name) orelse stripPersonaPrefix(name);
}

fn pieceTypeOrdinal(name: []const u8) u32 {
    const wire_name = personaWireName(name) orelse return 0;
    for (persona_piece_types) |entry| {
        if (std.mem.eql(u8, wire_name, entry.name)) return entry.ordinal;
    }
    return 0;
}

test "parseHexColor keeps six digit rgb with alpha 0 like pmmp" {
    try std.testing.expectEqual(@as(u32, 0x00B37B62), parseHexColor("#b37b62"));
    try std.testing.expectEqual(@as(u32, 0xFFA12722), parseHexColor("#ffa12722"));
    try std.testing.expectEqual(@as(u32, 0), parseHexColor("#0"));
    try std.testing.expectEqual(@as(u32, 0), parseHexColor(""));
}

test "pieceTypeOrdinal maps login names to wire ordinals" {
    try std.testing.expectEqual(@as(u32, 13), pieceTypeOrdinal("persona_eyes"));
    try std.testing.expectEqual(@as(u32, 13), pieceTypeOrdinal("eyes"));
    try std.testing.expectEqual(@as(u32, 9), pieceTypeOrdinal("persona_hand"));
    try std.testing.expectEqual(@as(u32, 8), pieceTypeOrdinal("persona_high_pants"));
    try std.testing.expectEqual(@as(u32, 11), pieceTypeOrdinal("persona_facial_hair"));
    try std.testing.expectEqual(@as(u32, 17), pieceTypeOrdinal("persona_face_accessory"));
    try std.testing.expectEqual(@as(u32, 20), pieceTypeOrdinal("persona_left_leg"));
    try std.testing.expectEqual(@as(u32, 21), pieceTypeOrdinal("persona_right_leg"));
    try std.testing.expectEqual(@as(u32, 23), pieceTypeOrdinal("persona_left_arm"));
    try std.testing.expectEqual(@as(u32, 24), pieceTypeOrdinal("persona_right_arm"));
    try std.testing.expectEqual(@as(u32, 26), pieceTypeOrdinal("persona_classic_skin"));
    try std.testing.expectEqual(@as(u32, 28), pieceTypeOrdinal("persona_coco"));
    try std.testing.expectEqual(@as(u32, 29), pieceTypeOrdinal("unsupported"));
    try std.testing.expectEqual(@as(u32, 29), pieceTypeOrdinal("PERSONA_UNSUPPORTED"));
    try std.testing.expectEqual(@as(u32, 23), pieceTypeOrdinal("LeftArm"));
    try std.testing.expectEqual(@as(u32, 0), pieceTypeOrdinal("persona_not_a_type"));
}

test "pieceTypeWireName keeps the names the client tints use" {
    try std.testing.expectEqualStrings("hands", pieceTypeWireName("persona_hand"));
    try std.testing.expectEqualStrings("hands", pieceTypeWireName("persona_hands"));
    try std.testing.expectEqualStrings("high_pants", pieceTypeWireName("persona_high_pants"));
    try std.testing.expectEqualStrings("facial_hair", pieceTypeWireName("persona_facial_hair"));
    try std.testing.expectEqualStrings("face_accessory", pieceTypeWireName("persona_face_accessory"));
    try std.testing.expectEqualStrings("left_leg", pieceTypeWireName("persona_left_leg"));
    try std.testing.expectEqualStrings("right_leg", pieceTypeWireName("persona_right_leg"));
    try std.testing.expectEqualStrings("left_arm", pieceTypeWireName("persona_left_arm"));
    try std.testing.expectEqualStrings("right_arm", pieceTypeWireName("persona_right_arm"));
    try std.testing.expectEqualStrings("classic_skin", pieceTypeWireName("persona_classic_skin"));
    try std.testing.expectEqualStrings("coco", pieceTypeWireName("persona_coco"));
    try std.testing.expectEqualStrings("eyes", pieceTypeWireName("persona_eyes"));
}
