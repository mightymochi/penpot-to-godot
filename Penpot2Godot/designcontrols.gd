extends Control
class_name UIDesignTools

#var script_dir:String = get_script().get_path().get_base_dir()
#const frameShaderPath:String = "res://shader/vertextApplyShader.gdshader"

static func center_the_rotation_s(theNode:Control, is_scene_ready:bool, center_rotation:bool)->void:
	if is_scene_ready:
		var cur_pos = theNode.position
		var cur_offset = theNode.pivot_offset
		var global_position_before = theNode.global_position 
		if (center_rotation == true):
			theNode.pivot_offset.x = theNode.size.x / 2
			theNode.pivot_offset.y = theNode.size.y / 2
			var new_pivot_offset = theNode.pivot_offset
			var local_offset_change = (new_pivot_offset - cur_offset).rotated(theNode.rotation) 
			theNode.position -= local_offset_change 
			theNode.global_position = global_position_before
		else:
			theNode.pivot_offset.x = 0.0
			theNode.pivot_offset.y = 0.0
			var new_pivot_offset = theNode.pivot_offset
			var local_offset_change = (new_pivot_offset - cur_offset).rotated(theNode.rotation) 
			theNode.position += local_offset_change 
			theNode.global_position = global_position_before

static func centerOnResize(theNode:Control, center_rotation:bool)->void:
	if center_rotation:
		theNode.pivot_offset.x = theNode.size.x / 2
		theNode.pivot_offset.y = theNode.size.y / 2

static func restrictMaxSize(theNode:Control, maxSize:Vector2)->void:
	if theNode.size.x > maxSize.x && maxSize.x != null :
		theNode.size.x = maxSize.x
	if theNode.size.y > maxSize.y && maxSize.y != null :
		theNode.size.y = maxSize.y
	
static func shaderNameMatches(theNode:Control,frameShaderPath:String)->bool:
	var shader_material = theNode.material
	if shader_material and shader_material is ShaderMaterial:
		var shader = shader_material.shader
		if shader:
			var shader_path = shader.resource_path
			if shader_path == frameShaderPath:
				return true
			else:
				return false
		else:
			return false
	else:
		return false

static func set_background_gradient(theNode:Control,is_scene_ready:bool,fill_gradient,frameShaderPath:String)->void:
	if is_scene_ready:
		if fill_gradient == null:
			pass
			if shaderNameMatches(theNode,frameShaderPath):
				theNode.material.set_shader_parameter("use_gradient", false)
				if theNode.fill_texture == null: 
					theNode.material = null
					theNode.styleBox.set("bg_color", theNode.fill_color)
					theNode.add_theme_stylebox_override("panel", theNode.styleBox)
			theNode.use_solid_fill = true
			theNode.notify_property_list_changed()
		elif !shaderNameMatches(theNode,frameShaderPath):
			var imageShader = load(frameShaderPath)
			var shader_material = ShaderMaterial.new()
			shader_material.shader = imageShader
			theNode.material = shader_material
			bgGradientActivate(theNode,fill_gradient)
		elif shaderNameMatches(theNode,frameShaderPath):
			bgGradientActivate(theNode,fill_gradient)
		
static func bgGradientActivate(theNode:Control,fill_gradient)->void:
	theNode.material.set_shader_parameter("gradient_texture", fill_gradient)
	theNode.material.set_shader_parameter("use_gradient", true)
	theNode.styleBox.set("bg_color", Color(0.6,0.6,0.6,1.0))
	theNode.material.set_shader_parameter("new_bg_color", theNode.fill_color)
	theNode.add_theme_stylebox_override("panel", theNode.styleBox)
	theNode.use_solid_fill = false
	theNode.notify_property_list_changed()

static func set_background_image(theNode:Control,is_scene_ready:bool,fill_texture:Texture,frameShaderPath:String)->void:
	if is_scene_ready:
		if fill_texture == null:
			if shaderNameMatches(theNode,frameShaderPath):
				theNode.material.set_shader_parameter("use_image", false)
				if theNode.fill_gradient == null: 
					theNode.material = null
					theNode.styleBox.set("bg_color", theNode.fill_color)
					theNode.add_theme_stylebox_override("panel", theNode.styleBox)
			resetTextureDefaults(theNode)
			theNode.notify_property_list_changed()
		elif !shaderNameMatches(theNode,frameShaderPath):
			var imageShader = load(frameShaderPath)
			var shader_material = ShaderMaterial.new()
			shader_material.shader = imageShader
			theNode.material = shader_material
			bgImageActivate(theNode,fill_texture)
		elif shaderNameMatches(theNode,frameShaderPath):
			bgImageActivate(theNode,fill_texture)

