extends Node2D

# --- 1. DATA ---
var ink_count = 200 
var stored_ink = 0.0      
var max_ink_capacity = 5000 

var tag_colors = {"Tide": "🌊 Tide", "Tremor": "🪨 Tremor", "Pyre": "🔥 Pyre", "Zephyr": "🌬️ Zephyr"}

var weighted_recipes = {
	"Tide Echo + Tremor Echo": {"The Shiver": 45, "The Faultline": 45, "The Silt": 5, "The Undertow": 5},
	"Tide Echo + Pyre Echo": {"Scalding Regret": 45, "Mist Echo": 45, "Searing Anguish": 5, "The Eruption": 5},
	"Tide Echo + Zephyr Echo": {"Drifting Ripple": 45, "Salted Whim": 45, "Hollow Current": 5, "The Maelstrom": 5},
	"Tremor Echo + Pyre Echo": {"Molten Core": 45, "Hardened Rage": 45, "Obsidian Heart": 5, "The Volcano": 5},
	"Tremor Echo + Zephyr Echo": {"The Haze": 45, "Fading Grits": 45, "Fossilized Sigh": 5, "The Echoing Void": 5},
	"Pyre Echo + Zephyr Echo": {"Flickering Whim": 45, "Breezy Passion": 45, "The Glaring Flash": 5, "The Radiant Collapse": 5}
}

