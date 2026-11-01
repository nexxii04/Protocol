const std = @import("std");

fn jsonTypeName(value: std.json.Value) []const u8 {
    return switch (value) {
        .null => "null",
        .bool => "bool",
        .integer => "integer",
        .float => "float",
        .number_string => "number_string",
        .string => "string",
        .array => "array",
        .object => "object",
    };
}

/// Reads a nested JSON value as text. Some clients send persona piece types as
/// numbers, so both forms are accepted; anything else becomes an empty string.
fn dupeJsonText(allocator: std.mem.Allocator, value: std.json.Value) ![]const u8 {
    return switch (value) {
        .string => |s| try allocator.dupe(u8, s),
        .integer => |i| try std.fmt.allocPrint(allocator, "{d}", .{i}),
        .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
        else => "",
    };
}

fn jsonInt(value: std.json.Value) i64 {
    return switch (value) {
        .integer => |i| i,
        .float => |f| @intFromFloat(f),
        .number_string => |s| std.fmt.parseInt(i64, s, 10) catch 0,
        else => 0,
    };
}

fn jsonBool(value: std.json.Value) bool {
    return switch (value) {
        .bool => |b| b,
        .integer => |i| i != 0,
        else => false,
    };
}

fn dupRequiredString(allocator: std.mem.Allocator, object: std.json.ObjectMap, key: []const u8) ![]const u8 {
    const value = object.get(key) orelse {
        std.log.err("Login field '{s}' is missing", .{key});
        return error.MissingRequiredLoginField;
    };
    return switch (value) {
        .string => |s| try allocator.dupe(u8, s),
        else => {
            std.log.err("Login field '{s}' expected string, got {s}", .{ key, jsonTypeName(value) });
            return error.InvalidRequiredLoginField;
        },
    };
}

pub const IdentityData = struct {
    xuid: []const u8,
    display_name: []const u8,
    identity: []const u8,
    title_id: []const u8,

    fn uuidFromXuid(allocator: std.mem.Allocator, xuid: []const u8) ![]const u8 {
        var md5 = std.crypto.hash.Md5.init(.{});
        md5.update("pocket-auth-1-xuid:");
        md5.update(xuid);
        var digest: [16]u8 = undefined;
        md5.final(&digest);
        digest[6] = (digest[6] & 0x0f) | 0x30;
        digest[8] = (digest[8] & 0x3f) | 0x80;

        const hex = "0123456789abcdef";
        var out: [36]u8 = undefined;
        var out_idx: usize = 0;
        for (digest, 0..) |byte, i| {
            if (i == 4 or i == 6 or i == 8 or i == 10) {
                out[out_idx] = '-';
                out_idx += 1;
            }
            out[out_idx] = hex[byte >> 4];
            out[out_idx + 1] = hex[byte & 0x0f];
            out_idx += 2;
        }
        return allocator.dupe(u8, &out);
    }

    pub fn parse(allocator: std.mem.Allocator, json_value: std.json.Value) !IdentityData {
        const xuid = try dupRequiredString(allocator, json_value.object, "xid");
        errdefer if (xuid.len > 0) allocator.free(xuid);

        const display_name = try dupRequiredString(allocator, json_value.object, "xname");
        errdefer if (display_name.len > 0) allocator.free(display_name);

        const identity = if (json_value.object.get("leguuid")) |leguuid_value| blk: {
            if (leguuid_value == .string and leguuid_value.string.len == 36) {
                break :blk try allocator.dupe(u8, leguuid_value.string);
            }
            break :blk try uuidFromXuid(allocator, xuid);
        } else try uuidFromXuid(allocator, xuid);
        errdefer if (identity.len > 0) allocator.free(identity);

        const title_id = try dupRequiredString(allocator, json_value.object, "tid");
        errdefer if (title_id.len > 0) allocator.free(title_id);

        return IdentityData{
            .xuid = xuid,
            .display_name = display_name,
            .identity = identity,
            .title_id = title_id,
        };
    }

    pub fn legacyParse(allocator: std.mem.Allocator, json_value: std.json.Value) !IdentityData {
        const extra_data = json_value.object.get("extraData") orelse return error.MissingExtraData;

        const xuid = try dupRequiredString(allocator, extra_data.object, "XUID");
        errdefer if (xuid.len > 0) allocator.free(xuid);

        const display_name = try dupRequiredString(allocator, extra_data.object, "displayName");
        errdefer if (display_name.len > 0) allocator.free(display_name);

        const identity = try dupRequiredString(allocator, extra_data.object, "identity");
        errdefer if (identity.len > 0) allocator.free(identity);

        const title_id = try dupRequiredString(allocator, extra_data.object, "titleId");
        errdefer if (title_id.len > 0) allocator.free(title_id);

        return IdentityData{
            .xuid = xuid,
            .display_name = display_name,
            .identity = identity,
            .title_id = title_id,
        };
    }

    pub fn deinit(self: *IdentityData, allocator: std.mem.Allocator) void {
        if (self.xuid.len > 0) allocator.free(self.xuid);
        if (self.display_name.len > 0) allocator.free(self.display_name);
        if (self.identity.len > 0) allocator.free(self.identity);
        if (self.title_id.len > 0) allocator.free(self.title_id);
    }
};

