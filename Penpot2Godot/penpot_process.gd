@tool
extends Control

var script_dir:String = get_script().get_path().get_base_dir()

@export_global_file("*.penpot") var penpot_file
@export_global_dir var unzip_target
@export_tool_button("Extract Penpot") var unzip_button = extract_all_from_zip
@export_dir var fonts_folder
@export_dir var images_folder : 
	set(value):
		images_folder = value
		if images_folder == null || images_folder == "" || images_folder == " ":
			autoPlaceImages = false
		else: 
			autoPlaceImages = true
		notify_property_list_changed()
## Select or deselect if you want the importer to automatically import images.
@export var autoPlaceImages:bool = false
@export_tool_button("Process Penpot") var processBtn = dir_contents_trigger
@export var SelectPage : String : set = changePageSelect
@export var SelectBoard : String :
	set(value):
		SelectBoard = value
		if SelectBoard != "" && SelectBoard != "Select Board" && tool_ready:
			board_id_to_proc = strip_to_id(SelectBoard)
		notify_property_list_changed()
@export_tool_button("Import Board") var importBoardBtn = process_board_from_button

var page_hints:String
var frame_hints:String
var pen_file_id:String
var tool_ready:bool = false
var board_id_to_proc:String
var name_dictionary:Dictionary
var parent_dictionary:Dictionary
var lineage_dictionary:Dictionary
var auto_layout_check:Dictionary
var main_parent_pos:Vector2 = Vector2(0.0,0.0)

func _ready() -> void:
	pass
	SelectBoard = ""
	SelectPage = ""
	tool_ready = true

func _validate_property(property : Dictionary) -> void:
	if property.name == &"SelectPage":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = page_hints
	if property.name == &"SelectBoard":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = frame_hints
		

func process_board_from_button():
	process_object(board_id_to_proc,true)

func process_object(the_board_id,position_override:bool):
	pass
	var the_page_id = strip_to_id(SelectPage)
	var path = unzip_target + "/files/" + pen_file_id + "/pages/" + the_page_id + "/" + the_board_id + ".json"
	var data_file = FileAccess.open(path, FileAccess.READ)
	var data_parsed = JSON.parse_string(data_file.get_as_text())
	var parent_cycle:String = ""
	var parent_lineage:String = ""
	#print(data_parsed["name"] + ": " + data_parsed["id"])
	name_dictionary[data_parsed["id"]] = data_parsed["name"]
	parent_dictionary[data_parsed["id"]] = data_parsed["parentId"]
	parent_cycle = data_parsed["parentId"]
	while parent_cycle != "00000000-0000-0000-0000-000000000000":
		parent_lineage = parent_cycle + "/InnerContainer/" + parent_lineage
		parent_cycle = parent_dictionary[parent_cycle]
	if parent_lineage != "":
		parent_lineage = parent_lineage.erase(parent_lineage.length()-1,1)
	lineage_dictionary[data_parsed["id"]] = parent_lineage
	var make_min_size:bool = false
	var process_forward:bool = true
	if data_parsed.has("layout") && (data_parsed["layout"] == "grid" || data_parsed["layout"] == "flex"):
		auto_layout_check[data_parsed["id"]] = true
		process_forward = false
	if auto_layout_check.has(data_parsed["parentId"]):
		make_min_size = auto_layout_check[data_parsed["parentId"]]
	match data_parsed["type"]:
		"frame", "rect":
			render_frame(data_parsed,parent_lineage,position_override,make_min_size)
			if data_parsed.has("shapes"):
				var shape_array = data_parsed["shapes"]
				if shape_array != null && shape_array.size() > 0:
					if process_forward:
						for the_count in shape_array:
							process_object(the_count,false)
					else:
						var the_count = shape_array.size()
						while the_count > 0:
							the_count -= 1
							process_object(shape_array[the_count],false)
		"text":
			render_text_frame(data_parsed,parent_lineage,position_override,make_min_size)
		"path":
			print("PATH")

