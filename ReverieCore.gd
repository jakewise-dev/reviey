extends Node2D
signal ui_updated


@onready var tide_1: Sprite2D = %Tide1
@onready var echo_scene = preload("res://base_echo.tscn")

const SAVE_PATH = "user://reverie_archive.save"

# --- 1. DATA & ECONOMY ---
var ink_count = 200 
var max_ink_capacity = 5000 
var current_total_rate = 0.0
@export var tide_scene: PackedScene = preload("res://TideHabitat.tscn")
@export var pyre_scene: PackedScene = preload("res://PyreHabitat.tscn")


# --- NEW: Wisp Placement Trackers ---
var active_waiting_wisp_name = ""
var active_waiting_wisp_node = null

var player_level = 1
var player_exp = 0
var exp_to_next_level = 100

var weave_speed_mult = 1.0 
var upgrades_unlocked = {"slot_4": false, "speed": false, "board": false}
var upgrade_costs = {"slot_4": 1500, "speed": 3000, "board": 6000}

var tag_colors = {"Tide": "🌊 Tide", "Tremor": "🪨 Tremor", "Pyre": "🔥 Pyre", "Zephyr": "🌬️ Zephyr"}

var echo_database = {
    # --- BASES ---
    "Tide Echo": {"hp": 100, "atk": 5, "time": 5, "tags": ["Tide"], "ink_rate": 1, "color": Color.CORNFLOWER_BLUE, "lore": "A manifestation of the subconscious flow. It is calm, but relentless."},
    "Tremor Echo": {"hp": 80, "atk": 8, "time": 5, "tags": ["Tremor"], "ink_rate": 1, "color": Color.GOLDENROD, "lore": "A solid, heavy memory. It grounds the Archive to reality."},
    "Pyre Echo": {"hp": 70, "atk": 12, "time": 5, "tags": ["Pyre"], "ink_rate": 1, "color": Color.ORANGE_RED, "lore": "Intense passion burning brightly. It consumes ink quickly."},
    "Zephyr Echo": {"hp": 90, "atk": 6, "time": 5, "tags": ["Zephyr"], "ink_rate": 2, "color": Color.LIGHT_CYAN, "lore": "A fleeting whim. Hard to hold onto, but moves with great speed."},
    
    # --- TIDE + TREMOR ---
    "The Shiver": {"hp": 130, "atk": 18, "time": 15, "tags": ["Tide", "Tremor"], "ink_rate": 5, "color": Color.AQUAMARINE, "lore": "A cold realization that shakes the foundation of the mind."},
    "The Faultline": {"hp": 160, "atk": 14, "time": 15, "tags": ["Tremor", "Tide"], "ink_rate": 5, "color": Color.CHOCOLATE, "lore": "A mental crack. Pressure built up over years, finally snapping."},
    
    # --- TIDE + PYRE (The 4 Options!) ---
    "Steam Echo": {"hp": 80, "atk": 15, "time": 10, "tags": ["Tide", "Pyre"], "ink_rate": 3, "color": Color.LIGHT_GRAY, "lore": "COMMON: A gentle mix of fire and water. Warm and fleeting."},
    "Geyser Echo": {"hp": 90, "atk": 18, "time": 10, "tags": ["Pyre", "Tide"], "ink_rate": 3, "color": Color.SKY_BLUE, "lore": "COMMON: A sudden, violent burst of hot water."},
    "Scalding Regret": {"hp": 110, "atk": 25, "time": 15, "tags": ["Tide", "Pyre"], "ink_rate": 6, "color": Color.INDIAN_RED, "lore": "RARE: A memory that burns to touch. It hurts the creator to remember."},
    "Thermal Flare": {"hp": 150, "atk": 30, "time": 25, "tags": ["Pyre", "Tide"], "ink_rate": 10, "color": Color.CRIMSON, "lore": "EPIC: Highly unstable boiling rage. Beautiful but dangerous."},
    
    # --- OTHERS ---
    "Molten Core": {"hp": 180, "atk": 25, "time": 20, "tags": ["Tremor", "Pyre"], "ink_rate": 8, "color": Color.DARK_ORANGE, "lore": "Burning trauma trapped under a heavy layer of stoicism."},
    "The Haze": {"hp": 120, "atk": 15, "time": 15, "tags": ["Tremor", "Zephyr"], "ink_rate": 6, "color": Color.WHEAT, "lore": "A crumbling memory turning to dust in the wind."},
    "Breezy Passion": {"hp": 100, "atk": 20, "time": 15, "tags": ["Pyre", "Zephyr"], "ink_rate": 7, "color": Color.LIGHT_STEEL_BLUE, "lore": "A light obsession. A hobby picked up and dropped in a week."}
}

