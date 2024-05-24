-- Stats Indicator v1.0.7
-- SmoothSpatula

log.info("Successfully loaded ".._ENV["!guid"]..".")

-- ========== Loading ==========

-- Helper mod
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

-- Toml mod
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        pos_x = 160,
        pos_y = 150,
        scale = 1.0,
        stats_indicator_enabled = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

-- ========== Parameters ==========

local zoom_scale = 1.0
local ingame = false
local first_jump = 0
local kill_count = 0

local text_string = 
[[      STATS
ATTACK DAMAGE: %d
CRIT CHANCE: %.2f%%
ATTACK SPEED: %.2f
REGEN: %.2f

JUMP: %d/%d
X SPEED: %.2f/%.2f
Y SPEED: %.2f

ARMOR: %d
SHIELD: %d/%d
BARRIER: %.1f/%d

EXP: %.1f/%.1f
KILL COUNT: %d
MOUNTAIN SHRINE: %d
]]

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

-- ========== Main ==========


-- Draw some stats on the HUD
local shrine_count = 0
gm.post_code_execute(function(self, other, code, result, flags)
    if code.name:match("oInit_Draw_6") then
        if not params['stats_indicator_enabled'] then return end
        local player = Helper.get_client_player()
        local director = gm._mod_game_getDirector()
        if not player or not director then return end
        -- Find if the player use its first jump 
        -- player.jump_count doesn't count it
        if player.jump_count == 0 and player.pVspeed ~= 0.0 then first_jump = 1
        elseif first_jump == 1 and player.pVspeed == 0.0 then first_jump = 0 end

        -- Add the number of enemy killed the last frame to the kill count
        kill_count = kill_count + player.multikill

        -- Check if the teleporter exist and get it
        local tp = Helper.get_teleporter()
        if tp then 
            shrine_count = tp.mountain + director.mountain
        else shrine_count = 0 end

        -- Set font, Align horizontal left, Align vertical top
        gm.draw_set_font(5)
        gm.draw_set_halign(0)
        gm.draw_set_valign(0)

        --print(player.movement_speed)
        -- Draw stats
        gm.draw_text_transformed_colour(
            gm.display_get_gui_width()-(params['pos_x']*zoom_scale), 
            params['pos_y']*zoom_scale, 
            string.format(text_string,
                player.damage,                                              -- Attack Damage
                player.critical_chance,                                     -- Critical Strike Chance
                player.attack_speed,                                        -- Attack Speed
                player.hp_regen*60,                                         -- Regen   
                gm.item_count(player, 38)+1-player.jump_count-first_jump,   -- Remaining jumps
                gm.item_count(player, 38)+1,                                -- Max jumps
                math.abs(player.pHspeed),                                   -- Horizontal Speed 
                player.pHmax,                                               -- Max Horizontal Speed
                math.abs(player.pVspeed),                                   -- Vertical Speed
                player.armor,                                               -- Armor
                player.shield,                                              -- Shield
                player.maxshield,                                           -- Max Shield
                player.barrier,                                             -- Barrier
                player.maxbarrier,                                          -- Max Barrier
                director.player_exp,                                        -- Player exp
                director.player_exp_required,                               -- Player exp required for current level
                kill_count,                                                 -- Kill count
                shrine_count),                                              -- Mountain shrine count
            zoom_scale*params['scale'], 
            zoom_scale*params['scale'], 
            0, 8421504, 8421504, 8421504, 8421504, 1.0)
    end
end)

-- Get the current HUD scale for live resizing
gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    zoom_scale = gm.prefs_get_hud_scale()
end)

-- Enable mod when run start
gm.pre_script_hook(gm.constants.run_create, function(self, other, result, args)
    ingame = true
    print("test")
end)

-- Disable mod when run ends
gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    ingame = false
    kill_count = 0
end)