func render_frame(data_parsed,the_parent,position_override:bool,set_min_sizes:bool):
	pass
	var newFrame
	newFrame = DesignerFrame.new()
	#newFrame.name = data_parsed["name"]+" xIDx"+ data_parsed["id"]+"x"
	newFrame.name = data_parsed["id"]
	if the_parent != null && the_parent != "":
		var parent = get_node(the_parent)
		parent.add_child(newFrame)
	else:
		add_child(newFrame)
	newFrame.set_owner(get_tree().get_edited_scene_root())
	newFrame.use_solid_fill = false
	newFrame.scrollingMode = "None"
	var newControl = Control.new()
	newControl.name = "InnerContainer"
	newFrame.add_child(newControl)
	newFrame.inner_container = newControl.get_path()
	newFrame.get_node(newFrame.inner_container).set_owner(get_tree().get_edited_scene_root())
	newFrame.get_node(newFrame.inner_container).size_flags_vertical = Control.SIZE_EXPAND_FILL
	newFrame.get_node(newFrame.inner_container).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	newFrame.the_id = data_parsed["id"]
	newFrame.set_deferred("center_rotation", true)
	if data_parsed.has("layoutItemHSizing"):
		newFrame.widthSizeMode = data_parsed["layoutItemHSizing"]
	if data_parsed.has("layoutItemVSizing"):
		newFrame.heightSizeMode = data_parsed["layoutItemVSizing"]
	if set_min_sizes:
		newFrame.minSize.x = data_parsed["width"]
		newFrame.minSize.y = data_parsed["height"]
	newFrame.set_deferred("size", Vector2(data_parsed["width"],data_parsed["height"]))
	if position_override:
		newFrame.set_deferred("global_position", Vector2(0.0,0.0))
		main_parent_pos = Vector2(data_parsed["x"],data_parsed["y"])
	else:
		newFrame.set_deferred("global_position", Vector2(data_parsed["x"] - main_parent_pos.x, data_parsed["y"] - main_parent_pos.y))
	newFrame.set_deferred("rotation_degrees", data_parsed["rotation"] * 1)
	if data_parsed.has("constraintsH"):
		match data_parsed["constraintsH"]:
			"left":
				newFrame.set_deferred("horizontalAnchor","Left")
			"right":
				newFrame.set_deferred("horizontalAnchor","Right")
			"leftright":
				newFrame.set_deferred("horizontalAnchor","Left and Right")
			"center":
				newFrame.set_deferred("horizontalAnchor","Center")
			"scale":
				newFrame.set_deferred("horizontalAnchor","Scale")
	if data_parsed.has("constraintsV"):
		match data_parsed["constraintsV"]:
			"top":
				newFrame.set_deferred("verticalAnchor","Top")
			"bottom":
				newFrame.set_deferred("verticalAnchor","Bottom")
			"topbottom":
				newFrame.set_deferred("verticalAnchor","Top and Bottom")
			"center":
				newFrame.set_deferred("verticalAnchor","Center")
			"scale":
				newFrame.set_deferred("verticalAnchor","Scale")
	if data_parsed.has("fills"):
		newFrame.fill_color = Color(0,0,0,0)
		for cur_fill in data_parsed["fills"]:
			if cur_fill.has("fillColor") && cur_fill.has("fillOpacity"):
				newFrame.fill_color = Color(Color.html(cur_fill["fillColor"]),cur_fill["fillOpacity"])
				newFrame.use_solid_fill = true
			if cur_fill.has("fillImage"):
				var image_texture_id = cur_fill["fillImage"]["id"]
				var image_json = unzip_target + "/files/" + pen_file_id + "/media/" + image_texture_id +".json"
				var the_image_file = find_image_from_json(image_json)
				var image_texture = load(unzip_target + "/objects/" + the_image_file) as Texture
				newFrame.fill_texture =  image_texture
			if cur_fill.has("fillColorGradient"):
				var gradient = Gradient.new()
				for color_stop in cur_fill["fillColorGradient"]["stops"]:
					gradient.add_point(color_stop["offset"], Color(Color.html(color_stop["color"]), color_stop["opacity"]))
				gradient.remove_point(1)
				gradient.remove_point(0)
				var gradient_texture = GradientTexture2D.new()
				gradient_texture.gradient = gradient
				match cur_fill["fillColorGradient"]["type"]:
					"linear":
						gradient_texture.fill = GradientTexture2D.FILL_LINEAR
					"radial":
						gradient_texture.fill = GradientTexture2D.FILL_RADIAL
				gradient_texture.width = 64
				gradient_texture.height = 64
				gradient_texture.fill_from = Vector2(cur_fill["fillColorGradient"]["startX"],cur_fill["fillColorGradient"]["startY"])
				gradient_texture.fill_to = Vector2(cur_fill["fillColorGradient"]["endX"],cur_fill["fillColorGradient"]["endY"])
				newFrame.fill_gradient = gradient_texture
	if data_parsed.has("strokes"):
		if data_parsed["strokes"].size() > 0:
			newFrame.border_color = Color(Color.html(data_parsed["strokes"][0]["strokeColor"]),data_parsed["strokes"][0]["strokeOpacity"])
			newFrame.border_weights = [data_parsed["strokes"][0]["strokeWidth"],data_parsed["strokes"][0]["strokeWidth"],data_parsed["strokes"][0]["strokeWidth"],data_parsed["strokes"][0]["strokeWidth"]]
			newFrame.border_align = data_parsed["strokes"][0]["strokeAlignment"]
	newFrame.corner_radius = [data_parsed["r1"],data_parsed["r2"],data_parsed["r3"],data_parsed["r4"]]
	if data_parsed.has("layoutPadding"):
		newFrame.padding = [data_parsed["layoutPadding"]["p1"],data_parsed["layoutPadding"]["p2"],data_parsed["layoutPadding"]["p3"],data_parsed["layoutPadding"]["p4"]]
	if data_parsed.has("layout"):
		match data_parsed["layout"]:
			"flex":
				pass
				match data_parsed["layoutFlexDir"]:
					"row":
						newFrame.layoutMode = "HORIZONTAL"
					"column":
						newFrame.layoutMode = "VERTICAL"
				match data_parsed["layoutWrapType"]:
					"nowrap":
						newFrame.layoutWrap = "NO_WRAP"
					"wrap":
						newFrame.layoutWrap = "WRAP"
				newFrame.spacing = data_parsed["layoutGap"]["columnGap"]
				newFrame.secondary_spacing = data_parsed["layoutGap"]["rowGap"]
				match data_parsed["layoutAlignContent"]:
					"start":
						newFrame.set_deferred("hLayoutAlign", "Left")
					"center":
						newFrame.set_deferred("hLayoutAlign", "Center")
					"end":
						newFrame.set_deferred("hLayoutAlign", "Right")
				match data_parsed["layoutJustifyContent"]:
					"start":
						newFrame.set_deferred("vLayoutAlign", "Top")
					"end":
						newFrame.set_deferred("vLayoutAlign", "Bottom")
					"center":
						newFrame.set_deferred("vLayoutAlign", "Center")
			"grid":
				newFrame.layoutMode = "GRID"
				newFrame.spacing = data_parsed["layoutGap"]["columnGap"]
				newFrame.secondary_spacing = data_parsed["layoutGap"]["rowGap"]
				newFrame.grid_columns = data_parsed["layoutGridColumns"].size()
	if data_parsed.has("showContent"):
			newFrame.clipFrameContents = !data_parsed["showContent"]
	else:
		newFrame.clipFrameContents = false