var weighted_recipes = {
    # --- PURE BREEDING (Mixing two of the exact same still gives the base) ---
    "Tide Echo + Tide Echo": {"Tide Echo": 100},
    "Pyre Echo + Pyre Echo": {"Pyre Echo": 100},
    "Tremor Echo + Tremor Echo": {"Tremor Echo": 100},

    # --- TIDE + PYRE (4 Options, ZERO Fails!) ---
    "Tide Echo + Pyre Echo": {
        "Steam Echo": 40,       # 40% chance (Common)
        "Geyser Echo": 40,      # 40% chance (Common)
        "Scalding Regret": 15,  # 15% chance (Rare)
        "Thermal Flare": 5      # 5% chance (Epic)
    },
    
    # --- TIDE + TREMOR ---
    "Tide Echo + Tremor Echo": {
        "The Shiver": 50, 
        "The Faultline": 50
    },
    
    # --- TREMOR + PYRE ---
    "Tremor Echo + Pyre Echo": {
        "Molten Core": 100
    },
    
    # --- PYRE + ZEPHYR ---
    "Pyre Echo + Zephyr Echo": {
        "Breezy Passion": 100
    }
}


# --- 2. GAME STATE (THE 3 PILLARS) ---

var hatchery_slots_active = [false, false, false, false]

var my_collection = [] # The Dummy Variable is back to stop errors!
var discovered_echoes = []

var deployed_echoes = [] 
var max_board_size = 3

var boss_atk = 15
var boss_level = 1
var boss_hp = 150
var is_fighting = false

var parent_a_index = -1
var parent_b_index = -1
var selected_echo_name = "" 
var library_roster_selected_name = ""
var board_selected_index = -1

var inspected_exhibit_key = ""
var selected_exhibit_content_index = -1
var codex_selected_name = ""
var active_habitat_node = null

var parent_a_name = ""
var parent_b_name = ""
var active_weave_slot = 0
var altar_is_weaving = false
var altar_egg_ready = false
var altar_result_egg = ""

# --- 3. INITIALIZATION ---

func _ready():
    randomize()
    auto_wire_signals()
    update_ui()

func auto_wire_signals():
    var btns = {
        "%ShopButton": _on_shop_button_pressed,
        "%WeaveButton": _on_weave_button_pressed,
       
        "%DeployButton": _on_deploy_button_pressed,
        "%RecallButton": _on_recall_button_pressed,
        "%FightButton": _on_fight_button_pressed,
        "%ExileButton": _on_exile_button_pressed,
        "%MergeButton": _on_merge_button_pressed,
        "%SaveButton": save_game,
        "%LoadButton": load_game
    }
    
    for path in btns:
        if has_node(path):
            var b = get_node(path)
            for c in b.pressed.get_connections():
                b.pressed.disconnect(c.callable)
            b.pressed.connect(btns[path])
    
    var lists = {
        "%ItemList": _on_item_list_item_selected,
        "%BoardList": _on_board_list_item_selected,
        "%CodexList": _on_codex_list_item_selected
    }
    
    for path in lists:
        if has_node(path):
            var l = get_node(path)
            if l.item_selected.is_connected(lists[path]):
                l.item_selected.disconnect(lists[path])
            l.item_selected.connect(lists[path])

func get_base_name(f):
    return f.split(" (")[0]

# --- 4. UI & DETAILS ---


func update_ui():
    if is_fighting: return 
        
    if has_node("%InkLabel"):
        %InkLabel.text = "Ink: " + str(int(ink_count)) + " | Level: " + str(player_level) + " (" + str(player_exp) + "/" + str(exp_to_next_level) + " XP)"
        
    if has_node("%InkLabelUI"):
        %InkLabelUI.text = "Ink: " + str(int(ink_count))
        
    if has_node("%BossLabel"):
        %BossLabel.text = "Boss Lv. " + str(boss_level) + " | HP: " + str(boss_hp)
    
    if has_node("%ItemList"):
        %ItemList.clear()
        for item in my_collection: %ItemList.add_item(item)
            
    if has_node("%LibraryRoster"):
        %LibraryRoster.clear()
        for item in my_collection: %LibraryRoster.add_item(item)
            
    if has_node("%BoardList"):
        %BoardList.clear()
        for item in deployed_echoes: %BoardList.add_item(item)

    if has_node("%CodexList"):
        %CodexList.clear()
        var all_keys = echo_database.keys()
        for key in all_keys:
            if key in discovered_echoes: %CodexList.add_item(key)
            else: %CodexList.add_item("???")
                
    if codex_selected_name != "" and has_node("%CodexLoreLabel"):
        if codex_selected_name in discovered_echoes:
            var d = echo_database[codex_selected_name]
            var tags_text = ""
            for t in d.tags: tags_text += tag_colors[t] + " "
            if has_node("%CodexPortrait"): %CodexPortrait.color = d.color
            %CodexLoreLabel.text = codex_selected_name + "\n" + tags_text + "\n\nBase HP: " + str(d.hp) + " | Base ATK: " + str(d.atk) + "\nInk Rate: " + str(d.ink_rate) + "/s\n\nLORE: " + d.lore
        else:
            if has_node("%CodexPortrait"): %CodexPortrait.color = Color.BLACK
            %CodexLoreLabel.text = "???\n\nThis Echo has not been discovered yet."

    if selected_echo_name != "" and has_node("%StatsLabel"):
        var base = get_base_name(selected_echo_name)
        if echo_database.has(base):
            var d = echo_database[base]
            if has_node("%Portrait"): %Portrait.color = d.color
            var tags_text = ""
            for t in d.tags: tags_text += tag_colors[t] + " "
            %StatsLabel.text = "--- ARCHIVE ---\n" + selected_echo_name + "\nRESONANCE: " + tags_text + "\nINK: " + str(d.ink_rate) + "/s\nHP: " + str(d.hp) + " | ATK: " + str(d.atk)
            check_for_merges()

    var p1 = "..."
    if parent_a_index != -1 and parent_a_index < my_collection.size(): p1 = my_collection[parent_a_index]
    var p2 = "..."
    if parent_b_index != -1 and parent_b_index < my_collection.size(): p2 = my_collection[parent_b_index]
        
    if has_node("%DetailsLabel"):
        %DetailsLabel.text = "Weaving: " + p1 + " + " + p2
            
    if has_node("%FightButton"):
        %FightButton.disabled = deployed_echoes.size() == 0 or is_fighting
        
    # Show/Hide hatchery bars based on player level
    var max_slots = get_max_hatchery_slots()
    
    if has_node("%HatcheryBar1"): %HatcheryBar1.visible = (max_slots >= 1)
    if has_node("%HatcheryBar2"): %HatcheryBar2.visible = (max_slots >= 2)
    if has_node("%HatcheryBar3"): %HatcheryBar3.visible = (max_slots >= 3)
    if has_node("%HatcheryBar4"): %HatcheryBar4.visible = (max_slots >= 4)
    update_synergy_label()

    
    print("RINGING THE BELL") # Add this for debugging!
    ui_updated.emit()