static func bgImageActivate(theNode:Control,fill_texture:Texture)->void:
	theNode.material.set_shader_parameter("image_texture", fill_texture)
	theNode.material.set_shader_parameter("use_image", true)
	theNode.material.set_shader_parameter("node_size", Vector2(theNode.size))
	theNode.material.set_shader_parameter("texture_size", fill_texture.get_size())
	theNode.styleBox.set("bg_color", Color(0.6,0.6,0.6,1.0))
	theNode.material.set_shader_parameter("new_bg_color", theNode.fill_color)
	theNode.add_theme_stylebox_override("panel", theNode.styleBox)
	theNode.use_solid_fill = theNode.use_solid_fill
	theNode.notify_property_list_changed()
	
static func resetTextureDefaults(theNode:Control)->void:
	theNode.textureSizeMode = "Fill"
	theNode.flip_x = false
	theNode.flip_y = false
	theNode.zoom = 1.0
	theNode.tile_texture = false
	theNode.size_stretch = Vector2(1.0,1.0)
	theNode.position_offset = Vector2(0.0,0.0)
	theNode.tint_color = Color(1.0,1.0,1.0,1.0)

static func set_image_sizing(theNode:Control,textureSizeMode:String,frameShaderPath:String)->void:
	if theNode.fill_texture != null && shaderNameMatches(theNode,frameShaderPath):
		match textureSizeMode:
			"Fill":
				theNode.zoom = 1.0
				theNode.size_stretch = Vector2(1.0,1.0)
				theNode.position_offset = Vector2(0.0,0.0)
				theNode.material.set_shader_parameter("keep_aspect", true)
				theNode.material.set_shader_parameter("fill_rect", true)
				theNode.material.set_shader_parameter("manual_scale", false)
			"Fit":
				theNode.zoom = 1.0
				theNode.size_stretch = Vector2(1.0,1.0)
				theNode.position_offset = Vector2(0.0,0.0)
				theNode.material.set_shader_parameter("keep_aspect", true)
				theNode.material.set_shader_parameter("fill_rect", false)
				theNode.material.set_shader_parameter("manual_scale", false)
			"Stretch":
				theNode.zoom = 1.0
				theNode.size_stretch = Vector2(1.0,1.0)
				theNode.position_offset = Vector2(0.0,0.0)
				theNode.material.set_shader_parameter("keep_aspect", false)
				theNode.material.set_shader_parameter("fill_rect", false)
				theNode.material.set_shader_parameter("manual_scale", false)
			"Keep Size":
				theNode.material.set_shader_parameter("keep_aspect", true)
				theNode.material.set_shader_parameter("fill_rect", false)
				theNode.material.set_shader_parameter("manual_scale", true)

static func break_the_style_link(theNode:Control,frameShaderPath:String)->void:
	theNode.styleBox = theNode.get_theme_stylebox("panel").duplicate()
	if shaderNameMatches(theNode,frameShaderPath):
		theNode.material = theNode.material.duplicate()
	if theNode.fill_gradient != null:
		theNode.fill_gradient = theNode.fill_gradient.duplicate()

static func set_wSizing(theNode:Control,is_scene_ready:bool,widthSizeMode:String)->void:
	if is_scene_ready:
		match widthSizeMode:
			"HUG", "auto":
				theNode.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				if theNode is ScrollContainer:
					theNode.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				theNode.minSize.x = 0.0
				theNode.size.x = 0.0
			"FIXED", "fix":
				theNode.minSize.x = theNode.size.x
				theNode.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				if theNode is ScrollContainer:
					set_scrolling(theNode,is_scene_ready,theNode.scrollingMode)
			"FILL", "fill":
				theNode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
static func set_hSizing(theNode:Control,is_scene_ready:bool,heightSizeMode:String)->void:
	if is_scene_ready:
		match heightSizeMode:
			"HUG", "auto":
				theNode.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				if theNode is ScrollContainer:
					theNode.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				theNode.minSize.y = 0.0
				theNode.size.y = 0.0
			"FIXED", "fix":
				theNode.minSize.y = theNode.size.y
				theNode.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				if theNode is ScrollContainer:
					set_scrolling(theNode,is_scene_ready,theNode.scrollingMode)
			"FILL", "fill":
				theNode.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
static func set_scrolling(theNode:Control,is_scene_ready:bool,scrollingMode:String):
	if is_scene_ready:
		match scrollingMode:
			"None":
				if theNode.widthSizeMode != "HUG":
					theNode.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
				if theNode.heightSizeMode != "HUG":
					theNode.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
			"Horizontal":
				if theNode.widthSizeMode != "HUG":
					theNode.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
				if theNode.heightSizeMode != "HUG":
					theNode.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
			"Vertical":
				if theNode.widthSizeMode != "HUG":
					theNode.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
				if theNode.heightSizeMode != "HUG":
					theNode.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			"Both":
				if theNode.widthSizeMode != "HUG":
					theNode.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
				if theNode.heightSizeMode != "HUG":
					theNode.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