func find_image_from_json(path):
	var data_file = FileAccess.open(path, FileAccess.READ)
	var data_parsed = JSON.parse_string(data_file.get_as_text())
	var file_type:String
	var file_name:String 
	if data_parsed.has("mtype"):
		file_type = String(data_parsed["mtype"]).right(3)
	if data_parsed.has("mediaId"):
		file_name = data_parsed["mediaId"]
	var full_file_name:String = file_name + "." + file_type
	return full_file_name
	
func render_text_frame(data_parsed,the_parent,position_override:bool,set_min_sizes:bool):
	var newFrame = Label.new()
	var newLabelSettings = LabelSettings.new()

	if fonts_folder != null and fonts_folder != "":
		var dynamic_font = FontFile.new()
		var font_name = str(data_parsed["positionData"][0]["fontFamily"]).replace(" ", "")
		var font_weight = str(data_parsed["positionData"][0]["fontWeight"]).replace(" ", "")
		var font_style = str(data_parsed["positionData"][0]["fontStyle"]).replace(" ", "")
		match font_weight:
			"100":
				font_weight = "Thin"
			"200":
				font_weight = "ExtraLight"
			"300":
				font_weight = "Light"
			"400":
				font_weight = "Regular"
			"500":
				font_weight = "Medium"
			"600":
				font_weight = "SemiBold"
			"700":
				font_weight = "Bold"
			"800":
				font_weight = "ExtraBold"
			"900":
				font_weight = "Black"
		match font_style:
			"italic":
				font_style = "Italic"
			_:
				font_style = ""
		var font_style_transformed:String = font_weight + font_style
		var font_location:String = fonts_folder + "/" + font_name + "-" + font_style_transformed + ".ttf"
		if FileAccess.file_exists(font_location):
			newLabelSettings.font = load(font_location)
	if data_parsed.has("constraintsH"):
		set_anchor_horizontal(data_parsed["constraintsH"],newFrame)
	if data_parsed.has("constraintsV"):
		set_anchor_vertical(data_parsed["constraintsV"],newFrame)
	var font_size_change = data_parsed["positionData"][0]["fontSize"]
	font_size_change = font_size_change.substr(0, font_size_change.length() - 2)
	newLabelSettings.font_size = int(font_size_change)
	if data_parsed.has("content") && data_parsed["content"].has("children") and data_parsed["content"]["children"].size() > 0 && data_parsed["content"]["children"][0].has("children") && data_parsed["content"]["children"][0]["children"].size() > 0 && data_parsed["content"]["children"][0]["children"][0].has("lineHeight"):
		newLabelSettings.line_spacing =  float(font_size_change) - (float(font_size_change) * float(data_parsed["content"]["children"][0]["children"][0]["lineHeight"]))
	else:
		newLabelSettings.line_spacing = 0
	if data_parsed["positionData"][0].has("fills"):
		newLabelSettings.font_color = Color(Color.html(data_parsed["positionData"][0]["fills"][0]["fillColor"]),data_parsed["positionData"][0]["fills"][0]["fillOpacity"])
	newFrame.name = data_parsed["id"]  #xIDx"+ make_safeName(p_id)+"x"
	var parent = get_node(the_parent)
	parent.add_child(newFrame)
	newFrame.set_label_settings(newLabelSettings)
	newFrame.set_owner(get_tree().get_edited_scene_root())
	newFrame.set_deferred("size", Vector2(data_parsed["width"],data_parsed["height"]))
	newFrame.set_deferred("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	#if data_parsed.has("content") && data_parsed["content"].has("children") and data_parsed["content"]["children"].size() > 0 && data_parsed["content"]["children"][0].has("children") && data_parsed["content"]["children"][0]["children"].size() > 0 && data_parsed["content"]["children"][0]["children"][0].has("children") && data_parsed["content"]["children"][0]["children"][0]["children"].size() > 0 && data_parsed["content"]["children"][0]["children"][0]["children"][0].has("text"):
		#newFrame.set_deferred("text",data_parsed["content"]["children"][0]["children"][0]["children"][0]["text"])
	var temp_text:String
	if data_parsed.has("positionData"):
		for pdat in data_parsed["positionData"]:
			temp_text += pdat["text"]
	newFrame.set_deferred("text",temp_text)
	#else:
		#newFrame.text = data_parsed["positionData"][0]["text"]
	if position_override:
		newFrame.set_deferred("global_position", Vector2(0.0,0.0))
		main_parent_pos = Vector2(data_parsed["x"],data_parsed["y"])
	else:
		newFrame.set_deferred("global_position", Vector2(data_parsed["x"] - main_parent_pos.x, data_parsed["y"] - main_parent_pos.y))
	newFrame.set_deferred("pivot_offset", Vector2(data_parsed["width"] / 2, data_parsed["height"] / 2))
	newFrame.set_deferred("rotation_degrees", data_parsed["rotation"] * 1)
	if data_parsed.has("content") && data_parsed["content"].has("children") and data_parsed["content"]["children"].size() > 0 && data_parsed["content"]["children"][0].has("children") && data_parsed["content"]["children"][0]["children"].size() > 0 && data_parsed["content"]["children"][0]["children"][0].has("textAlign"):
		update_textHAlign(data_parsed["content"]["children"][0]["children"][0]["textAlign"],newFrame)
	if data_parsed.has("content") && data_parsed["content"].has("verticalAlign"):
		update_textVAlign(data_parsed["content"]["verticalAlign"],newFrame)
	newFrame.custom_minimum_size = Vector2(data_parsed["width"],data_parsed["height"])
	if data_parsed.has("layoutItemHSizing"):
		set_textwSize(data_parsed["layoutItemHSizing"],newFrame,data_parsed["width"])
	if data_parsed.has("layoutItemVSizing"):
		set_texthSize(data_parsed["layoutItemVSizing"],newFrame,data_parsed["height"])

func update_textHAlign(_theVar,theNode):
	match _theVar:
		"left":
			theNode.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		"center":
			theNode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		"right":
			theNode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func update_textVAlign(_theVar,theNode):
	match _theVar:
		"top":
			theNode.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		"center":
			theNode.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		"bottom":
			theNode.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

func set_textwSize(widthSizeMode,theNode,theNodeWidth)->void:
	match widthSizeMode:
		"auto":
			theNode.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			theNode.size.x = 0.0
		"fix":
			theNode.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			theNode.custom_minimum_size.x = theNodeWidth
		"fill":
			theNode.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_texthSize(heightSizeMode,theNode,theNodeHeight)->void:
	match heightSizeMode:
		"auto":
			theNode.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			theNode.size.y = 0.0
		"fix":
			theNode.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			theNode.custom_minimum_size.y = theNodeHeight
		"fill":
			theNode.size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_anchor_horizontal(horizontalAnchor:String,theNode)->void:
	var my_width = theNode.size.x
	var myHpos = theNode.position.x
	match horizontalAnchor:
		"left":
			theNode.anchor_left = 0.0
			theNode.anchor_right = 0.0
			theNode.position.x = myHpos
			theNode.size.x = my_width
		"center":
			theNode.anchor_left = 0.5
			theNode.anchor_right = 0.5
			theNode.position.x = myHpos
			theNode.size.x = my_width
		"right":
			theNode.anchor_left = 1.0
			theNode.anchor_right = 1.0
			theNode.position.x = myHpos
			theNode.size.x = my_width
		"leftright":
			theNode.anchor_left = 0.0
			theNode.anchor_right = 1.0
			theNode.position.x = myHpos
			theNode.size.x = my_width
			theNode.grow_horizontal = Control.GROW_DIRECTION_BOTH
		"scale":
			pass
			#need object bounds
			
func set_anchor_vertical(verticalAnchor:String,theNode)->void:
	var my_height = theNode.size.y
	var myVpos = theNode.position.y
	match verticalAnchor:
		"top":
			theNode.anchor_top = 0.0
			theNode.anchor_bottom = 0.0
			theNode.position.y = myVpos
			theNode.size.y = my_height
		"center":
			theNode.anchor_top = 0.5
			theNode.anchor_bottom = 0.5
			theNode.position.y = myVpos
			theNode.size.y = my_height
		"bottom":
			theNode.anchor_top = 1.0
			theNode.anchor_bottom = 1.0
			theNode.position.y = myVpos
			theNode.size.y = my_height
		"topbottom":
			theNode.anchor_top = 0.0
			theNode.anchor_bottom = 1.0
			theNode.position.y = myVpos
			theNode.size.y = my_height
			theNode.grow_vertical = Control.GROW_DIRECTION_BOTH
		"scale":
			pass
			#need object bounds
# Extract all files from a ZIP archive, preserving the directories within.
# This acts like the "Extract all" functionality from most archive managers.
func extract_all_from_zip():
	var reader = ZIPReader.new()
	if penpot_file == null:
		print("no file")
		return
	reader.open(penpot_file)
	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction!
	if unzip_target == null:
		print("no extract directory")
		return
	var root_dir = DirAccess.open(unzip_target)

	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue
		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)
	EditorInterface.get_resource_filesystem().scan()
	print("Extraction Complete")