var echo_database = {
	"Tide Echo": {"hp": 100, "atk": 5, "time": 5, "tags": ["Tide"], "ink_rate": 1, "color": Color.CORNFLOWER_BLUE, "lore": "Flowing subconscious."},
	"Tremor Echo": {"hp": 80, "atk": 8, "time": 5, "tags": ["Tremor"], "ink_rate": 1, "color": Color.GOLDENROD, "lore": "Unshakable memory."},
	"Pyre Echo": {"hp": 70, "atk": 12, "time": 5, "tags": ["Pyre"], "ink_rate": 1, "color": Color.ORANGE_RED, "lore": "Intense emotion."},
	"Zephyr Echo": {"hp": 90, "atk": 6, "time": 5, "tags": ["Zephyr"], "ink_rate": 2, "color": Color.LIGHT_CYAN, "lore": "Fleeting whimsy."},
	"The Shiver": {"hp": 130, "atk": 18, "time": 15, "tags": ["Tide", "Tremor"], "ink_rate": 5, "color": Color.AQUAMARINE, "lore": "Cold realization."},
	"The Faultline": {"hp": 160, "atk": 14, "time": 15, "tags": ["Tremor", "Tide"], "ink_rate": 5, "color": Color.CHOCOLATE, "lore": "Mental crack."},
	"The Silt": {"hp": 145, "atk": 16, "time": 25, "tags": ["Tide", "Tremor"], "ink_rate": 15, "color": Color.SLATE_GRAY, "lore": "RARE: Deep confusion."},
	"The Undertow": {"hp": 200, "atk": 30, "time": 30, "tags": ["Tide", "Tremor"], "ink_rate": 20, "color": Color.DARK_SLATE_BLUE, "lore": "RARE: Deep mind pull."},
	"Scalding Regret": {"hp": 110, "atk": 25, "time": 15, "tags": ["Tide", "Pyre"], "ink_rate": 6, "color": Color.INDIAN_RED, "lore": "Burning memory."},
	"Mist Echo": {"hp": 95, "atk": 30, "time": 15, "tags": ["Tide", "Pyre"], "ink_rate": 6, "color": Color.LIGHT_GRAY, "lore": "Hazy passion."},
	"Searing Anguish": {"hp": 250, "atk": 50, "time": 40, "tags": ["Tide", "Pyre"], "ink_rate": 25, "color": Color.ORCHID, "lore": "RARE: Loss manifestation."},
	"The Eruption": {"hp": 180, "atk": 40, "time": 40, "tags": ["Tide", "Pyre"], "ink_rate": 25, "color": Color.SKY_BLUE, "lore": "RARE: Breakthrough."},
	"Drifting Ripple": {"hp": 110, "atk": 12, "time": 15, "tags": ["Tide", "Zephyr"], "ink_rate": 7, "color": Color.AZURE, "lore": "Floating dream."},
	"Salted Whim": {"hp": 100, "atk": 15, "time": 15, "tags": ["Tide", "Zephyr"], "ink_rate": 7, "color": Color.LIGHT_BLUE, "lore": "Fleeting thought."},
	"Hollow Current": {"hp": 190, "atk": 28, "time": 35, "tags": ["Tide", "Zephyr"], "ink_rate": 22, "color": Color.DARK_CYAN, "lore": "RARE: Empty flow."},
	"The Maelstrom": {"hp": 150, "atk": 55, "time": 35, "tags": ["Tide", "Zephyr"], "ink_rate": 22, "color": Color.NAVY_BLUE, "lore": "RARE: Mental swirl."},
	"Molten Core": {"hp": 180, "atk": 25, "time": 20, "tags": ["Tremor", "Pyre"], "ink_rate": 8, "color": Color.DARK_ORANGE, "lore": "Burning trauma."},
	"Hardened Rage": {"hp": 220, "atk": 20, "time": 20, "tags": ["Tremor", "Pyre"], "ink_rate": 8, "color": Color.DARK_RED, "lore": "Solidified anger."},
	"Obsidian Heart": {"hp": 400, "atk": 45, "time": 45, "tags": ["Tremor", "Pyre"], "ink_rate": 30, "color": Color.BLACK, "lore": "RARE: Unbreakable wall."},
	"The Volcano": {"hp": 300, "atk": 85, "time": 45, "tags": ["Tremor", "Pyre"], "ink_rate": 30, "color": Color.ORANGE, "lore": "RARE: Massive outburst."},
	"The Haze": {"hp": 120, "atk": 15, "time": 15, "tags": ["Tremor", "Zephyr"], "ink_rate": 6, "color": Color.WHEAT, "lore": "Crumbling memory."},
	"Fading Grits": {"hp": 100, "atk": 18, "time": 15, "tags": ["Tremor", "Zephyr"], "ink_rate": 6, "color": Color.TAN, "lore": "Sand of a lost thought."},
	"Fossilized Sigh": {"hp": 240, "atk": 32, "time": 35, "tags": ["Tremor", "Zephyr"], "ink_rate": 24, "color": Color.SADDLE_BROWN, "lore": "RARE: Ancient regret."},
	"The Echoing Void": {"hp": 210, "atk": 40, "time": 35, "tags": ["Tremor", "Zephyr"], "ink_rate": 24, "color": Color.DIM_GRAY, "lore": "RARE: Sound of nothingness."},
	"Flickering Whim": {"hp": 90, "atk": 28, "time": 15, "tags": ["Pyre", "Zephyr"], "ink_rate": 7, "color": Color.CORAL, "lore": "Fast spark."},
	"Breezy Passion": {"hp": 100, "atk": 20, "time": 15, "tags": ["Pyre", "Zephyr"], "ink_rate": 7, "color": Color.LIGHT_STEEL_BLUE, "lore": "Light obsession."},
	"The Glaring Flash": {"hp": 300, "atk": 80, "time": 45, "tags": ["Pyre", "Zephyr"], "ink_rate": 40, "color": Color.GOLD, "lore": "RARE: Singular clarity."},
	"The Radiant Collapse": {"hp": 200, "atk": 110, "time": 45, "tags": ["Pyre", "Zephyr"], "ink_rate": 40, "color": Color.DEEP_PINK, "lore": "RARE: Bright dream."},
	"The Drowning Panic": {"hp": 450, "atk": 65, "time": 60, "tags": ["Tide", "Tremor"], "ink_rate": 45, "color": Color.DARK_MAGENTA, "lore": "Ultimate reverie."}
}

# --- 2. STATE ---
var hatchery_slots = [
	{"is_active": false, "finish_time": 0, "result": "", "total_time": 0},
	{"is_active": false, "finish_time": 0, "result": "", "total_time": 0},
	{"is_active": false, "finish_time": 0, "result": "", "total_time": 0}
]