static func set_anchor_horizontal(theNode:Control,is_scene_ready:bool,horizontalAnchor:String):
	if is_scene_ready:
		var my_width = theNode.size.x
		var myHpos = theNode.position.x
		match horizontalAnchor:
			"Left":
				theNode.anchor_left = 0.0
				theNode.anchor_right = 0.0
				theNode.position.x = myHpos
				theNode.size.x = my_width
			"Center":
				theNode.anchor_left = 0.5
				theNode.anchor_right = 0.5
				theNode.position.x = myHpos
				theNode.size.x = my_width
			"Right":
				theNode.anchor_left = 1.0
				theNode.anchor_right = 1.0
				theNode.position.x = myHpos
				theNode.size.x = my_width
			"Left and Right":
				theNode.anchor_left = 0.0
				theNode.anchor_right = 1.0
				theNode.position.x = myHpos
				theNode.size.x = my_width
				theNode.grow_horizontal = Control.GROW_DIRECTION_BOTH
			"Scale":
				pass
				#need object bounds
			
static func set_anchor_vertical(theNode:Control,is_scene_ready:bool,verticalAnchor:String):
	if is_scene_ready:
		var my_height = theNode.size.y
		var myVpos = theNode.position.y
		match verticalAnchor:
			"Top":
				theNode.anchor_top = 0.0
				theNode.anchor_bottom = 0.0
				theNode.position.y = myVpos
				theNode.size.y = my_height
			"Center":
				theNode.anchor_top = 0.5
				theNode.anchor_bottom = 0.5
				theNode.position.y = myVpos
				theNode.size.y = my_height
			"Bottom":
				theNode.anchor_top = 1.0
				theNode.anchor_bottom = 1.0
				theNode.position.y = myVpos
				theNode.size.y = my_height
			"Top and Bottom":
				theNode.anchor_top = 0.0
				theNode.anchor_bottom = 1.0
				theNode.position.y = myVpos
				theNode.size.y = my_height
				theNode.grow_vertical = Control.GROW_DIRECTION_BOTH
			"Scale":
				pass

static func change_layout(theNode:Control,inner_container:NodePath)->void:
	if !theNode.is_scene_ready:
		return
	if theNode.layoutWrap == "NO_WRAP":
		match theNode.layoutMode:
			"NONE":
				var ControlClass = Control.new()
				ControlClass.name = theNode.get_node(inner_container).name
				ControlClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				ControlClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(ControlClass, true)
			"VERTICAL":
				var VBoxClass = VBoxContainer.new()
				VBoxClass.name = theNode.get_node(inner_container).name
				VBoxClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				VBoxClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(VBoxClass, true)
			"HORIZONTAL":
				var HBoxClass = HBoxContainer.new()
				HBoxClass.name = theNode.get_node(inner_container).name
				HBoxClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				HBoxClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(HBoxClass, true)
			"GRID":
				var GBoxClass = GridContainer.new()
				GBoxClass.name = theNode.get_node(inner_container).name
				GBoxClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				GBoxClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(GBoxClass, true)
				set_grid_col(theNode,theNode.grid_columns,inner_container)
		change_child_layouts(theNode,inner_container)
	elif theNode.layoutWrap == "WRAP":
		match theNode.layoutMode:
			"NONE":
				theNode.layoutMode = "HORIZONTAL"
			"VERTICAL":
				var VFlowClass = VFlowContainer.new()
				VFlowClass.name = theNode.get_node(inner_container).name
				VFlowClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				VFlowClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(VFlowClass, true)
			"HORIZONTAL":
				var HFlowClass = HFlowContainer.new()
				HFlowClass.name = theNode.get_node(inner_container).name
				HFlowClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				HFlowClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(HFlowClass, true)
			"GRID":
				var GBoxClass = GridContainer.new()
				GBoxClass.name = theNode.get_node(inner_container).name
				GBoxClass.size_flags_vertical = Control.SIZE_EXPAND_FILL
				GBoxClass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				theNode.get_node(inner_container).replace_by(GBoxClass, true)
				set_grid_col(theNode,theNode.grid_columns,inner_container)
	container_align_adjust(theNode,inner_container)
	update_gap_space(theNode,inner_container)
	theNode.notify_property_list_changed()

static func change_child_layouts(theNode:Control,inner_container:NodePath)->void:
	for c_node in theNode.get_node(inner_container).get_children():
		if c_node.get("layoutMode") != null:
			pass
			#print(layoutMode + " : " + c_node.name)
		elif c_node.get("layout_mode") != null:
			match theNode.layoutMode:
				"NONE":
					#c_node.layout_mode = 1
					c_node.size = c_node.custom_minimum_size
					c_node.anchor_left = 0.0
					c_node.anchor_right = 0.0
					c_node.anchor_top = 0.0
					c_node.anchor_bottom = 0.0
				"VERTICAL":
					c_node.layout_mode = 2
				"HORIZONTAL":
					c_node.layout_mode = 2
				"GRID":
					c_node.layout_mode = 2
	container_align_adjust(theNode,inner_container)
	children_valign_adjust(theNode,inner_container)
	children_halign_adjust(theNode,inner_container)
	update_gap_space(theNode,inner_container)

