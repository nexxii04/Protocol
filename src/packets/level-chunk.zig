const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Packet = @import("../root.zig").Packet;
const DimensionType = @import("../enums/dimension-type.zig").DimensionType;

pub const LevelChunk = struct {
    const MAX_BLOB_HASHES = 64;

    x: i32,
    z: i32,
    dimension: DimensionType,
    sub_chunk_count: u32,
    client_request_subchunk_limit: ?i32 = null,
    cache_enabled: bool,
    blobs: []const u64,
    data: []const u8,
    client_biome_update: bool = false,

    pub fn serialize(self: *LevelChunk, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.LevelChunk);
        try stream.writeZigZag(self.x);
        try stream.writeZigZag(self.z);
        try stream.writeZigZag(@intFromEnum(self.dimension));
        try stream.writeVarInt(self.sub_chunk_count);

        if (self.client_request_subchunk_limit) |limit| {
            try stream.writeBool(true);
            try stream.writeZigZag(limit);
        } else {
            try stream.writeBool(false);
        }

        try stream.writeBool(self.cache_enabled);

        try stream.writeVarInt(@intCast(self.blobs.len));
        for (self.blobs) |hash| {
            try stream.writeUint64(hash, .Little);
        }

        try stream.writeVarInt(@intCast(self.data.len));
        try stream.write(self.data);
        try stream.writeBool(self.client_biome_update);

        return stream.getBuffer();
    }

    pub fn deserialize(stream: *BinaryStream) !LevelChunk {
        _ = try stream.readVarInt();
        const x = try stream.readZigZag();
        const z = try stream.readZigZag();
        const dimension_raw = try stream.readZigZag();
        const dimension: DimensionType = @enumFromInt(dimension_raw);

        const sub_chunk_count = try stream.readVarInt();

        var client_request_limit: ?i32 = null;
        if (try stream.readBool()) {
            client_request_limit = try stream.readZigZag();
        }

        const cache_enabled = try stream.readBool();

        var blobs: []const u64 = &[_]u64{};
        const blob_count = try stream.readVarInt();
        if (blob_count > MAX_BLOB_HASHES) {
            return error.TooManyBlobHashes;
        }
        if (blob_count > 0) {
            const blob_array = try stream.allocator.alloc(u64, @intCast(blob_count));
            for (0..@intCast(blob_count)) |i| {
                blob_array[i] = try stream.readUint64(.Little);
            }
            blobs = blob_array;
        }

        const data_length = try stream.readVarInt();
        const data = stream.read(@intCast(data_length));
        const client_biome_update = try stream.readBool();

        return LevelChunk{
            .x = x,
            .z = z,
            .dimension = dimension,
            .sub_chunk_count = sub_chunk_count,
            .client_request_subchunk_limit = client_request_limit,
            .cache_enabled = cache_enabled,
            .blobs = blobs,
            .data = data,
            .client_biome_update = client_biome_update,
        };
    }
};
