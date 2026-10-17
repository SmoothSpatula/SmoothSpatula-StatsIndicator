-- Stats Indicator
-- SmoothSpatula

-- ========== Loading ==========
mods["ReturnsAPI-ReturnsAPI"].auto {
    namespace = "statsindicator",
    mp = true
}

mods["SmoothSpatula-TomlHelper"].auto()

-- ========== Configuration ==========

params = Toml.config_update(_ENV["!guid"], {
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
})

local display_settings = {
    { "Damage",          "display_damage",        "ATTACK DAMAGE: %.1f",    {1} },
    { "Crit Chance",     "display_crit",          "CRIT CHANCE: %.2f%%",    {2} },
    { "Attack Speed",    "display_attack_speed",  "ATTACK SPEED: %.2f",     {3} },
    { "Regen",           "display_regen",         "REGEN: %.2f",            {4} },
    { "Jump",            "display_jump",          "JUMP: %d/%d",            {5, 6} },
    { "X Speed",         "display_xspeed",        "X SPEED: %.2f/%.2f",     {7, 8} },
    { "Y Speed",         "display_yspeed",        "Y SPEED: %.2f",          {9} },
    { "Armor",           "display_armor",         "ARMOR: %.1f",            {10} },
    { "Shield",          "display_shield",        "SHIELD: %.1f/%.1f",      {11, 12} },
    { "Barrier",         "display_barrier",       "BARRIER: %.1f/%.1f",     {13, 14} },
    { "XP",              "display_exp",           "EXP: %.1f/%.1f",         {15, 16} },
    { "Kill Count",      "display_kill",          "KILL COUNT: %d",         {17} },
    { "Mountain Shrine", "display_shrine",        "MOUNTAIN SHRINE: %d",    {18} },
}

-- ========== Parameters ==========

local zoom_scale = 1.0
local first_jump = 0
local kill_count = 0

local player    = nil
local director  = nil
local oInit     = nil
local tp        = nil

local lookup_tbl = {}
local format_str = "      STATS"

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local value, changed = ImGui.Checkbox(
        "Enable Stats Indicator",
        params.stats_indicator_enabled
    )

    if changed then
        params.stats_indicator_enabled = value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local value, changed = ImGui.DragInt(
        "X position from the right part of the screen",
        params.pos_x, 1, 0, gm.display_get_gui_width() // zoom_scale
    )

    if changed then
        params.pos_x = value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local value, changed = ImGui.DragInt(
        "Y position from the top part of the screen",
        params.pos_y, 1, 0, gm.display_get_gui_height() // zoom_scale
    )

    if changed then
        params.pos_y = value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local value, changed = ImGui.InputFloat(
        "Scale of the text", params.scale, 0.05, 0.2, "%.2f", 0
    )

    if changed and value >= -0.01 then
        params.scale = math.abs(value)
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    ImGui.Text("\tDisplay Stats")

    local changed = false

    for _, stat in ipairs(display_settings) do
        local value, pressed = ImGui.Checkbox(
            stat[1], params[stat[2]]
        )

        if pressed then
            params[stat[2]] = value
            changed = true
        end
    end

    if changed then
        Toml.save_cfg(_ENV["!guid"], params)
        init()
    end
end)

-- ======== ModOptions ======

local modOptions = ModOptions.new()

local function add_checkbox(id, key)
    local checkbox = modOptions:add_checkbox(id)

    checkbox:add_getter(function()
        return params[key]
    end)

    checkbox:add_setter(function(value)
        params[key] = value
        Toml.save_cfg(_ENV["!guid"], params)
        init()
    end)
end

add_checkbox("stats_indicator_enabled", "stats_indicator_enabled")

for _, setting in ipairs(display_settings) do
    add_checkbox("stats."..setting[2], setting[2], init)
end

-- ========== Main ==========

function init()
    format_str = "      STATS"
    lookup_tbl = {}

    for _, stat in ipairs(display_settings) do
        if params[stat[2]] then
            format_str = format_str .. "\n" .. stat[3]

            for _, index in ipairs(stat[4]) do
                lookup_tbl[#lookup_tbl + 1] = index
            end
        end
    end
end

local function get_vals(player, director)
    -- Account for the first jump, which jump_count does not track
    if player.jump_count == 0 and player.pVspeed ~= 0.0 then
        first_jump = 1
    elseif first_jump == 1 and player.pVspeed == 0.0 then
        first_jump = 0
    end


    if oInit and oInit.player and oInit.player[1] and oInit.player[1].game_report then
        kill_count = oInit.player[1].game_report.kills
    end

    if Instance.exists(tp) then
        tpMountain = tp.mountain or 0
    else
        tpMountain = 0
    end

    return {
        player.damage,                                                  -- 1: Attack damage
        player.critical_chance,                                         -- 2: Crit chance
        player.attack_speed,                                            -- 3: Attack speed
        (player.hp_regen) * 60,                                         -- 4: Regen
        gm.item_count(player, 38) + 1 - player.jump_count - first_jump, -- 5: Remaining jumps
        gm.item_count(player, 38) + 1,                                  -- 6: Maximum jumps
        math.abs(player.pHspeed),                                       -- 7: Horizontal speed
        player.pHmax,                                                   -- 8: Maximum horizontal speed
        math.abs(player.pVspeed),                                       -- 9: Vertical speed
        player.armor,                                                   -- 10: Armor
        player.shield,                                                  -- 11: Shield
        player.maxshield,                                               -- 12: Maximum shield
        player.barrier,                                                 -- 13: Barrier
        player.maxbarrier,                                              -- 14: Maximum barrier
        director.player_exp,                                            -- 15: Current XP
        director.player_exp_required,                                   -- 16: XP required
        kill_count,                                                     -- 17: Kill count
        tpMountain + director.mountain                                  -- 18: Mountain shrines
    }
end

-- ========== HUD ==========

Callback.add(Callback.ON_HUD_DRAW, function()
    if not params.stats_indicator_enabled then return end

    zoom_scale = gm.prefs_get_hud_scale()

    -- Refresh references when necessary.
    if not player or player.value == nil or player.value == -4
        or director == nil or director == -4 then
        player = Player.get_local()
        director = gm._mod_game_getDirector()
        oInit = gm.instance_find(gm.constants.oInit, 0)
        return
    end

    if not director then return end

    local values = get_vals(player.value, director)
    local result_tbl = {}

    for _, index in ipairs(lookup_tbl) do
        local value = values[index]
        result_tbl[#result_tbl + 1] =
            type(value) == "number" and value or 0
    end

    gm.draw_set_font(5)
    gm.draw_set_halign(0)
    gm.draw_set_valign(0)

    gm.draw_text_transformed_colour(
        gm.display_get_gui_width() - params.pos_x * zoom_scale,
        params.pos_y * zoom_scale,
        string.format(format_str, table.unpack(result_tbl)),
        zoom_scale * params.scale,
        zoom_scale * params.scale,
        0,
        8421504, 8421504, 8421504, 8421504,
        1.0
    )
end)

-- ========== Lifecycle ==========

Callback.add(Callback.ON_PLAYER_INIT, function(self)
    if not self == Player.get_local() then return end
    player = self.value
    director = nil
    oInit = nil
    kill_count = 0
    first_jump = 0
end)

Callback.add(Callback.ON_STAGE_START, function()
    tp = Instance.find(gm.constants.oTeleporter, 1)
    if not Instance.exists(tp) then
        tp = Instance.find(gm.constants.oTeleporterEpic, 1)
    end
end)

Initialize.add_hotloadable(init)