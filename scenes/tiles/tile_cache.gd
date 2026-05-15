extends Tile
class_name TileCache

static var _cache_targets: TileTargetDef

@onready var rift = $Stretcher3D/RiftFX

var _point_source := PointSource.new()

static func _static_init() -> void:
  _cache_targets = load("res://data/targets/tile_target_surrounding.tres").duplicate()
  _cache_targets.include_self = true

func _ready() -> void:
  super._ready()
  
  _point_source.target = 20
  var ctx := EffectContext.new()
  ctx.tile = self
  _setup_move_bind(ctx)
  
  var points = _cache_targets.get_target(ctx)
  var lifetime := BasicCommand.from(
    func():
      for target: Vector3i in points:
        var mod := GridManager.inst.get_mods_at_point(target)
        mod.point_source_override = _point_source
        GridManager.inst.upgrade_grid_context(target, mod),
    func():
      for target: Vector3i in points:
        var mod := GridManager.inst.get_mods_at_point(target)
        if mod.point_source_override == _point_source:
          mod.point_source_override = null 
          GridManager.inst.upgrade_grid_context(target, mod)
  )
  lifetime.execute()
  register_bind_command(TileBind.LIFETIME, lifetime)

  def = TileDef.new()
  def.name = "Rift"
    
  var src_effect := TileEffectDestroyIfPointSatisfied.new()
  src_effect.pt_source = _point_source
  src_effect.event = TileEffect.Event.CUSTOM
  src_effect.main_target = _cache_targets
    
  var give_tile_effect := TileEffectGiveTile.new()
  give_tile_effect.def = AllTileContainer.inst.resources.filter(func(target_def: TileDef): return target_def.in_shop).pick_random()
  give_tile_effect.event = TileEffect.Event.ON_DESTROY
    
  _effects.push_back(src_effect)
  _effects.push_back(give_tile_effect)
  
func _setup_move_bind(ctx: EffectContext):
  var points = _cache_targets.get_target(ctx)
  var binding := BasicCommand.from(
    func(): pass,
    func():
      for target: Vector3i in points:
        var mod := GridManager.inst.get_mods_at_point(target)
        if mod.point_source_override == _point_source:
          mod.point_source_override = null 
          GridManager.inst.upgrade_grid_context(target, mod)
      _setup_move_bind(ctx),
  )
  
  register_bind_command(TileBind.POSITION, binding)
  binding.execute() 

func get_tile_name() -> String:
  return "An Ominous Rift"

func _load_def():
  pass

func _process(delta: float) -> void:
  _point_source.target_point = global_position
  var dir = stretcher.global_position.direction_to(get_viewport().get_camera_3d().global_position)
  var rot = atan2(dir.x, dir.z)
  stretcher.global_rotation = Vector3.UP*(rot+(PI*0.5))
  if _point_source.current >= _point_source.target:
    destroy()