pub const SkinAnimation = struct {
    image: []const u8,
    image_width: i64,
    image_height: i64,
    animation_type: i64,
    frames: f64,
    expression_type: i64,
};

pub const PersonaPiece = struct {
    piece_id: []const u8,
    piece_type: []const u8,
    pack_id: []const u8,
    is_default: bool,
    product_id: []const u8,
};

pub const PersonaPieceTintColor = struct {
    piece_type: []const u8,
    colors: [4][]const u8,
};

pub const ClientData = struct {
    skin_id: []const u8,
    play_fab_id: []const u8,
    skin_data: []const u8,
    skin_image_width: i64,
    skin_image_height: i64,
    skin_geometry_data: []const u8,
    skin_geometry_data_engine_version: []const u8,
    skin_resource_patch: []const u8,
    skin_animation_data: []const u8,

    cape_id: []const u8,
    cape_data: []const u8,
    cape_image_width: i64,
    cape_image_height: i64,

    persona_skin: bool,
    premium_skin: bool,
    cape_on_classic_skin: bool,
    trusted_skin: bool,
    /// Whether the server skin replaces the one the client picked for itself.
    /// The clients send this as `OverrideSkin`; it defaults to true.
    override_skin: bool = true,
    profile_hash: []const u8 = "",
    arm_size: []const u8,
    skin_color: []const u8,

    animated_image_data: []const SkinAnimation,
    persona_pieces: []const PersonaPiece,
    piece_tint_colors: []const PersonaPieceTintColor,

    device_model: []const u8,
    device_os: i64,
    device_id: []const u8,
    game_version: []const u8,

    language_code: []const u8,
    server_address: []const u8,
    third_party_name: []const u8,
    platform_online_id: []const u8,
    self_signed_id: []const u8,

    ui_profile: i64,
    current_input_mode: i64,
    default_input_mode: i64,
    gui_scale: i64,

    pub fn parse(allocator: std.mem.Allocator, json_value: std.json.Value) !ClientData {
        const obj = json_value.object;

        const getString = struct {
            fn get(o: std.json.ObjectMap, key: []const u8, alloc: std.mem.Allocator) ![]const u8 {
                const value = o.get(key) orelse return "";
                return switch (value) {
                    .string => |s| try alloc.dupe(u8, s),
                    else => {
                        std.log.warn("Login field '{s}' expected string, got {s}", .{ key, jsonTypeName(value) });
                        return "";
                    },
                };
            }
        }.get;

        const getInt = struct {
            fn get(o: std.json.ObjectMap, key: []const u8) i64 {
                return if (o.get(key)) |v| jsonInt(v) else 0;
            }
        }.get;

        const getBool = struct {
            fn get(o: std.json.ObjectMap, key: []const u8, default: bool) bool {
                const value = o.get(key) orelse return default;
                return switch (value) {
                    .bool => |b| b,
                    else => default,
                };
            }
        }.get;

        const animated_image_data = blk: {
            const arr_val = obj.get("AnimatedImageData") orelse break :blk &[0]SkinAnimation{};
            if (arr_val != .array) break :blk &[0]SkinAnimation{};
            const arr = arr_val.array;
            if (arr.items.len == 0) break :blk &[0]SkinAnimation{};
            const anims = try allocator.alloc(SkinAnimation, arr.items.len);
            for (arr.items, 0..) |item, i| {
                const a = item.object;
                anims[i] = .{
                    .image = if (a.get("Image")) |v| try dupeJsonText(allocator, v) else "",
                    .image_width = if (a.get("ImageWidth")) |v| jsonInt(v) else 0,
                    .image_height = if (a.get("ImageHeight")) |v| jsonInt(v) else 0,
                    .animation_type = if (a.get("Type")) |v| jsonInt(v) else 0,
                    .frames = if (a.get("Frames")) |v| switch (v) {
                        .float => v.float,
                        .integer => @as(f64, @floatFromInt(v.integer)),
                        else => 0.0,
                    } else 0.0,
                    .expression_type = if (a.get("AnimationExpression")) |v| jsonInt(v) else 0,
                };
            }
            break :blk anims;
        };

        const persona_pieces = blk: {
            const arr_val = obj.get("PersonaPieces") orelse break :blk &[0]PersonaPiece{};
            if (arr_val != .array) break :blk &[0]PersonaPiece{};
            const arr = arr_val.array;
            if (arr.items.len == 0) break :blk &[0]PersonaPiece{};
            const pieces = try allocator.alloc(PersonaPiece, arr.items.len);
            for (arr.items, 0..) |item, i| {
                const p = item.object;
                pieces[i] = .{
                    .piece_id = if (p.get("PieceId")) |v| try dupeJsonText(allocator, v) else "",
                    .piece_type = if (p.get("PieceType")) |v| try dupeJsonText(allocator, v) else "",
                    .pack_id = if (p.get("PackId")) |v| try dupeJsonText(allocator, v) else "",
                    .is_default = if (p.get("IsDefault")) |v| jsonBool(v) else false,
                    .product_id = if (p.get("ProductId")) |v| try dupeJsonText(allocator, v) else "",
                };
            }
            break :blk pieces;
        };

        const piece_tint_color = blk: {
            const arr_val = obj.get("PieceTintColors") orelse break :blk &[0]PersonaPieceTintColor{};
            if (arr_val != .array) break :blk &[0]PersonaPieceTintColor{};
            const arr = arr_val.array;
            if (arr.items.len == 0) break :blk &[0]PersonaPieceTintColor{};
            const tints = try allocator.alloc(PersonaPieceTintColor, arr.items.len);
            for (arr.items, 0..) |item, i| {
                const t = item.object;
                var colors: [4][]const u8 = .{ "", "", "", "" };
                if (t.get("Colors")) |cv| {
                    if (cv == .array) {
                        for (cv.array.items, 0..) |c, ci| {
                            if (ci >= 4) break;
                            colors[ci] = try dupeJsonText(allocator, c);
                        }
                    }
                }
                tints[i] = .{
                    .piece_type = if (t.get("PieceType")) |v| try dupeJsonText(allocator, v) else "",
                    .colors = colors,
                };
            }
            break :blk tints;
        };

        return ClientData{
            .skin_id = try getString(obj, "SkinId", allocator),
            .play_fab_id = try getString(obj, "PlayFabId", allocator),
            .skin_data = try getString(obj, "SkinData", allocator),
            .skin_image_width = getInt(obj, "SkinImageWidth"),
            .skin_image_height = getInt(obj, "SkinImageHeight"),
            .skin_geometry_data = try getString(obj, "SkinGeometryData", allocator),
            .skin_geometry_data_engine_version = try getString(obj, "SkinGeometryDataEngineVersion", allocator),
            .skin_resource_patch = try getString(obj, "SkinResourcePatch", allocator),
            .skin_animation_data = try getString(obj, "SkinAnimationData", allocator),

            .cape_id = try getString(obj, "CapeId", allocator),
            .cape_data = try getString(obj, "CapeData", allocator),
            .cape_image_width = getInt(obj, "CapeImageWidth"),
            .cape_image_height = getInt(obj, "CapeImageHeight"),

            .persona_skin = getBool(obj, "PersonaSkin", false),
            .premium_skin = getBool(obj, "PremiumSkin", false),
            .cape_on_classic_skin = getBool(obj, "CapeOnClassicSkin", false),
            .trusted_skin = getBool(obj, "TrustedSkin", false),
            .override_skin = getBool(obj, "OverrideSkin", true),
            .arm_size = try getString(obj, "ArmSize", allocator),
            .skin_color = try getString(obj, "SkinColor", allocator),

            .animated_image_data = animated_image_data,
            .persona_pieces = persona_pieces,
            .piece_tint_colors = piece_tint_color,

            .device_model = try getString(obj, "DeviceModel", allocator),
            .device_os = getInt(obj, "DeviceOS"),
            .device_id = try getString(obj, "DeviceId", allocator),
            .game_version = try getString(obj, "GameVersion", allocator),

            .language_code = try getString(obj, "LanguageCode", allocator),
            .server_address = try getString(obj, "ServerAddress", allocator),
            .third_party_name = try getString(obj, "ThirdPartyName", allocator),
            .platform_online_id = try getString(obj, "PlatformOnlineId", allocator),
            .self_signed_id = try getString(obj, "SelfSignedId", allocator),

            .ui_profile = getInt(obj, "UIProfile"),
            .current_input_mode = getInt(obj, "CurrentInputMode"),
            .default_input_mode = getInt(obj, "DefaultInputMode"),
            .gui_scale = getInt(obj, "GuiScale"),
        };
    }

    pub fn deinit(self: *ClientData, allocator: std.mem.Allocator) void {
        for (self.animated_image_data) |anim| {
            if (anim.image.len > 0) allocator.free(anim.image);
        }
        if (self.animated_image_data.len > 0) allocator.free(self.animated_image_data);

        for (self.persona_pieces) |piece| {
            if (piece.piece_id.len > 0) allocator.free(piece.piece_id);
            if (piece.piece_type.len > 0) allocator.free(piece.piece_type);
            if (piece.pack_id.len > 0) allocator.free(piece.pack_id);
            if (piece.product_id.len > 0) allocator.free(piece.product_id);
        }
        if (self.persona_pieces.len > 0) allocator.free(self.persona_pieces);

        for (self.piece_tint_colors) |tint| {
            if (tint.piece_type.len > 0) allocator.free(tint.piece_type);
            for (tint.colors) |c| {
                if (c.len > 0) allocator.free(c);
            }
        }
        if (self.piece_tint_colors.len > 0) allocator.free(self.piece_tint_colors);

        inline for (@typeInfo(ClientData).@"struct".fields) |field| {
            if (field.type == []const u8) {
                const value = @field(self, field.name);
                if (value.len > 0) allocator.free(value);
            }
        }
    }

    pub fn decodeSkinPixels(self: *const ClientData, allocator: std.mem.Allocator) ![]u8 {
        if (self.skin_data.len == 0) return error.NoSkinData;

        const decoder = std.base64.standard;
        const decoded_len = try decoder.Decoder.calcSizeForSlice(self.skin_data);
        const decoded = try allocator.alloc(u8, decoded_len);
        errdefer allocator.free(decoded);

        try decoder.Decoder.decode(decoded, self.skin_data);
        return decoded;
    }

    pub fn decodeCapePixels(self: *const ClientData, allocator: std.mem.Allocator) ![]u8 {
        if (self.cape_data.len == 0) return error.NoCapeData;

        const decoder = std.base64.standard;
        const decoded_len = try decoder.Decoder.calcSizeForSlice(self.cape_data);
        const decoded = try allocator.alloc(u8, decoded_len);
        errdefer allocator.free(decoded);

        try decoder.Decoder.decode(decoded, self.cape_data);
        return decoded;
    }

    pub fn getDeviceOSName(self: *const ClientData) []const u8 {
        return switch (self.device_os) {
            1 => "Android",
            2 => "iOS",
            3 => "macOS",
            4 => "FireOS",
            5 => "GearVR",
            6 => "Hololens",
            7 => "Windows 10",
            8 => "Windows",
            9 => "Dedicated",
            10 => "tvOS",
            11 => "PlayStation",
            12 => "Nintendo Switch",
            13 => "Xbox",
            14 => "Windows Phone",
            else => "Unknown",
        };
    }
};
