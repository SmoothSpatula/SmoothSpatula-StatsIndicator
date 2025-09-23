-- Stats Indicator v1.0.13
-- SmoothSpatula

-- ========== Loading ==========
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
mods["SmoothSpatula-TomlHelper"].auto()

params = {
    pos_x = 160,
    pos_y = 150,
    scale = 1.0,
    stats_indicator_enabled = true,
    display_damage = true,
    display_crit = true,
    display_attack_speed = true,
    display_regen = true,
    display_jump = true,
    display_xspeed = true,
    display_yspeed = true,
    display_armor = true,
    display_shield = true,
    display_barrier = true,
    display_exp = true,
    display_kill = true,
    display_shrine = true,
}
params = Toml.config_update(_ENV["!guid"], params) -- Load Save
settings_tbl_imgui = {
    params['display_damage'],
    params['display_crit'],
    params['display_attack_speed'],
    params['display_regen'],
    params['display_jump'],
    params['display_xspeed'],
    params['display_yspeed'],
    params['display_armor'],
    params['display_shield'],
    params['display_barrier'],
    params['display_exp'],
    params['display_kill'],
    params['display_shrine'],
}
settings_tbl_hud = {
    params['display_damage'],
    params['display_crit'],
    params['display_attack_speed'],
    params['display_regen'],
    params['display_jump'],
    params['display_jump'],
    params['display_xspeed'],
    params['display_xspeed'],
    params['display_yspeed'],
    params['display_armor'],
    params['display_shield'],
    params['display_shield'],
    params['display_barrier'],
    params['display_barrier'],
    params['display_exp'],
    params['display_exp'],
    params['display_kill'],
    params['display_shrine'],
}

-- ========== Parameters ==========

local zoom_scale = 1.0
local ingame = false
local first_jump = 0
local kill_count = 0

local player = nil
local director = nil
local oInit = nil

local val_tbl = {}
local lookup_tbl = {}
local result_tbl = {}

