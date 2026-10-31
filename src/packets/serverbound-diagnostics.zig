const std = @import("std");

const BinaryStream = @import("BinaryStream").BinaryStream;

const Packet = @import("../enums/packet.zig").Packet;

pub const EntityDiagnosticTimingInfo = struct {
    display_name: []const u8 = "",
    entity: []const u8 = "",
    time_in_ns: i64 = 0,
    percent_of_total: u8 = 0,
    position_x: f32 = 0,
    position_y: f32 = 0,
    position_z: f32 = 0,
    dimension: []const u8 = "",

    pub fn write(stream: *BinaryStream, value: EntityDiagnosticTimingInfo) !void {
        try stream.writeVarString(value.display_name);
        try stream.writeVarString(value.entity);
        try stream.writeInt64(value.time_in_ns, .Little);
        try stream.writeUint8(value.percent_of_total);
        try stream.writeFloat32(value.position_x, .Little);
        try stream.writeFloat32(value.position_y, .Little);
        try stream.writeFloat32(value.position_z, .Little);
        try stream.writeVarString(value.dimension);
    }
};

pub const SystemDiagnosticTimingInfo = struct {
    display_name: []const u8 = "",
    system_index: i64 = 0,
    time_in_ns: i64 = 0,
    percent_of_total: u8 = 0,

    pub fn write(stream: *BinaryStream, value: SystemDiagnosticTimingInfo) !void {
        try stream.writeVarString(value.display_name);
        try stream.writeInt64(value.system_index, .Little);
        try stream.writeInt64(value.time_in_ns, .Little);
        try stream.writeUint8(value.percent_of_total);
    }
};

pub const SystemCategory = struct {
    category_name: []const u8 = "",
    system_index: i64 = 0,

    pub fn write(stream: *BinaryStream, value: SystemCategory) !void {
        try stream.writeVarString(value.category_name);
        try stream.writeInt64(value.system_index, .Little);
    }
};

pub const WhiskerScopeDataSummary = struct {
    label: []const u8 = "",
    indentation: []const u8 = "",
    total_high_cost_ns: i64 = 0,
    total_mid_cost_ns: i64 = 0,
    total_low_cost_ns: i64 = 0,

    pub fn write(stream: *BinaryStream, value: WhiskerScopeDataSummary) !void {
        try stream.writeVarString(value.label);
        try stream.writeVarString(value.indentation);
        try stream.writeInt64(value.total_high_cost_ns, .Little);
        try stream.writeInt64(value.total_mid_cost_ns, .Little);
        try stream.writeInt64(value.total_low_cost_ns, .Little);
    }
};

pub const MemoryCategoryCounter = struct {
    category: u8 = 0,
    bytes: u64 = 0,

    pub fn write(stream: *BinaryStream, value: MemoryCategoryCounter) !void {
        try stream.writeUint8(value.category);
        try stream.writeInt64(@bitCast(value.bytes), .Little);
    }
};