func update_synergy_label():
    var tags = {"Tide": 0, "Tremor": 0, "Pyre": 0, "Zephyr": 0}
    var total_atk = 0
    for item in deployed_echoes:
        var base = get_base_name(item)
        if echo_database.has(base):
            var d = echo_database[base]
            total_atk += d.atk
            for t in d.tags:
                if tags.has(t): tags[t] += 1
    if tags["Pyre"] >= 3:
        total_atk = int(total_atk * 1.5)
        
    if has_node("%SynergyLabel"):
        %SynergyLabel.text = "Field: " + str(deployed_echoes.size()) + "/" + str(max_board_size) + " | ATK: " + str(total_atk)


# --- 5. HATCHERY & EXP ---

func gain_exp(amount):
    player_exp += amount
    if player_exp >= exp_to_next_level:
        player_level += 1
        player_exp -= exp_to_next_level
        exp_to_next_level = int(exp_to_next_level * 1.5)
        print("LEVEL UP! You are now Level ", player_level)

func find_free_slot():
    var total_slots = get_max_hatchery_slots()
    for i in range(total_slots):
        if hatchery_slots_active[i] == false:
            return i
    return -1 
    
func start_job(slot_idx, res_name, dur):
    hatchery_slots_active[slot_idx] = true
    
    # 1. Spawn & Grow
    var new_wisp = echo_scene.instantiate()
    var book_container = get_node("%HatcheryBooks") 
    book_container.add_child(new_wisp)
    # Set the color based on the database
    var base = get_base_name(res_name)
    if echo_database.has(base):
        new_wisp.modulate = echo_database[base].color
    
    var marker = get_node("%SlotPos" + str(slot_idx + 1))
    new_wisp.position = marker.position
    new_wisp.scale = Vector2(0.1, 0.1)
    
    var grow_tween = create_tween()
    grow_tween.tween_property(new_wisp, "scale", Vector2(1.5, 1.5), dur)
    
    await grow_tween.finished
    print("Hatch complete! ", res_name, " is waiting on the book.")
    
    # 2. Add secret tags so the wisp remembers who it is
    new_wisp.set_meta("echo_name", res_name)
    new_wisp.set_meta("slot_idx", slot_idx)
    new_wisp.add_to_group("waiting_wisps")
    
    # --- NEW: Make it clickable! ---
    var area = new_wisp.get_node_or_null("Area2D")
    if area:
        area.input_event.connect(_on_waiting_wisp_clicked.bind(res_name, slot_idx, new_wisp))
    # -------------------------------
    
    # 3. The "Ready" Bounce Animation
    var bounce_tw = create_tween().set_loops()
    bounce_tw.tween_property(new_wisp, "position:y", new_wisp.position.y - 15, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    bounce_tw.tween_property(new_wisp, "position:y", new_wisp.position.y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    
# --- NEW: Make it clickable! ---
    var wisp_area = new_wisp.find_child("Area2D", true, false)
    if wisp_area:
        print("✅ Area2D FOUND! Wisp is ready to be clicked.")
        wisp_area.input_event.connect(_on_waiting_wisp_clicked.bind(res_name, slot_idx, new_wisp))
    else:
        print("❌ ERROR: Still can't find it! Check node name!")
    # -------------------------------
    
    
    update_ui()
    
func _on_shop_button_pressed(): 
    var slot = find_free_slot()
    if slot == -1 or ink_count < 50: return
    ink_count -= 50
    
    var pool = ["Tide Echo", "Pyre Echo"]
    if player_level >= 3: pool.append("Tremor Echo")
    if player_level >= 5: pool.append("Zephyr Echo")
        
    var result = pool[randi() % pool.size()]
    start_job(slot, result, 5.0)
    update_ui()

func _on_weave_button_pressed():
    var slot = find_free_slot()
    
    if slot == null or slot == -1:
        print("Archive is full! Cannot weave right now.")
        return 
        
    if parent_a_index == -1 or parent_b_index == -1:
        print("Select two Echoes to weave!")
        return
        
    var p1 = get_base_name(my_collection[parent_a_index])
    var p2 = get_base_name(my_collection[parent_b_index])
    var key = p1 + " + " + p2
    var alt = p2 + " + " + p1
    var res = ""
    
    if weighted_recipes.has(key): res = pick_weighted_result(weighted_recipes[key])
    elif weighted_recipes.has(alt): res = pick_weighted_result(weighted_recipes[alt])
    else: res = p1 if randf() > 0.5 else p2
            
    var final_time = echo_database[res]["time"] * weave_speed_mult
    start_job(slot, res, final_time)
    
    parent_a_index = -1
    parent_b_index = -1
    selected_echo_name = ""
    update_ui()
    
    
func _on_waiting_wisp_clicked(viewport, event, shape_idx, echo_name, slot_idx, wisp_node):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        
        # --- THE MAGIC SHIELD (Stops the laser beam!) ---
        viewport.set_input_as_handled() 
        # ------------------------------------------------
        
        print("Opening decision menu for: ", echo_name)
        
        # 1. Remember who we just clicked
        active_waiting_wisp_name = echo_name
        active_waiting_wisp_node = wisp_node
        
        # 2. Show the popup!
        if has_node("%DecisionPopup"):
            %DecisionPopup.visible = true

# --- 7. TFT COMBAT LOGIC ---
func _on_deploy_button_pressed():
    if selected_echo_name != "" and selected_echo_name in my_collection:
        if deployed_echoes.size() < max_board_size:
            my_collection.erase(selected_echo_name)
            deployed_echoes.append(selected_echo_name)
            selected_echo_name = ""
            update_ui()

func _on_recall_button_pressed():
    if board_selected_index != -1 and board_selected_index < deployed_echoes.size():
        my_collection.append(deployed_echoes[board_selected_index])
        deployed_echoes.remove_at(board_selected_index)
        board_selected_index = -1
        update_ui()

func post_to_log(msg: String):
    if has_node("%BattleLog"):
        var log_node = get_node("%BattleLog")
        log_node.append_text(msg + "\n")

func _on_fight_button_pressed():
    if is_fighting or deployed_echoes.size() == 0: return
    is_fighting = true
    if has_node("%FightButton"): %FightButton.disabled = true
    
    var current_hp = 0
    var current_atk = 0
    var current_boss_atk = boss_atk
    var tags = {"Tide": 0, "Tremor": 0, "Pyre": 0, "Zephyr": 0}
    
    for i in deployed_echoes:
        var d = echo_database[get_base_name(i)]
        current_hp += d.hp
        current_atk += d.atk
        for t in d.tags: if tags.has(t): tags[t] += 1
    
    var heal_per_turn = tags["Tide"] * 10      
    var shield_block = tags["Tremor"] * 5      
    var burn_per_turn = tags["Pyre"] * 15      
    
    var active_boss_hp = boss_hp
    var active_player_hp = current_hp
    var max_player_hp = current_hp
    
    if has_node("%BossHPBar"):
        %BossHPBar.max_value = boss_hp
        %BossHPBar.value = active_boss_hp
    
    if has_node("%BattleLog"): 
        %BattleLog.text = "" 
    post_to_log("[color=yellow]--- BATTLE START (LV " + str(boss_level) + ") ---[/color]")
    
    while active_boss_hp > 0 and active_player_hp > 0:
        active_boss_hp -= current_atk
        post_to_log("Board attacks for [color=yellow]" + str(current_atk) + "[/color] damage.")
        
        if burn_per_turn > 0:
            active_boss_hp -= burn_per_turn
            post_to_log("🔥 Pyre applies [color=orange]" + str(burn_per_turn) + " Burn[/color] damage!")
        
        if has_node("%BossHPBar"): %BossHPBar.value = active_boss_hp
        spawn_damage_text(current_atk + burn_per_turn, %BossLabel.global_position + Vector2(50,0), Color.YELLOW)
        apply_shake(%BossLabel, 10.0)
        await get_tree().create_timer(0.4).timeout
        
        if active_boss_hp <= 0: break
            
        var actual_boss_dmg = max(0, current_boss_atk - shield_block)
        active_player_hp -= actual_boss_dmg
        
        if shield_block > 0:
            post_to_log("Boss attacks for [color=red]" + str(actual_boss_dmg) + "[/color] (🪨 Blocked " + str(shield_block) + ").")
        else:
            post_to_log("Boss attacks for [color=red]" + str(actual_boss_dmg) + "[/color] damage.")
        
        if heal_per_turn > 0 and active_player_hp > 0:
            active_player_hp += heal_per_turn
            if active_player_hp > max_player_hp: active_player_hp = max_player_hp
            post_to_log("🌊 Tide heals the board for [color=green]" + str(heal_per_turn) + "[/color] HP!")
            
        spawn_damage_text(actual_boss_dmg, Vector2(200, 400), Color.RED)
        apply_shake(self, 5.0)
        await get_tree().create_timer(0.4).timeout
    
    if active_boss_hp <= 0:
        post_to_log("[color=green]--- VICTORY ---[/color]")
        ink_count += 100 * boss_level
        var exp_reward = 50 * boss_level
        gain_exp(exp_reward)
        
        boss_level += 1
        boss_hp = int(boss_hp * 1.5)
        boss_atk = int(boss_atk * 1.2)
        post_to_log("Gained " + str(exp_reward) + " EXP!")
    else:
        post_to_log("[color=red]--- DEFEAT ---[/color]")
        post_to_log("Your board was wiped out.")
        
    is_fighting = false
    if has_node("%FightButton"): %FightButton.disabled = false
    update_ui()

# --- 8. HELPERS ---
func _on_item_list_item_selected(idx):
    pass
    # if idx < my_collection.size():
    # 	selected_echo_name = my_collection[idx]
    # 	if parent_a_index == -1: parent_a_index = idx
    # 	elif parent_b_index == -1: parent_b_index = idx
    # 	else: parent_a_index = idx; parent_b_index = -1
    # 	update_ui()

func _on_board_list_item_selected(idx):
    if idx < deployed_echoes.size():
        board_selected_index = idx
        update_ui()

func _on_codex_list_item_selected(idx):
    var all_keys = echo_database.keys()
    if idx < all_keys.size(): codex_selected_name = all_keys[idx]
    update_ui()

func _on_merge_button_pressed():
    if selected_echo_name == "": return
    var target = selected_echo_name
    var count_found = 0
    var next_collection = []
    for i in my_collection:
        if i == target:
            if count_found < 3: count_found += 1
            else: next_collection.append(i)
        else: next_collection.append(i)
    
    my_collection = next_collection
    var base = get_base_name(target)
    var next_star_name = target.replace("(2-Star)", "(3-Star)") if "(2-Star)" in target else target + " (2-Star)"
        
    if not echo_database.has(next_star_name):
        var old = echo_database[base]
        echo_database[next_star_name] = {"hp": old.hp * 2, "atk": old.atk * 2, "time": old.time, "tags": old.tags, "ink_rate": old.ink_rate * 3, "color": old.color}
    my_collection.append(next_star_name)
    selected_echo_name = next_star_name
    update_ui()

func check_for_merges():
    var count = 0
    for i in my_collection:
        if i == selected_echo_name: count += 1
    if has_node("%MergeButton"):
        %MergeButton.disabled = count < 3
        %MergeButton.text = "MERGE" if count >= 3 else "NEED 3"

func pick_weighted_result(dict):
    var tw = 0
    for w in dict.values(): tw += w
    var r = randi() % tw
    var current_sum = 0
    for outcome in dict.keys():
        current_sum += dict[outcome]
        if r < current_sum: return outcome
    return dict.keys()[0]

func spawn_damage_text(v, p, c):
    var l = Label.new()
    l.text = str(v)
    l.add_theme_color_override("font_color", c)
    add_child(l)
    l.global_position = p
    var tw = create_tween().set_parallel(true)
    tw.tween_property(l, "position", l.position + Vector2(0, -50), 0.5)
    tw.tween_property(l, "modulate:a", 0.0, 0.5)
    tw.chain().tween_callback(l.queue_free)

func apply_shake(n, i):
    var o = n.position
    var tw = create_tween()
    for j in range(4):
        var offset = Vector2(randf_range(-i,i), randf_range(-i,i))
        tw.tween_property(n, "position", o + offset, 0.05)
    tw.tween_property(n, "position", o, 0.05)

func _on_exile_button_pressed():
    if selected_echo_name != "" and selected_echo_name in my_collection:
        my_collection.erase(selected_echo_name)
        selected_echo_name = ""
        parent_a_index = -1
        parent_b_index = -1
        update_ui()

# --- 9. SAVE & LOAD SYSTEM (WITH OFFLINE PROGRESS) ---

func save_game():
    # 🌟 1. Take a snapshot of every physical building on the island
    var grid_snapshot = []
    for hab in get_tree().get_nodes_in_group("placed_habitats"):
        grid_snapshot.append({
            "pos_x": hab.global_position.x,
            "pos_y": hab.global_position.y,
            "type": hab.habitat_type,
            "ink": hab.stored_ink,
            "echoes": hab.resident_echoes
        })

    # 🌟 2. Bundle it all together
    var save_data = {
        "ink_count": ink_count,
        "player_level": player_level,
        "player_exp": player_exp,
        "exp_to_next_level": exp_to_next_level,
        "my_collection": my_collection,
        "discovered_echoes": discovered_echoes,
        "deployed_echoes": deployed_echoes,
        "boss_level": boss_level,
        "boss_hp": boss_hp,
        "boss_atk": boss_atk,
        "upgrades_unlocked": upgrades_unlocked,
        "grid_data": grid_snapshot, # <-- Our new island snapshot!
        "last_save_time": Time.get_unix_time_from_system() 
    }
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_var(save_data)
    print("Game Saved successfully!")
    post_to_log("Game Saved to Hard Drive!")

func load_game():
    if not FileAccess.file_exists(SAVE_PATH):
        print("No save file found!")
        return
        
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var save_data = file.get_var()
    
    ink_count = save_data.get("ink_count", ink_count)
    player_level = save_data.get("player_level", player_level)
    player_exp = save_data.get("player_exp", player_exp)
    exp_to_next_level = save_data.get("exp_to_next_level", exp_to_next_level)
    my_collection = save_data.get("my_collection", my_collection)
    discovered_echoes = save_data.get("discovered_echoes", discovered_echoes)
    deployed_echoes = save_data.get("deployed_echoes", deployed_echoes)
    boss_level = save_data.get("boss_level", boss_level)
    boss_hp = save_data.get("boss_hp", boss_hp)
    boss_atk = save_data.get("boss_atk", boss_atk)
    upgrades_unlocked = save_data.get("upgrades_unlocked", upgrades_unlocked)
    
    # 🌟 1. Clear the island of any pre-existing buildings
    for hab in get_tree().get_nodes_in_group("placed_habitats"):
        hab.queue_free()
        
    # 🌟 2. Rebuild the island from the snapshot!
    var grid_snapshot = save_data.get("grid_data", [])
    for data in grid_snapshot:
        var new_hab = null
        
        # Figure out which blueprint to use
        if data["type"] == "Tide" and tide_scene:
            new_hab = tide_scene.instantiate()
        elif data["type"] == "Pyre" and pyre_scene:
            new_hab = pyre_scene.instantiate()
            
        # If we built one, place it and fill its pockets
        if new_hab:
            get_tree().current_scene.add_child(new_hab)
            new_hab.global_position = Vector2(data["pos_x"], data["pos_y"])
            new_hab.stored_ink = data.get("ink", 0.0)
            new_hab.resident_echoes = data.get("echoes", [])
            
            # Force the visual wisps to spawn immediately
            if new_hab.has_method("refresh_visuals"):
                new_hab.refresh_visuals()

    selected_echo_name = ""
    library_roster_selected_name = ""
    inspected_exhibit_key = ""
    
    update_ui()
    print("Game Loaded successfully!")
    post_to_log("Game Loaded Successfully!")

func _on_area_2d_mouse_entered():
    tide_1.modulate = Color(1.5, 1.5, 2.0)

func _on_area_2d_mouse_exited():
    tide_1.modulate = Color(1, 1, 1)



func _on_close_button_pressed():
    print("Closing SanctuaryUI...")
    %SanctuaryUI.visible = false

func _on_pyre_1_area_2d_mouse_entered():
    print("I AM TOUCHING THE FORGE!")
    %"pyre 1".modulate = Color(2.0, 1.2, 0.8)

func _on_pyre_1_area_2d_mouse_exited():
    print("I LEFT THE FORGE!")
    %"pyre 1".modulate = Color(1, 1, 1)

func _on_pyre_1_area_2d_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        print("I CLICKED THE FORGE!")
        %SanctuaryUI.visible = true
        %TabContainer.current_tab = 1
        update_ui()

func _on_buy_tide_button_pressed():
    var slot = find_free_slot()
    if slot != -1:
        start_job(slot, "Tide Echo", 5.0) 

func _on_buy_pyre_button_pressed():
    var slot = find_free_slot()
    if slot != -1:
        start_job(slot, "Pyre Echo", 5.0)
        
func get_max_hatchery_slots():
    var slots = 1
    if player_level >= 3: slots = 2
    if player_level >= 10: slots = 3
    if player_level >= 25: slots = 4
    return slots


func _on_place_button_pressed():
    if active_waiting_wisp_name != "" and active_waiting_wisp_node != null:
        # 1. Add it to your Archive (my_collection) instead of forcing a habitat!
        my_collection.append(active_waiting_wisp_name)
        print("Sent ", active_waiting_wisp_name, " to the Archive!")
        
        # 2. Clean up the hatchery book
        var slot_idx = active_waiting_wisp_node.get_meta("slot_idx")
        hatchery_slots_active[slot_idx] = false
        active_waiting_wisp_node.queue_free()
        
        # 3. UI Cleanup
        %DecisionPopup.visible = false
        update_ui() 
        
        active_waiting_wisp_name = ""
        active_waiting_wisp_node = null

func _on_sell_button_pressed() -> void:
    pass # Replace with function body.



# --- MASTER UI FUNCTION ---

func open_sanctuary(tab_name: String):
    print("Opening Sanctuary UI for: ", tab_name)
    
    if has_node("%SanctuaryUI"):
        %SanctuaryUI.visible = true
        
        match tab_name:
            "Archive":
                %TabContainer.current_tab = 0 
            "Tide":
                %TabContainer.current_tab = 3
            "Pyre":
                %TabContainer.current_tab = 1
            "Hatchery":
                %TabContainer.current_tab = 0 
    else:
        print("❌ ERROR: Could not find SanctuaryUI node!")

# ==========================================
# --- FOOTER UI & TRAY SYSTEM ---
# ==========================================

func show_habitat_footer(habitat_node):
    if habitat_node == null: return
    
    # 🌟 FIX 2: Auto-close any lingering popups so switching is seamless!
    if has_node("%RosterPopup"): %RosterPopup.visible = false
    if has_node("%DecisionPopup"): %DecisionPopup.visible = false
    
    # 1. Remember exactly which physical tree we clicked!
    active_habitat_node = habitat_node 
    
    if has_node("%HabitatNameLabel"):
        %HabitatNameLabel.text = habitat_node.habitat_type + " Habitat"
        
    # ... (Keep the rest of your function exactly the same!) ...
    
    if has_node("%HabitatMenuBoxContainer"):
        # Clear out the old buttons
        for child in %HabitatMenuBoxContainer.get_children():
            child.queue_free()
        
        # 2. Read from the tree's PERSONAL list of wisps!
        for wisp_name in habitat_node.resident_echoes:
            var portrait = create_portrait_button(wisp_name)
            %HabitatMenuBoxContainer.add_child(portrait)
        
        # 3. If there is space, add the Add button
        if habitat_node.resident_echoes.size() < 3: 
            var add_btn = create_action_button("Add")
            add_btn.pressed.connect(_on_add_to_habitat_pressed)
            %HabitatMenuBoxContainer.add_child(add_btn)
            
        # 4. Add the Collect button
        var collect_btn = create_action_button("Collect")
        collect_btn.pressed.connect(_on_collect_from_habitat)
        %HabitatMenuBoxContainer.add_child(collect_btn)
        
        # 5. Add the Close button
        var close_btn = create_action_button("Close")
        close_btn.pressed.connect(func(): %HabitatMenu.visible = false)
        %HabitatMenuBoxContainer.add_child(close_btn)
    
    if has_node("%HabitatMenu"):
        %HabitatMenu.visible = true

func _on_collect_from_habitat():
    # Only collect from the specific tree we are looking at!
    if active_habitat_node and active_habitat_node.stored_ink >= 1:
        var amount = floor(active_habitat_node.stored_ink)
        ink_count += amount
        active_habitat_node.stored_ink = 0 # Empty this specific tree's pockets
        update_ui()
        print("💰 Harvested ", amount, " ink!")
    else:
        print("No ink to collect yet!")

func create_portrait_button(wisp_name: String) -> Button:
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(80, 80)
    
    var color_patch = ColorRect.new()
    color_patch.size = Vector2(60, 40)
    color_patch.position = Vector2(10, 10)
    color_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    var base = get_base_name(wisp_name)
    if echo_database.has(base):
        color_patch.color = echo_database[base].color
    
    btn.add_child(color_patch)
    btn.text = "\n\n" + wisp_name.split(" ")[0]
    
    # 🌟 NEW: Clicking the portrait now triggers the recall!
    btn.pressed.connect(func():
        recall_wisp_from_tree(wisp_name)
    )
    
    return btn

func recall_wisp_from_tree(wisp_name: String):
    if active_habitat_node == null: return
    
    # 1. Remove the wisp from the physical tree's pockets
    active_habitat_node.resident_echoes.erase(wisp_name)
    
    # 2. Put it safely back in your main Archive list
    my_collection.append(wisp_name)
    
    # 3. Tell the tree to erase the wandering visual
    active_habitat_node.refresh_visuals()
    
    # 4. Refresh the UI tray so the portrait disappears instantly
    show_habitat_footer(active_habitat_node)
    update_ui()
    
    print("🪄 Recalled ", wisp_name, " back to the Archive!")

func create_action_button(btn_text: String, icon_path: String = "") -> Button:
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(80, 80)
    btn.text = btn_text
    return btn

func _on_add_to_habitat_pressed():
    print("Opening Roster for Habitat!")
    if has_node("%RosterList"):
        %RosterList.clear()
        for wisp in my_collection:
            %RosterList.add_item(wisp)
        
    if has_node("%RosterPopup"):
        %RosterPopup.visible = true

func _on_roster_list_item_selected(index: int):
    if index >= my_collection.size(): return
    var clicked_wisp = my_collection[index]

    # --- PATH A: ARE WE PICKING A PARENT FOR THE ALTAR? ---
    if active_weave_slot > 0:
        if active_weave_slot == 1:
            parent_a_name = clicked_wisp
        else:
            parent_b_name = clicked_wisp
            
        my_collection.remove_at(index)
        active_weave_slot = 0
        if has_node("%RosterPopup"): %RosterPopup.visible = false
        show_weaving_footer()
        update_ui()
        return

# --- PATH B: ARE WE PICKING A RESIDENT FOR A TREE? ---
    if active_habitat_node != null:
        var base_name = get_base_name(clicked_wisp)
        var echo_data = echo_database[base_name]
        
        if not active_habitat_node.habitat_type in echo_data.tags:
            spawn_damage_text("Wrong Element!", get_global_mouse_position(), Color.RED)
            print("Blocked: Wrong Element!")
            
            # 🌟 FIX 1: Close the roster popup so we don't get trapped!
            if has_node("%RosterPopup"): %RosterPopup.visible = false
            return
            
        my_collection.remove_at(index)
        active_habitat_node.resident_echoes.append(clicked_wisp)
        active_habitat_node.refresh_visuals()
        
        if has_node("%RosterPopup"): %RosterPopup.visible = false
        show_habitat_footer(active_habitat_node)
        update_ui()
        
        
# ==========================================
# --- WEAVING ALTAR TRAY LOGIC ---
# ==========================================

func _on_weaving_altar_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        print("Weaving Altar clicked!")
        show_weaving_footer()
        viewport.set_input_as_handled()

func show_weaving_footer():
    active_habitat_node = null 
    if has_node("%HabitatNameLabel"): %HabitatNameLabel.text = "The Weaving Altar"

    if has_node("%HabitatMenuBoxContainer"):
        for child in %HabitatMenuBoxContainer.get_children(): child.queue_free()

        # --- STATE 1: ALTAR IS BUSY WEAVING ---
        if altar_is_weaving:
            var busy_btn = create_action_button("Weaving...\n(Busy)")
            %HabitatMenuBoxContainer.add_child(busy_btn)
            
        # --- STATE 2: EGG IS READY ---
        elif altar_egg_ready:
            var collect_btn = create_action_button("Send Egg\nTo Hatchery")
            collect_btn.pressed.connect(_on_send_egg_pressed)
            %HabitatMenuBoxContainer.add_child(collect_btn)
            
        # --- STATE 3: EMPTY ALTAR (Pick Parents) ---
        else:
            if parent_a_name != "":
                var p1_btn = create_action_button("Remove\n" + parent_a_name.split(" ")[0])
                p1_btn.pressed.connect(func(): my_collection.append(parent_a_name); parent_a_name = ""; show_weaving_footer())
                %HabitatMenuBoxContainer.add_child(p1_btn)
            else:
                var add_a = create_action_button("Add\nParent 1")
                add_a.pressed.connect(func(): open_roster_for_weaving(1))
                %HabitatMenuBoxContainer.add_child(add_a)

            if parent_b_name != "":
                var p2_btn = create_action_button("Remove\n" + parent_b_name.split(" ")[0])
                p2_btn.pressed.connect(func(): my_collection.append(parent_b_name); parent_b_name = ""; show_weaving_footer())
                %HabitatMenuBoxContainer.add_child(p2_btn)
            else:
                var add_b = create_action_button("Add\nParent 2")
                add_b.pressed.connect(func(): open_roster_for_weaving(2))
                %HabitatMenuBoxContainer.add_child(add_b)

            if parent_a_name != "" and parent_b_name != "":
                var weave_btn = create_action_button("WEAVE!")
                weave_btn.pressed.connect(_on_physical_weave_pressed)
                %HabitatMenuBoxContainer.add_child(weave_btn)

        # Close Button
        var close_btn = create_action_button("Close")
        close_btn.pressed.connect(func(): %HabitatMenu.visible = false)
        %HabitatMenuBoxContainer.add_child(close_btn)

    if has_node("%HabitatMenu"): %HabitatMenu.visible = true

func open_roster_for_weaving(slot_number):
    active_weave_slot = slot_number
    if has_node("%RosterList"):
        %RosterList.clear()
        for wisp in my_collection: %RosterList.add_item(wisp)
    if has_node("%RosterPopup"): %RosterPopup.visible = true

func _on_physical_weave_pressed():
    # 1. Calculate the baby!
    var p1 = get_base_name(parent_a_name)
    var p2 = get_base_name(parent_b_name)
    var key = p1 + " + " + p2
    var alt = p2 + " + " + p1
    var res = p1 if randf() > 0.5 else p2 
    
    if weighted_recipes.has(key): res = pick_weighted_result(weighted_recipes[key])
    elif weighted_recipes.has(alt): res = pick_weighted_result(weighted_recipes[alt])

   # 2. Lock the Altar!
    altar_is_weaving = true
    altar_result_egg = res
    var weave_time = echo_database[res]["time"]
    
 # 🌟 Tell the physical altar to start its animation!
    var altar_node = get_node_or_null("%WeavingAltar")
    if altar_node and altar_node.has_method("start_weaving"):
        var color_a = echo_database[p1].color
        var color_b = echo_database[p2].color
        var color_baby = echo_database[res].color # Grab the baby's color!
        
        # Send all 3 colors to the Altar
        altar_node.start_weaving(color_a, color_b, color_baby, weave_time)
    
    %HabitatMenu.visible = false
    update_ui()
    print("🪄 Altar is now weaving! It will take ", weave_time, " seconds.")
    
    # 3. Wait for the Godot Timer to finish!
    await get_tree().create_timer(weave_time).timeout
    
    # 4. The Egg is ready!
    altar_is_weaving = false
    altar_egg_ready = true
    print("🥚 Egg is ready at the Altar!")

func _on_send_egg_pressed():
    var slot = find_free_slot()
    if slot == -1:
        print("Hatchery Books are full! Wait for a space.")
        return

    # 1. Send the egg to the Hatchery Books!
    var incubation_time = echo_database[altar_result_egg]["time"]
    start_job(slot, altar_result_egg, incubation_time)
    
    # 2. Give the parents back to the player
    my_collection.append(parent_a_name)
    my_collection.append(parent_b_name)
    parent_a_name = ""
    parent_b_name = ""
    
  # 3. Clean out the Altar
    altar_egg_ready = false
    altar_result_egg = ""
    
    # 🌟 NEW: Tell the physical altar to hide the egg!
    var altar_node = get_node_or_null("%WeavingAltar")
    if altar_node and altar_node.has_method("reset_altar"):
        altar_node.reset_altar()
    
    %HabitatMenu.visible = false
    update_ui()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        print("Books clicked! Opening Hatchery...")
        open_sanctuary("Hatchery")

    pass # Replace with function body.
    
    
func _on_roster_close_button_pressed():
    if has_node("%RosterPopup"): 
        %RosterPopup.visible = false
    print("Closed the Roster!")
    
    
    
func _on_collect_button_pressed():
    print("Global collect is disabled! Click the physical trees to harvest Ink.")