var my_collection = []
var deployed_echoes = [] 
var discovered_echoes = ["Tide Echo", "Tremor Echo", "Pyre Echo", "Zephyr Echo"]
var max_board_size = 3
var parent_a_index = -1; var parent_b_index = -1; var last_clicked_index = -1 
var board_selected_index = -1; var codex_selected_index = -1
var boss_level = 1; var boss_hp = 150; var boss_atk = 15; var is_fighting = false

func _ready():
	randomize()
	my_collection = ["Tide Echo", "Tremor Echo", "Pyre Echo", "Zephyr Echo"]
	update_ui()

func get_base_name(full_name: String) -> String:
	return full_name.split(" (")[0]

# --- 3. THE JUICE ENGINE (MISSING FUNCTIONS RE-ADDED) ---

func spawn_damage_text(value: int, pos: Vector2, color: Color):
	var label = Label.new()
	label.text = str(value)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 32)
	add_child(label)
	label.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -60), 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)

func apply_shake(node: Node, intensity: float):
	if not node: return
	var original_pos = node.position
	var tween = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, 0.05)
	tween.tween_property(node, "position", original_pos, 0.05)

func flash_node(node: Node, color: Color):
	if not node: return
	var original_mod = node.modulate
	node.modulate = color
	create_tween().tween_property(node, "modulate", original_mod, 0.2)

# --- 4. UI ---

func update_ui():
	if is_fighting: return 
	if last_clicked_index >= my_collection.size(): last_clicked_index = -1
	if parent_a_index >= my_collection.size(): parent_a_index = -1
	if parent_b_index >= my_collection.size(): parent_b_index = -1
	
	%InkLabel.text = "Ink: " + str(int(ink_count))
	%CollectButton.text = "Collect (" + str(int(stored_ink)) + "/" + str(max_ink_capacity) + ")"
	%BossLabel.text = "🦑 INK-BEAST (Lv. " + str(boss_level) + ")\nHP: " + str(boss_hp) + " | ATK: " + str(boss_atk)
	
	%ItemList.clear()
	for item in my_collection: %ItemList.add_item(item)
	%BoardList.clear()
	for item in deployed_echoes: %BoardList.add_item(item)
	
	%CodexList.clear()
	var echo_names = echo_database.keys()
	for echo in echo_names: %CodexList.add_item(echo if echo in discovered_echoes else "???")
	
	var p1_n = my_collection[parent_a_index] if parent_a_index != -1 else "..."
	var p2_n = my_collection[parent_b_index] if parent_b_index != -1 else "..."
	%DetailsLabel.text = "Weaving Resonance:\n" + p1_n + " + " + p2_n
	
	if last_clicked_index != -1:
		var name_to_check = my_collection[last_clicked_index]
		var data = echo_database[get_base_name(name_to_check)] if echo_database.has(get_base_name(name_to_check)) else echo_database["Tide Echo"]
		%Portrait.color = data.color
		var tag_string = ""
		for t in data.tags: tag_string += tag_colors[t] + " "
		%StatsLabel.text = "--- " + name_to_check + " ---\nRESONANCE: " + tag_string + "\nINK: " + str(data.ink_rate) + "/s\nHP: " + str(data.hp) + " | ATK: " + str(data.atk)
		check_for_merges()
	else:
		%Portrait.color = Color.BLACK; %StatsLabel.text = "Select an Echo."; %MergeButton.disabled = true
	
	if codex_selected_index != -1:
		var selected = echo_names[codex_selected_index]
		if selected in discovered_echoes:
			var d = echo_database[selected]
			var t_s = ""
			for t in d.tags: t_s += tag_colors[t] + " "
			%CodexLabel.text = "ENTRY: " + selected + "\nTAGS: " + t_s + "\n\nINK: " + str(d.ink_rate) + "/s\n\nLORE: " + d.lore
		else: %CodexLabel.text = "ENTRY: ???\n\nDiscovery required."
	calculate_synergy()