local format_str = "      STATS"
local format_tbl = {
    "ATTACK DAMAGE: %.1f",
    "CRIT CHANCE: %.2f%%",
    "ATTACK SPEED: %.2f",
    "REGEN: %.2f",
    "JUMP: %d/%d",
    "X SPEED: %.2f/%.2f",
    "Y SPEED: %.2f",
    "ARMOR: %.1f",
    "SHIELD: %.1f/%.1f",
    "BARRIER: %.1f/%.1f",
    "EXP: %.1f/%.1f",
    "KILL COUNT: %d",
    "MOUNTAIN SHRINE: %d"
}

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Stats Indicator", params['stats_indicator_enabled'])
    if clicked then
        params['stats_indicator_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("X position from the right part of the screen", params['pos_x'], 1, 0, gm.display_get_gui_width()//zoom_scale)
    if clicked then
        params['pos_x'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("Y position from the top part of the screen", params['pos_y'], 1, 0, gm.display_get_gui_height()//zoom_scale)
    if clicked then
        params['pos_y'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, isChanged = ImGui.InputFloat("Scale of the text", params['scale'], 0.05, 0.2, "%.2f", 0)
    if isChanged and new_value >= -0.01 then -- due to floating point precision error, checking against 0 does not work
        params['scale'] = math.abs(new_value) -- same as above, so it display -0.0
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local hasChanged = false

    ImGui.Text("\tDisplay Stats")

    local new_value, pressed  = ImGui.Checkbox("Damage", params['display_damage'])
    if pressed then
        hasChanged = true
        params['display_damage'] = new_value
        settings_tbl_imgui[1] = new_value
        settings_tbl_hud[1] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Crit Chance", params['display_crit'])
    if pressed then
        hasChanged = true
        params['display_crit'] = new_value
        settings_tbl_imgui[2] = new_value
        settings_tbl_hud[2] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Attack Speed", params['display_attack_speed'])
    if pressed then
        hasChanged = true
        params['display_attack_speed'] = new_value
        settings_tbl_imgui[3] = new_value
        settings_tbl_hud[3] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Regen", params['display_regen'])
    if pressed then
        hasChanged = true
        params['display_regen'] = new_value
        settings_tbl_imgui[4] = new_value
        settings_tbl_hud[4] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Jump", params['display_jump'])
    if pressed then
        hasChanged = true
        params['display_jump'] = new_value
        settings_tbl_imgui[5] = new_value
        settings_tbl_hud[5] = new_value
        settings_tbl_hud[6] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("X Speed", params['display_xspeed'])
    if pressed then
        hasChanged = true
        params['display_xspeed'] = new_value
        settings_tbl_imgui[6] = new_value
        settings_tbl_hud[7] = new_value
        settings_tbl_hud[8] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Y Speed", params['display_yspeed'])
    if pressed then
        hasChanged = true
        params['display_yspeed'] = new_value
        settings_tbl_imgui[7] = new_value
        settings_tbl_hud[9] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Armor", params['display_armor'])
    if pressed then
        hasChanged = true
        params['display_armor'] = new_value
        settings_tbl_imgui[8] = new_value
        settings_tbl_hud[10] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Shield", params['display_shield'])
    if pressed then
        hasChanged = true
        params['display_shield'] = new_value
        settings_tbl_imgui[9] = new_value
        settings_tbl_hud[11] = new_value
        settings_tbl_hud[12] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Barrier", params['display_barrier'])
    if pressed then
        hasChanged = true
        params['display_barrier'] = new_value
        settings_tbl_imgui[10] = new_value
        settings_tbl_hud[13] = new_value
        settings_tbl_hud[14] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("XP", params['display_exp'])
    if pressed then
        hasChanged = true
        params['display_exp'] = new_value
        settings_tbl_imgui[11] = new_value
        settings_tbl_hud[15] = new_value
        settings_tbl_hud[16] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Kill Count", params['display_kill'])
    if pressed then
        hasChanged = true
        params['display_kill'] = new_value
        settings_tbl_imgui[12] = new_value
        settings_tbl_hud[17] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    local new_value, pressed  = ImGui.Checkbox("Mountain Shrine", params['display_shrine'])
    if pressed then
        hasChanged = true
        params['display_shrine'] = new_value
        settings_tbl_imgui[13] = new_value
        settings_tbl_hud[18] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end

    if hasChanged then 
        init() 
        hasChanged = false
    end
end)

-- ========== Main ==========

function init()
    format_str = "      STATS"
    -- create format_str  based on the settings_tbl_imgui
    for k, v in ipairs(settings_tbl_imgui) do
        if v then
        format_str=format_str.."\n"..format_tbl[k]
        end
    end

    -- create lookup_tbl based on the settings_tbl_hud
    local i = 1
    for k, v in ipairs(settings_tbl_hud) do
        if v then
        lookup_tbl[i] = k
        i = i+1
        end
    end
end

function get_vals(player, director)

    -- Find if the player use its first jump 
    -- player.jump_count doesn't count it
    if player.jump_count == 0 and player.pVspeed ~= 0.0 then first_jump = 1
    elseif first_jump == 1 and player.pVspeed == 0.0 then first_jump = 0 end

    -- Get the kill_count from the game_report
    if oInit and oInit.player then
        kill_count = oInit.player[1].game_report.kills
    end

    -- Check if the teleporter exist and get it
    local tp = Instance.find(Instance.teleporters)
    local tpMountain = 0
    if tp:exists() then tpMountain = tp.mountain end
    return {
        player.damage or 0,                                              -- Attack Damage
        player.critical_chance or 0,                                     -- Critical Strike Chance
        player.attack_speed or 0,                                        -- Attack Speed
        (player.hp_regen or 0)*60,                                       -- Regen   
        gm.item_count(player, 38)+1-(player.jump_count or 0)-first_jump, -- Remaining jumps
        gm.item_count(player, 38)+1,                                     -- Max jumps
        math.abs(player.pHspeed or 0),                                   -- Horizontal Speed 
        player.pHmax or 0,                                               -- Max Horizontal Speed
        math.abs(player.pVspeed or 0),                                   -- Vertical Speed
        player.armor or 0,                                               -- Armor
        player.shield or 0,                                              -- Shield
        player.maxshield or 0,                                           -- Max Shield
        player.barrier or 0,                                             -- Barrier
        player.maxbarrier or 0,                                          -- Max Barrier
        director.player_exp or 0,                                        -- Player exp
        director.player_exp_required or 0,                               -- Player exp required for current level
        kill_count or 0,                                                 -- Kill count
        tpMountain + (director.mountain or 0)                             -- Mountain shrine count
    }
end

-- Draw some stats on the HUD
gm.post_code_execute("gml_Object_oInit_Draw_64", function(self, other)
    zoom_scale = gm.prefs_get_hud_scale()
    if not gm.variable_global_get("__run_exists") or self.chat_talking or not params['stats_indicator_enabled'] then return end
    if not player or player.value == nil or player.value == -4 or director == -4 or director == nil then -- idk how to chekc this animore pls help
        player = Player.get_client()
        director = gm._mod_game_getDirector()
        oInit = gm.instance_find(gm.constants.oInit, 0)
        return 
    end

    -- create a result_tbl from the lookup_tbl and val_tbl

    if player.value == nil or player.value == -4 then return end

    val_tbl = get_vals(player.value, director)
    for i=1, #lookup_tbl do
    result_tbl[i] = val_tbl[lookup_tbl[i]]
    end
    
    -- Set font, Align horizontal left, Align vertical top
    gm.draw_set_font(5)
    gm.draw_set_halign(0)
    gm.draw_set_valign(0)

    -- Draw stats
    gm.draw_text_transformed_colour(
        gm.display_get_gui_width()-(params['pos_x']*zoom_scale), 
        params['pos_y']*zoom_scale, 
        string.format(format_str, table.unpack(result_tbl)),                           -- Mountain shrine count
        zoom_scale*params['scale'], 
        zoom_scale*params['scale'], 
        0, 8421504, 8421504, 8421504, 8421504, 1.0)
end)

-- Get the current HUD scale for live resizing
-- gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
--     zoom_scale = 
-- end)

-- Enable mod when run start
gm.pre_script_hook(gm.constants.run_create, function(self, other, result, args)
    player = nil
    kill_count = 0
end)

gm.post_script_hook(gm.constants.actor_kill, function(self, other, result, args)
    print("actor kill")
    print(gm.object_get_name(self))
    print(gm.object_get_name(other))
end)

Initialize(init)
log.info("Successfully loaded ".._ENV["!guid"]..".")

if reload then init() end
reload = true