func dir_contents_trigger():
	dir_contents(unzip_target)

func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
				#print("Found directory: " + file_name)
			else:
				#print("Found file: " + file_name)
				if file_name == "manifest.json":
					#Load the file.
					var the_file_loc = path + "/" + file_name
					var data_file = FileAccess.open(the_file_loc, FileAccess.READ)
					#Parse the json file.
					var data_parsed = JSON.parse_string(data_file.get_as_text())
					process_manifest(data_parsed)
					return
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func process_manifest(json_data):
	page_hints = "Select Page,"
	SelectPage = "Select Page"
	pen_file_id = json_data["files"][0]["id"]
	var path = unzip_target + "/files/" + pen_file_id + "/pages"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
				#print("Found directory: " + file_name)
			else:
				if file_name.ends_with(".json"):
					var page_json = path + "/" + file_name
					get_page_id(page_json)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func get_page_id(json_data):
	var data_file = FileAccess.open(json_data, FileAccess.READ)
	var data_parsed = JSON.parse_string(data_file.get_as_text())
	page_hints += data_parsed["name"]+" ----- xIDx"+data_parsed["id"]+"x,"
	notify_property_list_changed()

func changePageSelect(_stuff):
	SelectPage = _stuff
	if SelectPage != "Select Page" && SelectPage != "":
		var the_page_id = strip_to_id(SelectPage)
		frame_hints = "Select Board,"
		SelectBoard = "Select Board"
		if tool_ready:
			loadPageShapes(the_page_id)
	notify_property_list_changed()

func loadPageShapes(page_id):
	pass
	var path = unzip_target + "/files/" + pen_file_id + "/pages/" + page_id
	var data_file = FileAccess.open(path + "/00000000-0000-0000-0000-000000000000.json", FileAccess.READ)
	var data_parsed = JSON.parse_string(data_file.get_as_text())
	var shape_array:Array = data_parsed["shapes"]
	for the_id in shape_array.size():
		var shape_data_file = FileAccess.open(path + "/" + shape_array[the_id] + ".json", FileAccess.READ)
		var shape_data_parsed = JSON.parse_string(shape_data_file.get_as_text())
		frame_hints += shape_data_parsed["name"]+" ----- xIDx"+shape_data_parsed["id"]+"x,"

func strip_to_id(input_string:String):
	var start_pos = input_string.find("xIDx") + 4 
	var end_pos = input_string.rfind("x") 
	if start_pos < end_pos: 
		return input_string.substr(start_pos, end_pos - start_pos) 
	else:
		print("no id")