func calculate_synergy():
	var tags = {"Tide": 0, "Tremor": 0, "Pyre": 0, "Zephyr": 0}
	var hp = 0; var atk = 0
	for item in deployed_echoes:
		var d = echo_database[get_base_name(item)] if echo_database.has(get_base_name(item)) else {"hp":0,"atk":0,"tags":[]}
		hp += d.hp; atk += d.atk
		for tag in d.tags: if tags.has(tag): tags[tag] += 1
	if tags["Tide"] >= 3: hp = int(hp * 1.5)
	if tags["Pyre"] >= 3: atk = int(atk * 1.5)
	%SynergyLabel.text = "BOARD HP: " + str(hp) + " | ATK: " + str(atk)

# --- 5. BATTLE LOGIC FIXED ---

func _on_fight_button_pressed():
	if is_fighting or deployed_echoes.size() == 0: return
	is_fighting = true; %FightButton.disabled = true
	var hp = 0; var atk = 0; var b_atk = boss_atk; var tags = {"Tide":0,"Tremor":0,"Pyre":0,"Zephyr":0}
	for item in deployed_echoes:
		var d = echo_database[get_base_name(item)]; hp += d.hp; atk += d.atk
		for tag in d.tags: if tags.has(tag): tags[tag] += 1
	if tags["Tide"] >= 3: hp = int(hp * 1.5)
	if tags["Tremor"] >= 3: b_atk = int(b_atk * 0.7)
	if tags["Pyre"] >= 3: atk = int(atk * 1.5)
	var l_b_hp = boss_hp; var l_p_hp = hp
	%BattleLog.text = "BATTLE START!"
	
	while l_b_hp > 0 and l_p_hp > 0:
		# PLAYER ATTACKS
		l_b_hp -= atk
		%BossHPBar.value = l_b_hp
		spawn_damage_text(atk, %BossLabel.global_position + Vector2(100, 0), Color.YELLOW)
		apply_shake(%BossLabel, 10.0)
		flash_node(%BossLabel, Color.WHITE)
		await get_tree().create_timer(0.4).timeout
		
		if l_b_hp <= 0: break
		
		# BOSS ATTACKS
		l_p_hp -= b_atk
		%BattleLog.text = "Board HP: " + str(l_p_hp)
		spawn_damage_text(b_atk, Vector2(200, 400), Color.RED) # Generic board pos
		apply_shake(self, 5.0) # Shake the root node for screen shake
		await get_tree().create_timer(0.4).timeout
	
	if l_b_hp <= 0:
		var r = 100 * boss_level; ink_count += r; boss_level += 1
		boss_hp = int(boss_hp * 1.5); boss_atk = int(boss_atk * 1.2)
		%BattleLog.text = "VICTORY!"
	else:
		%BattleLog.text = "DEFEAT!"
	
	is_fighting = false; update_ui()

# --- 6. HATCHERY & SYSTEM (UNTOUCHED) ---

func _on_shop_button_pressed(): 
	var open_slot = find_free_slot()
	if open_slot == -1 or ink_count < 50: return
	ink_count -= 50
	var starters = ["Tide Echo", "Tremor Echo", "Pyre Echo", "Zephyr Echo"]
	start_hatchery_job(open_slot, starters[randi() % 4], 5.0); update_ui()

func _on_weave_button_pressed():
	var open_slot = find_free_slot()
	if open_slot == -1 or parent_a_index == -1 or parent_b_index == -1: return
	var p1 = get_base_name(my_collection[parent_a_index])
	var p2 = get_base_name(my_collection[parent_b_index])
	var key = p1 + " + " + p2; var alt = p2 + " + " + p1
	var res = ""
	if weighted_recipes.has(key): res = pick_weighted_result(weighted_recipes[key])
	elif weighted_recipes.has(alt): res = pick_weighted_result(weighted_recipes[alt])
	else: res = p1 if randf() > 0.5 else p2
	start_hatchery_job(open_slot, res, echo_database[res]["time"])
	parent_a_index = -1; parent_b_index = -1; update_ui()

func find_free_slot() -> int:
	for i in range(hatchery_slots.size()):
		if not hatchery_slots[i]["is_active"]: return i
	return -1

func start_hatchery_job(slot_index, result_name, duration):
	hatchery_slots[slot_index]["is_active"] = true
	hatchery_slots[slot_index]["result"] = result_name
	hatchery_slots[slot_index]["finish_time"] = Time.get_unix_time_from_system() + duration
	hatchery_slots[slot_index]["total_time"] = duration

