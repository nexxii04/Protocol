const std = @import("std");

const BinaryStream = @import("BinaryStream").BinaryStream;
const NBT = @import("nbt");

const Difficulty = @import("../enums/difficulty.zig").Difficulty;
const Gamemode = @import("../enums/gamemode.zig").Gamemode;
const PermissionLevel = @import("../enums/permission-level.zig").PermissionLevel;
const Packet = @import("../root.zig").Packet;
const BlockPosition = @import("../types/block-position.zig").BlockPosition;
const Experiments = @import("../types/experiments.zig").Experiments;
const GameRules = @import("../types/game-rules.zig").GameRules;
const NetworkBlockTypeDefinition = @import("../types/network-block-type-definition.zig").NetworkBlockTypeDefinition;
const ServerTelemetryData = @import("../types/server-telemetry-data.zig").ServerTelemetryData;
const Uuid = @import("../types/uuid.zig").Uuid;
const Vector3f = @import("../types/vector3f.zig").Vector3f;

pub const StartGamePacket = struct {
    entity_id: i64,
    runtime_entity_id: u64,
    player_gamemode: Gamemode,
    player_position: Vector3f,
    pitch: f32,
    yaw: f32,
    seed: u64,
    biome_type: i16,
    biome_name: []const u8,
    dimension: i32,
    generator: i32,
    world_gamemode: Gamemode,
    hardcore: bool,
    difficulty: Difficulty,
    spawn_position: BlockPosition,
    achievements_disabled: bool,
    editor_world_type: i32,
    created_in_editor: bool,
    exported_from_editor: bool,
    editor_level_migration_version: i8 = 0,
    day_cycle_stop_time: i32,
    edu_offer: i32,
    edu_features: bool,
    edu_product_uuid: []const u8,
    rain_level: f32,
    lightning_level: f32,
    confirmed_platform_locked_content: bool,
    multiplayer_game: bool,
    broadcast_to_lan: bool,
    xbl_broadcast_mode: i32,
    platform_broadcast_mode: i32,
    commands_enabled: bool,
    texture_packs_required: bool,
    gamerules: []GameRules,
    experiments: []Experiments,
    experiments_previously_toggled: bool,
    bonus_chest: bool,
    map_enabled: bool,
    permission_level: PermissionLevel,
    server_chunk_tick_range: i32,
    has_locked_behavior_pack: bool,
    has_locked_resource_pack: bool,
    is_from_locked_world_template: bool,
    use_msa_gamertags_only: bool,
    is_from_world_template: bool,
    is_world_template_option_locked: bool,
    only_spawn_v1_villagers: bool,
    persona_disabled: bool,
    custom_skins_disabled: bool,
    emote_chat_muted: bool,
    game_version: []const u8,
    limited_world_width: i32,
    limited_world_length: i32,
    is_new_nether: bool,
    edu_resource_uri_button_name: []const u8,
    edu_resource_uri_link: []const u8,
    experimental_gameplay_override: ?bool = null,
    chat_restriction_level: u8,
    disable_player_interactions: bool,
    server_editor_connection_policy: i32,
    allow_anonimous_block_drops_in_editor_worlds: bool,
    level_identifier: []const u8,
    level_name: []const u8,
    premium_world_template_id: []const u8,
    is_trial: bool,
    rewind_history_size: i32,
    server_authoritative_block_breaking: bool,
    current_tick: u64,
    enchantment_seed: i32,
    block_type_definitions: []const NetworkBlockTypeDefinition,
    multiplayer_correlation_id: []const u8,
    server_authoritative_inventory: bool,
    engine: []const u8,
    properties: NBT.Tag,
    block_palette_checksum: u64,
    world_template_id: []const u8,
    client_side_generation: bool,
    block_network_ids_are_hashes: bool,
    server_controlled_sounds: bool,
    contains_server_join_info: bool,
    server_telemetry_data: ServerTelemetryData,

    pub fn serialize(self: *StartGamePacket, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.StartGame);

        try stream.writeZigZong(self.entity_id);
        try stream.writeVarLong(self.runtime_entity_id);
        try stream.writeZigZag(@intFromEnum(self.player_gamemode));
        try Vector3f.write(stream, self.player_position);
        try stream.writeFloat32(self.pitch, .Little);
        try stream.writeFloat32(self.yaw, .Little);
        try stream.writeInt64(@bitCast(self.seed), .Little);
        try stream.writeInt16(self.biome_type, .Little);
        try stream.writeVarString(self.biome_name);
        try stream.writeZigZag(self.dimension);
        try stream.writeZigZag(self.generator);
        try stream.writeZigZag(@intFromEnum(self.world_gamemode));
        try stream.writeBool(self.hardcore);
        try stream.writeZigZag(@intFromEnum(self.difficulty));
        try BlockPosition.write(stream, self.spawn_position);
        try stream.writeBool(self.achievements_disabled);
        try stream.writeZigZag(self.editor_world_type);
        try stream.writeBool(self.created_in_editor);
        try stream.writeBool(self.exported_from_editor);
        try stream.writeInt8(self.editor_level_migration_version);
        try stream.writeZigZag(self.day_cycle_stop_time);
        try stream.writeZigZag(self.edu_offer);
        try stream.writeBool(self.edu_features);
        try stream.writeVarString(self.edu_product_uuid);
        try stream.writeFloat32(self.rain_level, .Little);
        try stream.writeFloat32(self.lightning_level, .Little);
        try stream.writeBool(self.confirmed_platform_locked_content);
        try stream.writeBool(self.multiplayer_game);
        try stream.writeBool(self.broadcast_to_lan);
        try stream.writeZigZag(self.xbl_broadcast_mode);
        try stream.writeZigZag(self.platform_broadcast_mode);
        try stream.writeBool(self.commands_enabled);
        try stream.writeBool(self.texture_packs_required);
        try GameRules.write(stream, self.gamerules);
        try Experiments.write(stream, self.experiments);
        try stream.writeBool(self.experiments_previously_toggled);
        try stream.writeBool(self.bonus_chest);
        try stream.writeBool(self.map_enabled);
        try stream.writeUint8(@intCast(@intFromEnum(self.permission_level)));
        try stream.writeInt32(self.server_chunk_tick_range, .Little);
        try stream.writeBool(self.has_locked_behavior_pack);
        try stream.writeBool(self.has_locked_resource_pack);
        try stream.writeBool(self.is_from_locked_world_template);
        try stream.writeBool(self.use_msa_gamertags_only);
        try stream.writeBool(self.is_from_world_template);
        try stream.writeBool(self.is_world_template_option_locked);
        try stream.writeBool(self.only_spawn_v1_villagers);
        try stream.writeBool(self.persona_disabled);
        try stream.writeBool(self.custom_skins_disabled);
        try stream.writeBool(self.emote_chat_muted);
        try stream.writeVarString(self.game_version);
        try stream.writeInt32(self.limited_world_width, .Little);
        try stream.writeInt32(self.limited_world_length, .Little);
        try stream.writeBool(self.is_new_nether);
        try stream.writeVarString(self.edu_resource_uri_button_name);
        try stream.writeVarString(self.edu_resource_uri_link);
        if (self.experimental_gameplay_override) |override| {
            try stream.writeBool(true);
            try stream.writeBool(override);
        } else {
            try stream.writeBool(false);
        }
        try stream.writeInt8(@bitCast(self.chat_restriction_level));
        try stream.writeBool(self.disable_player_interactions);
        try stream.writeZigZag(self.server_editor_connection_policy);
        try stream.writeBool(self.allow_anonimous_block_drops_in_editor_worlds);
        try stream.writeVarString(self.level_identifier);
        try stream.writeVarString(self.level_name);
        try stream.writeVarString(self.premium_world_template_id);
        try stream.writeBool(self.is_trial);
        try stream.writeZigZag(self.rewind_history_size);
        try stream.writeBool(self.server_authoritative_block_breaking);
        try stream.writeInt64(@bitCast(self.current_tick), .Little);
        try stream.writeZigZag(self.enchantment_seed);
        try NetworkBlockTypeDefinition.write(stream, self.block_type_definitions);
        try stream.writeVarString(self.multiplayer_correlation_id);
        try stream.writeBool(self.server_authoritative_inventory);
        try stream.writeVarString(self.engine);

        try self.properties.write(stream, .{ .varint = true });

        try stream.writeInt64(@bitCast(self.block_palette_checksum), .Little);
        try Uuid.write(stream, self.world_template_id);
        try stream.writeBool(self.client_side_generation);
        try stream.writeBool(self.block_network_ids_are_hashes);
        try stream.writeBool(self.server_controlled_sounds);
        if (self.contains_server_join_info) {
            // NOOP
            return error.UnsupportedServerJoinInfo;
        }
        try stream.writeBool(false);
        try ServerTelemetryData.write(stream, self.server_telemetry_data);

        return stream.getBuffer();
    }

    pub fn deserialize(stream: *BinaryStream) !StartGamePacket {
        _ = try stream.readVarInt();

        const entity_id = try stream.readZigZong();
        const runtime_entity_id: u64 = @intCast(try stream.readVarLong());
        const player_gamemode: Gamemode = @enumFromInt(try stream.readZigZag());
        const player_position = try Vector3f.read(stream);
        const pitch = try stream.readFloat32(.Little);
        const yaw = try stream.readFloat32(.Little);
        const seed: u64 = @bitCast(try stream.readInt64(.Little));
        const biome_type = try stream.readInt16(.Little);
        const biome_name = try stream.readVarString();
        const dimension = try stream.readZigZag();
        const generator = try stream.readZigZag();
        const world_gamemode: Gamemode = @enumFromInt(try stream.readZigZag());
        const hardcore = try stream.readBool();
        const difficulty: Difficulty = @enumFromInt(try stream.readZigZag());
        const spawn_position = try BlockPosition.read(stream);
        const achievements_disabled = try stream.readBool();
        const editor_world_type = try stream.readZigZag();
        const created_in_editor = try stream.readBool();
        const exported_from_editor = try stream.readBool();
        const editor_level_migration_version = try stream.readInt8();
        const day_cycle_stop_time = try stream.readZigZag();
        const edu_offer = try stream.readVarInt();
        const edu_features = try stream.readBool();
        const edu_product_uuid = try stream.readVarString();
        const rain_level = try stream.readFloat32(.Little);
        const lightning_level = try stream.readFloat32(.Little);
        const confirmed_platform_locked_content = try stream.readBool();
        const multiplayer_game = try stream.readBool();
        const broadcast_to_lan = try stream.readBool();
        const xbl_broadcast_mode: u32 = @intCast(try stream.readVarInt());
        const platform_broadcast_mode: u32 = @intCast(try stream.readVarInt());
        const commands_enabled = try stream.readBool();
        const texture_packs_required = try stream.readBool();
        const gamerules = try GameRules.read(stream);
        const experiments = try Experiments.read(stream);
        const experiments_previously_toggled = try stream.readBool();
        const bonus_chest = try stream.readBool();
        const map_enabled = try stream.readBool();
        const permission_level: PermissionLevel = @enumFromInt(try stream.readUint8());
        const server_chunk_tick_range = try stream.readInt32(.Little);
        const has_locked_behavior_pack = try stream.readBool();
        const has_locked_resource_pack = try stream.readBool();
        const is_from_locked_world_template = try stream.readBool();
        const use_msa_gamertags_only = try stream.readBool();
        const is_from_world_template = try stream.readBool();
        const is_world_template_option_locked = try stream.readBool();
        const only_spawn_v1_villagers = try stream.readBool();
        const persona_disabled = try stream.readBool();
        const custom_skins_disabled = try stream.readBool();
        const emote_chat_muted = try stream.readBool();
        const game_version = try stream.readVarString();
        const limited_world_width = try stream.readInt32(.Little);
        const limited_world_length = try stream.readInt32(.Little);
        const is_new_nether = try stream.readBool();
        const edu_resource_uri_button_name = try stream.readVarString();
        const edu_resource_uri_link = try stream.readVarString();
        const experimental_gameplay_override: ?bool = if (try stream.readBool())
            try stream.readBool()
        else
            null;
        const chat_restriction_level: u8 = @bitCast(try stream.readInt8());
        const disable_player_interactions = try stream.readBool();
        const server_editor_connection_policy = try stream.readZigZag();
        const allow_anonimous_block_drops_in_editor_worlds = try stream.readBool();
        const level_identifier = try stream.readVarString();
        const level_name = try stream.readVarString();
        const premium_world_template_id = try stream.readVarString();
        const is_trial = try stream.readBool();
        const rewind_history_size = try stream.readZigZag();
        const server_authoritative_block_breaking = try stream.readBool();
        const current_tick: u64 = @bitCast(try stream.readInt64(.Little));
        const enchantment_seed = try stream.readZigZag();
        const block_type_definitions = try NetworkBlockTypeDefinition.read(stream);
        const multiplayer_correlation_id = try stream.readVarString();
        const server_authoritative_inventory = try stream.readBool();
        const engine = try stream.readVarString();

        const properties = try NBT.Tag.read(stream, stream.allocator, .{ .varint = true });

        const block_palette_checksum: u64 = @bitCast(try stream.readInt64(.Little));
        const world_template_id = try Uuid.read(stream);
        const client_side_generation = try stream.readBool();
        const block_network_ids_are_hashes = try stream.readBool();
        const server_controlled_sounds = try stream.readBool();
        const contains_server_join_info = try stream.readBool();
        const server_telemetry_data = try ServerTelemetryData.read(stream);

        return StartGamePacket{
            .entity_id = entity_id,
            .runtime_entity_id = runtime_entity_id,
            .player_gamemode = player_gamemode,
            .player_position = player_position,
            .pitch = pitch,
            .yaw = yaw,
            .seed = seed,
            .biome_type = biome_type,
            .biome_name = biome_name,
            .dimension = dimension,
            .generator = generator,
            .world_gamemode = world_gamemode,
            .hardcore = hardcore,
            .difficulty = difficulty,
            .spawn_position = spawn_position,
            .achievements_disabled = achievements_disabled,
            .editor_world_type = editor_world_type,
            .created_in_editor = created_in_editor,
            .exported_from_editor = exported_from_editor,
            .editor_level_migration_version = editor_level_migration_version,
            .day_cycle_stop_time = day_cycle_stop_time,
            .edu_offer = edu_offer,
            .edu_features = edu_features,
            .edu_product_uuid = edu_product_uuid,
            .rain_level = rain_level,
            .lightning_level = lightning_level,
            .confirmed_platform_locked_content = confirmed_platform_locked_content,
            .multiplayer_game = multiplayer_game,
            .broadcast_to_lan = broadcast_to_lan,
            .xbl_broadcast_mode = xbl_broadcast_mode,
            .platform_broadcast_mode = platform_broadcast_mode,
            .commands_enabled = commands_enabled,
            .texture_packs_required = texture_packs_required,
            .gamerules = gamerules,
            .experiments = experiments,
            .experiments_previously_toggled = experiments_previously_toggled,
            .bonus_chest = bonus_chest,
            .map_enabled = map_enabled,
            .permission_level = permission_level,
            .server_chunk_tick_range = server_chunk_tick_range,
            .has_locked_behavior_pack = has_locked_behavior_pack,
            .has_locked_resource_pack = has_locked_resource_pack,
            .is_from_locked_world_template = is_from_locked_world_template,
            .use_msa_gamertags_only = use_msa_gamertags_only,
            .is_from_world_template = is_from_world_template,
            .is_world_template_option_locked = is_world_template_option_locked,
            .only_spawn_v1_villagers = only_spawn_v1_villagers,
            .persona_disabled = persona_disabled,
            .custom_skins_disabled = custom_skins_disabled,
            .emote_chat_muted = emote_chat_muted,
            .game_version = game_version,
            .limited_world_width = limited_world_width,
            .limited_world_length = limited_world_length,
            .is_new_nether = is_new_nether,
            .edu_resource_uri_button_name = edu_resource_uri_button_name,
            .edu_resource_uri_link = edu_resource_uri_link,
            .experimental_gameplay_override = experimental_gameplay_override,
            .chat_restriction_level = chat_restriction_level,
            .disable_player_interactions = disable_player_interactions,
            .server_editor_connection_policy = server_editor_connection_policy,
            .allow_anonimous_block_drops_in_editor_worlds = allow_anonimous_block_drops_in_editor_worlds,
            .level_identifier = level_identifier,
            .level_name = level_name,
            .premium_world_template_id = premium_world_template_id,
            .is_trial = is_trial,
            .rewind_history_size = rewind_history_size,
            .server_authoritative_block_breaking = server_authoritative_block_breaking,
            .current_tick = current_tick,
            .enchantment_seed = enchantment_seed,
            .block_type_definitions = block_type_definitions,
            .multiplayer_correlation_id = multiplayer_correlation_id,
            .server_authoritative_inventory = server_authoritative_inventory,
            .engine = engine,
            .properties = properties,
            .block_palette_checksum = block_palette_checksum,
            .world_template_id = world_template_id,
            .client_side_generation = client_side_generation,
            .block_network_ids_are_hashes = block_network_ids_are_hashes,
            .server_controlled_sounds = server_controlled_sounds,
            .contains_server_join_info = contains_server_join_info,
            .server_telemetry_data = server_telemetry_data,
        };
    }

    pub fn deinit(self: *StartGamePacket, allocator: std.mem.Allocator) void {
        for (self.gamerules) |*rule| {
            rule.deinit(allocator);
        }
        allocator.free(self.gamerules);

        for (self.experiments) |*experiment| {
            experiment.deinit(allocator);
        }
        allocator.free(self.experiments);

        for (self.block_type_definitions) |definition| {
            definition.deinit(allocator);
        }
        allocator.free(self.block_type_definitions);

        self.properties.deinit(allocator);
        self.server_telemetry_data.deinit(allocator);
    }
};
