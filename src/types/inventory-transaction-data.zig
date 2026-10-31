const Vector3f = @import("vector3f.zig").Vector3f;
const BlockPosition = @import("block-position.zig").BlockPosition;

pub const LegacySetItemSlot = struct {
    container_id: u8,
    slots: []const u8,
};

pub const InventoryAction = struct {
    source_type: u32,
    window_id: i32,
    source_flags: u32,
    inventory_slot: u32,
};

pub const NormalTransactionData = struct {
    is_drop: bool = false,
    drop_slot: u32 = 0,
    drop_count: u16 = 0,
};

pub const UseItemTransactionData = struct {
    action_type: i32,
    trigger_type: u32,
    block_position: BlockPosition,
    block_face: i32,
    hot_bar_slot: i32,
    hand: u8,
    position: Vector3f,
    clicked_position: Vector3f,
    block_runtime_id: u32,
    client_prediction: u32,
    client_cooldown_state: u32,
};

pub const UseItemOnEntityTransactionData = struct {
    target_entity_runtime_id: u64,
    action_type: i32,
    hot_bar_slot: i32,
    hand: u8,
    position: Vector3f,
    clicked_position: Vector3f,
};

pub const ReleaseItemTransactionData = struct {
    action_type: i32,
    hot_bar_slot: i32,
    head_position: Vector3f,
    hand: u8,
};

pub const TransactionData = union(enum) {
    normal: NormalTransactionData,
    mismatch: void,
    use_item: UseItemTransactionData,
    use_item_on_entity: UseItemOnEntityTransactionData,
    release_item: ReleaseItemTransactionData,
};