pub const ServerboundDiagnosticsPacket = struct {
    avg_fps: f32 = 0,
    avg_server_sim_tick_time_ms: f32 = 0,
    avg_client_sim_tick_time_ms: f32 = 0,
    avg_begin_frame_time_ms: f32 = 0,
    avg_input_time_ms: f32 = 0,
    avg_render_time_ms: f32 = 0,
    avg_end_frame_time_ms: f32 = 0,
    avg_remainder_time_percent: f32 = 0,
    avg_unaccounted_time_percent: f32 = 0,
    memory_category_values: []const MemoryCategoryCounter = &.{},
    entity_diagnostics: []const EntityDiagnosticTimingInfo = &.{},
    system_diagnostics: []const SystemDiagnosticTimingInfo = &.{},
    system_categories: ?[]const SystemCategory = null,
    whisker_scopes: []const WhiskerScopeDataSummary = &.{},

    pub fn serialize(self: *const ServerboundDiagnosticsPacket, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.ServerboundDiagnosticPacket);

        try stream.writeFloat32(self.avg_fps, .Little);
        try stream.writeFloat32(self.avg_server_sim_tick_time_ms, .Little);
        try stream.writeFloat32(self.avg_client_sim_tick_time_ms, .Little);
        try stream.writeFloat32(self.avg_begin_frame_time_ms, .Little);
        try stream.writeFloat32(self.avg_input_time_ms, .Little);
        try stream.writeFloat32(self.avg_render_time_ms, .Little);
        try stream.writeFloat32(self.avg_end_frame_time_ms, .Little);
        try stream.writeFloat32(self.avg_remainder_time_percent, .Little);
        try stream.writeFloat32(self.avg_unaccounted_time_percent, .Little);

        try stream.writeVarInt(@intCast(self.memory_category_values.len));
        for (self.memory_category_values) |mc| {
            try MemoryCategoryCounter.write(stream, mc);
        }

        try stream.writeVarInt(@intCast(self.entity_diagnostics.len));
        for (self.entity_diagnostics) |ed| {
            try EntityDiagnosticTimingInfo.write(stream, ed);
        }

        try stream.writeVarInt(@intCast(self.system_diagnostics.len));
        for (self.system_diagnostics) |sd| {
            try SystemDiagnosticTimingInfo.write(stream, sd);
        }

        if (self.system_categories) |categories| {
            try stream.writeBool(true);
            try stream.writeVarInt(@intCast(categories.len));
            for (categories) |sc| {
                try SystemCategory.write(stream, sc);
            }
        } else {
            try stream.writeBool(false);
        }

        try stream.writeVarInt(@intCast(self.whisker_scopes.len));
        for (self.whisker_scopes) |ws| {
            try WhiskerScopeDataSummary.write(stream, ws);
        }

        return stream.getBuffer();
    }

    pub fn deserialize(stream: *BinaryStream, allocator: std.mem.Allocator) !ServerboundDiagnosticsPacket {
        _ = try stream.readVarInt();

        var packet = ServerboundDiagnosticsPacket{};
        packet.avg_fps = try stream.readFloat32(.Little);
        packet.avg_server_sim_tick_time_ms = try stream.readFloat32(.Little);
        packet.avg_client_sim_tick_time_ms = try stream.readFloat32(.Little);
        packet.avg_begin_frame_time_ms = try stream.readFloat32(.Little);
        packet.avg_input_time_ms = try stream.readFloat32(.Little);
        packet.avg_render_time_ms = try stream.readFloat32(.Little);
        packet.avg_end_frame_time_ms = try stream.readFloat32(.Little);
        packet.avg_remainder_time_percent = try stream.readFloat32(.Little);
        packet.avg_unaccounted_time_percent = try stream.readFloat32(.Little);

        const memory_count = try stream.readVarInt();
        const memory_category_values = try allocator.alloc(MemoryCategoryCounter, @intCast(memory_count));
        for (0..@intCast(memory_count)) |i| {
            memory_category_values[i] = .{
                .category = try stream.readUint8(),
                .bytes = @bitCast(try stream.readInt64(.Little)),
            };
        }
        packet.memory_category_values = memory_category_values;

        const entity_count = try stream.readVarInt();
        const entity_diagnostics = try allocator.alloc(EntityDiagnosticTimingInfo, @intCast(entity_count));
        for (0..@intCast(entity_count)) |i| {
            entity_diagnostics[i] = .{
                .display_name = try stream.readVarString(),
                .entity = try stream.readVarString(),
                .time_in_ns = try stream.readInt64(.Little),
                .percent_of_total = try stream.readUint8(),
                .position_x = try stream.readFloat32(.Little),
                .position_y = try stream.readFloat32(.Little),
                .position_z = try stream.readFloat32(.Little),
                .dimension = try stream.readVarString(),
            };
        }
        packet.entity_diagnostics = entity_diagnostics;

        const system_count = try stream.readVarInt();
        const system_diagnostics = try allocator.alloc(SystemDiagnosticTimingInfo, @intCast(system_count));
        for (0..@intCast(system_count)) |i| {
            system_diagnostics[i] = .{
                .display_name = try stream.readVarString(),
                .system_index = try stream.readInt64(.Little),
                .time_in_ns = try stream.readInt64(.Little),
                .percent_of_total = try stream.readUint8(),
            };
        }
        packet.system_diagnostics = system_diagnostics;

        if (try stream.readBool()) {
            const category_count = try stream.readVarInt();
            const system_categories = try allocator.alloc(SystemCategory, @intCast(category_count));
            for (0..@intCast(category_count)) |i| {
                system_categories[i] = .{
                    .category_name = try stream.readVarString(),
                    .system_index = try stream.readInt64(.Little),
                };
            }
            packet.system_categories = system_categories;
        }

        const whisker_count = try stream.readVarInt();
        const whisker_scopes = try allocator.alloc(WhiskerScopeDataSummary, @intCast(whisker_count));
        for (0..@intCast(whisker_count)) |i| {
            whisker_scopes[i] = .{
                .label = try stream.readVarString(),
                .indentation = try stream.readVarString(),
                .total_high_cost_ns = try stream.readInt64(.Little),
                .total_mid_cost_ns = try stream.readInt64(.Little),
                .total_low_cost_ns = try stream.readInt64(.Little),
            };
        }
        packet.whisker_scopes = whisker_scopes;

        return packet;
    }

    pub fn deinit(self: *ServerboundDiagnosticsPacket, allocator: std.mem.Allocator) void {
        allocator.free(self.memory_category_values);
        allocator.free(self.entity_diagnostics);
        allocator.free(self.system_diagnostics);
        if (self.system_categories) |categories| allocator.free(categories);
        allocator.free(self.whisker_scopes);
    }
};