static func set_grid_col(theNode:Control,grid_columns:int,inner_container:NodePath):
	if theNode.layoutMode == "GRID":
		theNode.get_node(inner_container).columns = grid_columns

static func update_gap_space(theNode:Control,inner_container:NodePath)->void:
	if !theNode.is_scene_ready:
		return
	if (theNode.layoutWrap == "NO_WRAP" && theNode.layoutMode == "HORIZONTAL") || (theNode.layoutWrap == "NO_WRAP" && theNode.layoutMode == "VERTICAL"):
		if theNode.autoSpace:
			theNode.get_node(inner_container).add_theme_constant_override("separation", 0)
			var the_total:int = theNode.get_node(inner_container).get_child_count()
			var the_count:int = 0
			for c_node in theNode.get_node(inner_container).get_children():
				the_count += 1
				if the_count < the_total:
					match theNode.layoutMode:
						"VERTICAL":
							c_node.size_flags_vertical = Control.SIZE_EXPAND
						"HORIZONTAL":
							c_node.size_flags_horizontal = Control.SIZE_EXPAND
		else:
			children_valign_adjust(theNode,inner_container)
			children_halign_adjust(theNode,inner_container)
			theNode.get_node(inner_container).add_theme_constant_override("separation", theNode.spacing)
	elif theNode.layoutWrap == "WRAP" || theNode.layoutMode == "GRID":
		theNode.get_node(inner_container).add_theme_constant_override("h_separation", theNode.spacing)
		theNode.get_node(inner_container).add_theme_constant_override("v_separation", theNode.secondary_spacing)

static func container_align_adjust(theNode:Control,inner_container:NodePath)->void:
	if !theNode.is_scene_ready:
		return
	var the_container = theNode.get_node(inner_container)
	match theNode.layoutMode:
		"VERTICAL":
			if the_container.is_class("VFlowContainer"):
				match theNode.hLayoutAlign:
					"Left":
						the_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
					"Center":
						the_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
					"Right":
						the_container.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
			match theNode.vLayoutAlign:
				"Top":
					the_container.alignment = BoxContainer.AlignmentMode.ALIGNMENT_BEGIN
				"Center":
					the_container.alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER
				"Bottom":
						the_container.alignment = BoxContainer.AlignmentMode.ALIGNMENT_END
		"HORIZONTAL":
			if the_container.is_class("HFlowContainer"):
				match theNode.vLayoutAlign:
					"Top":
						the_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN | Control.SIZE_EXPAND
					"Center":
						the_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
					"Bottom":
						the_container.size_flags_vertical = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
			match theNode.hLayoutAlign:
				"Left":
					the_container.alignment = BoxContainer.AlignmentMode.ALIGNMENT_BEGIN
				"Center":
					the_container.alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER
				"Right":
					the_container.alignment = BoxContainer.AlignmentMode.ALIGNMENT_END

static func children_halign_adjust(theNode:Control,inner_container:NodePath)->void:
	if !theNode.is_scene_ready:
		return
	for c_node in theNode.get_node(inner_container).get_children():
		if c_node.size_flags_horizontal != Control.SIZE_FILL && c_node.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
			match theNode.layoutMode:
				"VERTICAL":
					match theNode.hLayoutAlign:
						"Left":
							c_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						"Center":
							c_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
						"Right":
							c_node.size_flags_horizontal = Control.SIZE_SHRINK_END
				"HORIZONTAL":
					match theNode.vLayoutAlign:
						"Top":
							c_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						"Center":
							c_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
						"Bottom":
							c_node.size_flags_horizontal = Control.SIZE_SHRINK_END
						
static func children_valign_adjust(theNode:Control,inner_container:NodePath)->void:
	if !theNode.is_scene_ready:
		return
	for c_node in theNode.get_node(inner_container).get_children():
		if c_node.size_flags_vertical != Control.SIZE_FILL && c_node.size_flags_vertical != Control.SIZE_EXPAND_FILL:
			match theNode.layoutMode:
				"VERTICAL":
					match theNode.hLayoutAlign:
						"Left":
							c_node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
						"Center":
							c_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
						"Right":
							c_node.size_flags_vertical = Control.SIZE_SHRINK_END
				"HORIZONTAL":
					match theNode.vLayoutAlign:
						"Top":
							c_node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
						"Center":
							c_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
						"Bottom":
							c_node.size_flags_vertical = Control.SIZE_SHRINK_END