func pick_weighted_result(recipe_dict):
	var total_weight = 0
	for weight in recipe_dict.values(): total_weight += weight
	var roll = randi() % total_weight; var current_sum = 0
	for outcome in recipe_dict.keys():
		current_sum += recipe_dict[outcome]
		if roll < current_sum: return outcome
	return recipe_dict.keys()[0]

func _on_item_list_item_selected(index):
	if parent_a_index == -1: parent_a_index = index
	elif parent_b_index == -1: parent_b_index = index
	else: parent_a_index = index; parent_b_index = -1
	last_clicked_index = index; update_ui()
func _on_deploy_button_pressed():
	if last_clicked_index == -1: return
	deployed_echoes.append(my_collection[last_clicked_index]); my_collection.remove_at(last_clicked_index); last_clicked_index = -1; update_ui()
func _on_recall_button_pressed():
	if board_selected_index == -1: return
	my_collection.append(deployed_echoes[board_selected_index]); deployed_echoes.remove_at(board_selected_index); board_selected_index = -1; update_ui()
func _on_board_list_item_selected(index): board_selected_index = index; update_ui()
func _on_collect_button_pressed(): ink_count += int(stored_ink); stored_ink = 0; update_ui()
func _on_exile_button_pressed(): if last_clicked_index != -1: my_collection.remove_at(last_clicked_index); last_clicked_index = -1; update_ui()
func _on_codex_list_item_selected(index): codex_selected_index = index; update_ui()

func check_for_merges():
	var selected_echo = my_collection[last_clicked_index]
	if "(3-Star)" in selected_echo: %MergeButton.disabled = true; %MergeButton.text = "MAX STAR"; return
	var count = 0
	for item in my_collection: if item == selected_echo: count += 1
	%MergeButton.disabled = count < 3
	%MergeButton.text = "MERGE 3x" if count >= 3 else "NEED 3 COPIES"

func _on_merge_button_pressed():
	if last_clicked_index == -1: return
	var target = my_collection[last_clicked_index]; var removed = 0; var next = []
	for i in my_collection:
		if i == target and removed < 3: removed += 1
		else: next.append(i)
	my_collection = next
	var new_name = target.replace("(2-Star)", "(3-Star)") if "(2-Star)" in target else target + " (2-Star)"
	var base_name = get_base_name(target)
	if not echo_database.has(new_name):
		var old = echo_database[base_name]
		echo_database[new_name] = {"hp":old.hp*2,"atk":old.atk*2,"time":old.time,"tags":old.tags,"ink_rate":old.ink_rate*3,"color":old.color, "lore": "Refined."}
	my_collection.append(new_name); last_clicked_index = -1; update_ui()

func _process(delta):
	var rate = 0; var zephyr_count = 0
	for i in deployed_echoes: if "Zephyr" in echo_database[get_base_name(i)].tags: zephyr_count += 1
	for i in my_collection: rate += echo_database[get_base_name(i)].ink_rate if echo_database.has(get_base_name(i)) else 0
	for i in deployed_echoes: rate += echo_database[get_base_name(i)].ink_rate if echo_database.has(get_base_name(i)) else 0
	if zephyr_count >= 3: rate = rate * 1.5 
	if stored_ink < max_ink_capacity:
		stored_ink += rate * delta
		%CollectButton.text = "Collect (" + str(int(stored_ink)) + "/" + str(max_ink_capacity) + ")"
	
	var now = Time.get_unix_time_from_system()
	for i in range(hatchery_slots.size()):
		var slot = hatchery_slots[i]
		var bar = get_node("%HatcheryBar" + str(i+1))
		if slot["is_active"]:
			var time_left = slot["finish_time"] - now
			bar.value = 100 - ((time_left / slot["total_time"]) * 100)
			if time_left <= 0:
				slot["is_active"] = false; bar.value = 0
				if not slot["result"] in discovered_echoes: discovered_echoes.append(slot["result"])
				my_collection.append(slot["result"]); update_ui()
