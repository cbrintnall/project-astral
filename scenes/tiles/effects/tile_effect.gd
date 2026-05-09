@abstract
extends Node3D
class_name TileEffect

@abstract func get_description(effect_ctx: EffectContext, exec_ctx: ExecutionContext) -> String
@abstract func execute(effect_ctx: EffectContext, exec_ctx: ExecutionContext)
