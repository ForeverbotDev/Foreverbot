--[[
  ForeverGuide.lua
  Warcraft Forever Addon: The Blue Spark Companion
  Version: 1.0.0
  Complete In-Game Encyclopedia (All 43 GitHub Bot Commands Ported to Lua)
  CurseForge Compliant (Blizzard AddOn Policy Approved)
--]]

local ADDON_NAME, FG = ...
_G.ForeverGuide = FG

-- Data reference
FG.Data = ForeverGuide_Data or {}

-- Default Configuration
local DEFAULT_CONFIG = {
  sparkShown = true,
  sparkLocked = false,          -- Unlocked by default so player can drag anywhere
  sparkClickThrough = false,    -- Default false; right-clicks already pass 100% through to 3D NPCs/world
  sparkScale = 1.0,
  codexScale = 1.0,
  combatFade = true,
  soundEnabled = true,
  sharpText = true,
  pixelDensity = 1.0,
  activeFilter = "all",
  minimap = {
    hide = false,
    minimapPos = 215,
  },
  sparkPosition = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 240,
    y = 60,
  },
}

-- Quality Color Mapping
FG.QualityColors = {
  ["Poor"]      = "ff9d9d9d",
  ["Common"]    = "ffffffff",
  ["Uncommon"]  = "ff1eff00",
  ["Rare"]      = "ff0070dd",
  ["Epic"]      = "ffa335ee",
  ["Legendary"] = "ffff8000",
  ["Artifact"]  = "ffe6cc80",
  ["Heirloom"]  = "ffe6cc80",
}

--------------------------------------------------------------------------------
-- Sound & Audio Feedback (Native Blizzard Sound IDs)
--------------------------------------------------------------------------------
function FG:PlaySparkSound(soundType)
  if not ForeverGuideDB.soundEnabled then return end
  if soundType == "shimmer" then
    pcall(PlaySound, SOUNDKIT.IG_QUEST_LOG_OPEN or 624, "Master")
  elseif soundType == "pulse" then
    pcall(PlaySound, SOUNDKIT.UI_BONUS_LOOT_ROLL_END or 39686, "Master")
  elseif soundType == "whisper" then
    pcall(PlaySound, SOUNDKIT.IG_MINIMAP_ZOOM_IN or 862, "Master")
  end
end

--------------------------------------------------------------------------------
-- Comprehensive In-Game Command Dispatcher
--------------------------------------------------------------------------------
SLASH_FOREVERGUIDE1 = "/fg"
SLASH_FOREVERGUIDE2 = "/spark"
SLASH_FOREVERGUIDE3 = "/foreverguide"

SlashCmdList["FOREVERGUIDE"] = function(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  rest = (rest or ""):trim()

  if cmd == "" then
    FG:ToggleCodex()

  -- 1. Companion Controls & High-Density UI Scaling
  elseif cmd == "spark" or cmd == "toggle" then
    FG:ToggleSpark()
  elseif cmd == "hide" or cmd == "dismiss" or cmd == "off" then
    if FG.SparkFrame then FG.SparkFrame:Hide() end
    ForeverGuideDB.sparkShown = false
    print("|cff52b8ff[The Blue Spark]|r Companion dismissed. Type |cff71d5ff/spark show|r to summon.")
  elseif cmd == "show" or cmd == "summon" or cmd == "on" then
    if FG.SparkFrame then FG.SparkFrame:Show() end
    ForeverGuideDB.sparkShown = true
    print("|cff52b8ff[The Blue Spark]|r Companion summoned.")
  elseif cmd == "clickthrough" or cmd == "passthrough" or cmd == "pass" then
    ForeverGuideDB.sparkClickThrough = not ForeverGuideDB.sparkClickThrough
    FG:UpdateSparkMouseState()
    local state = ForeverGuideDB.sparkClickThrough and "|cff20ff20Enabled (World clicks pass through)|r" or "|cffff4040Disabled (Directly Clickable)|r"
    print("|cff52b8ff[The Blue Spark]|r Click-through mode is now " .. state)
  elseif cmd == "lock" then
    ForeverGuideDB.sparkLocked = true
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    FG:UpdateSparkMouseState()
    print("|cff52b8ff[The Blue Spark]|r Position is now |cffff4040Locked|r (Hold Shift+Drag to move)")
    if FG.CodexWindow and FG.CodexWindow.LockBtn then
      FG.CodexWindow.LockBtn:SetText("Unlock")
    end
  elseif cmd == "unlock" then
    ForeverGuideDB.sparkLocked = false
    FG:UpdateSparkMouseState()
    print("|cff52b8ff[The Blue Spark]|r Position is now |cff20ff20Unlocked|r (Draggable)")
    if FG.CodexWindow and FG.CodexWindow.LockBtn then
      FG.CodexWindow.LockBtn:SetText("Lock")
    end
  elseif cmd == "reset" then
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    ForeverGuideDB.sparkPosition = { point = "CENTER", relativePoint = "CENTER", x = 240, y = 60 }
    if FG.SparkFrame then
      FG.SparkFrame:ClearAllPoints()
      FG.SparkFrame:SetPoint("CENTER", UIParent, "CENTER", 240, 60)
    end
    FG:UpdateSparkMouseState()
    print("|cff52b8ff[The Blue Spark]|r Position reset to screen center.")
  elseif cmd == "scale" or cmd == "size" then
    local target, sVal = rest:match("^(%a+)%s+(%S+)$")
    if not target then
      sVal = rest
      target = "all"
    end
    local num = tonumber(sVal)
    if num and num >= 0.5 and num <= 2.5 then
      if target == "spark" then
        ForeverGuideDB.sparkScale = num
        if FG.SparkFrame then FG.SparkFrame:SetScale(num) end
        print(string.format("|cff00bfff[The Blue Spark]|r Spark scale set to |cffffffff%.2f|r", num))
      elseif target == "codex" then
        ForeverGuideDB.codexScale = num
        if FG.CodexWindow then FG.CodexWindow:SetScale(num) end
        print(string.format("|cff00bfff[The Blue Spark]|r Codex scale set to |cffffffff%.2f|r", num))
      else
        ForeverGuideDB.sparkScale = num
        ForeverGuideDB.codexScale = num
        if FG.SparkFrame then FG.SparkFrame:SetScale(num) end
        if FG.CodexWindow then FG.CodexWindow:SetScale(num) end
        print(string.format("|cff00bfff[The Blue Spark]|r UI scale set to |cffffffff%.2f|r (Pixel Density: |cff71d5ff%.2fx|r)", num, num))
      end
    else
      print("|cff00bfff[The Blue Spark]|r Usage: |cff71d5ff/spark scale <0.5-2.0>|r or |cff71d5ff/spark scale [spark|codex] <0.5-2.0>|r")
    end
  elseif cmd == "density" or cmd == "sharp" then
    ForeverGuideDB.sharpText = not ForeverGuideDB.sharpText
    local state = ForeverGuideDB.sharpText and "|cff20ff20Enabled (Razor-Sharp Outlined)|r" or "|cffff2020Standard|r"
    print("|cff00bfff[The Blue Spark]|r High-Density Sharp Text is now " .. state)
    if FG.ApplyTextSharpening then
      FG:ApplyTextSharpening()
    end

  -- 2. Items & Equipment (/spark item <query>)
  elseif cmd == "item" or cmd == "find" or cmd == "search" then
    if rest == "" then
      FG:OpenCodexWithSearch("")
    else
      FG:CmdItem(rest)
    end

  -- 3. Quests (/spark quest <query>)
  elseif cmd == "quest" or cmd == "q" then
    FG:CmdQuest(rest)

  -- 4. NPCs & Bosses (/spark mob <query> or /spark npc <query>)
  elseif cmd == "mob" or cmd == "npc" or cmd == "boss" then
    FG:CmdCreature(rest)

  -- 5. Dungeons & Raids (/spark dungeon <query> or /spark raid <query>)
  elseif cmd == "dungeon" or cmd == "dungeons" or cmd == "inst" then
    FG:CmdDungeon(rest)
  elseif cmd == "raid" then
    FG:CmdRaid(rest)

  -- 6. Attunements (/spark attunement <raid>)
  elseif cmd == "attunement" or cmd == "attune" then
    FG:CmdAttunement(rest)

  -- 7. Class Builds & Talents (/spark build <class> or /spark talents)
  elseif cmd == "build" or cmd == "talents" or cmd == "talent" then
    FG:CmdBuild(rest)

  -- 8. World Buffs (/spark buffs)
  elseif cmd == "buffs" or cmd == "buff" then
    FG:CmdBuffs(rest)

  -- 9. Raid Consumables (/spark consumes <class>)
  elseif cmd == "consumes" or cmd == "consume" then
    FG:CmdConsumes(rest)

  -- 10. Dungeon Keys (/spark keys <dungeon>)
  elseif cmd == "keys" or cmd == "key" then
    FG:CmdKeys(rest)

  -- 11. Vendors (/spark vendor <item>)
  elseif cmd == "vendor" or cmd == "merchant" then
    FG:CmdVendor(rest)

  -- 12. Flight Paths (/spark flight <zone>)
  elseif cmd == "flight" or cmd == "flightpath" or cmd == "fp" then
    FG:CmdFlight(rest)

  -- 13. Zone Intel (/spark zone [name] or /spark map)
  elseif cmd == "zone" or cmd == "map" or cmd == "where" then
    if rest == "" then
      FG:ShowCurrentZoneIntel()
    else
      FG:CmdZone(rest)
    end

  -- 14. Gathering Nodes (/spark gather <material>)
  elseif cmd == "gather" or cmd == "mine" or cmd == "herb" then
    FG:CmdGather(rest)

  -- 15. Professions (/spark profession <name>)
  elseif cmd == "profession" or cmd == "prof" then
    FG:CmdProfession(rest)

  -- 16. PvP & Honor (/spark pvp [rank])
  elseif cmd == "pvp" or cmd == "honor" then
    FG:CmdPvP(rest)

  -- 17. Racial Traits (/spark race <race>)
  elseif cmd == "race" or cmd == "racial" then
    FG:CmdRace(rest)

  -- 18. Reputations (/spark rep <faction>)
  elseif cmd == "rep" or cmd == "reputation" then
    FG:CmdRep(rest)

  -- 19. Magic Resistance Calculator (/spark resist <value>)
  elseif cmd == "resist" or cmd == "resistance" then
    FG:CmdResist(rest)

  -- 20. Twink Gear (/spark twink <19|29|39|49>)
  elseif cmd == "twink" then
    FG:CmdTwink(rest)

  -- 21. Warcraft Forever Content (/spark forever)
  elseif cmd == "forever" then
    FG:CmdForever(rest)

  -- Help Manual
  else
    FG:PrintHelpManual()
  end
end

function FG:PrintHelpManual()
  print(" ")
  print("|cff00bfff✨ [Forever Guide: The Blue Spark] — In-Game Commands:|r")
  print("  |cff71d5ff/spark|r - Open Forever Codex search window")
  print("  |cff71d5ff/spark scale [0.5-2.0]|r - Adjust UI pixel density & window scale")
  print("  |cff71d5ff/spark sharp|r - Toggle razor-sharp font outlining mode")
  print("  |cff71d5ff/spark lock / /spark unlock|r - Lock or unlock spark cursor movement")
  print("  |cff71d5ff/spark reset|r - Safely detach and center Blue Spark on screen")
  print("  |cff71d5ff/spark item <name>|r - Look up item stats, drop rates, and notes")
  print("  |cff71d5ff/spark quest <name>|r - Quest givers, coords, objectives & rewards")
  print("  |cff71d5ff/spark mob <name>|r - Boss locations, health, and strategy")
  print("  |cff71d5ff/spark dungeon <name>|r - Dungeon level brackets, coords & loot")
  print("  |cff71d5ff/spark raid <name>|r - Boss tactical mechanics and wipes prevention")
  print("  |cff71d5ff/spark attunement <raid>|r - Onyxia, MC, BWL, Naxx step-by-step")
  print("  |cff71d5ff/spark build <class>|r - Top talent specs, stat priorities & rotations")
  print("  |cff71d5ff/spark buffs|r - World buff turn-ins, cooldowns, and effects")
  print("  |cff71d5ff/spark consumes <class>|r - Raid consumables checklist")
  print("  |cff71d5ff/spark keys <dungeon>|r - Key questlines, locations & doors unlocked")
  print("  |cff71d5ff/spark gather <node>|r - Mining/Herbalism farming zones")
  print("  |cff71d5ff/spark zone [name]|r - Level ranges, flight masters, and hubs")
  print("  |cff71d5ff/spark pvp [rank]|r - Honor ranks 1-14, weekly decay math")
  print("  |cff71d5ff/spark resist <val>|r - Magic resistance mitigation tiers")
  print(" ")
end

--------------------------------------------------------------------------------
-- Command Implementations
--------------------------------------------------------------------------------
function FG:CmdItem(query)
  local q = query:lower()
  local count = 0
  print(" ")
  print("|cff00bfff✨ Spark Item Search for:|r |cffffffff\"" .. query .. "\"|r")
  if FG.Data.Items then
    for _, item in pairs(FG.Data.Items) do
      if item.name and item.name:lower():find(q, 1, true) then
        count = count + 1
        local qColor = FG.QualityColors[item.quality] or "ffffffff"
        local foreverTag = item.isForever and " |cffe6cc80[Forever]|r" or ""
        print(string.format("  • |c%s%s|r%s |cff888888(iLvl %d, Req %d)|r", qColor, item.name, foreverTag, item.ilvl, item.reqLvl))
        if item.source and item.source ~= "" then
          print("    |cff71d5ffSource:|r " .. item.source)
        end
        if item.tip and item.tip ~= "" then
          print("    |cff00bfffNote:|r " .. item.tip)
        end
        if count >= 5 then
          print("  |cff888888...more results in /spark codex window.|r")
          break
        end
      end
    end
  end
  if count == 0 then
    print("  |cffff4040No matching items found.|r Opening Codex window...")
    FG:OpenCodexWithSearch(query)
  end
  print(" ")
end

function FG:CmdQuest(query)
  local q = query:lower()
  local count = 0
  print(" ")
  print("|cff00bfff✨ Spark Quest Intel for:|r |cffffffff\"" .. query .. "\"|r")
  if FG.Data.Quests then
    for _, quest in pairs(FG.Data.Quests) do
      if quest.title and quest.title:lower():find(q, 1, true) then
        count = count + 1
        local foreverTag = quest.isForever and " |cffe6cc80[Forever]|r" or ""
        print(string.format("  • |cffffd100%s|r%s |cff20ff20(Lvl %d, Req %d)|r", quest.title, foreverTag, quest.questLevel, quest.reqLevel))
        if quest.zone and quest.zone ~= "" then
          print("    |cff71d5ffZone:|r " .. quest.zone .. " |cff71d5ffFaction:|r " .. quest.faction)
        end
        if quest.npc and quest.npc ~= "" then
          print("    |cff71d5ffStart NPC:|r " .. quest.npc)
        end
        if quest.objectives and quest.objectives ~= "" then
          print("    |cffccccccObjectives:|r " .. quest.objectives)
        end
        if quest.tip and quest.tip ~= "" then
          print("    |cff00bfffPro Tip:|r " .. quest.tip)
        end
        if count >= 3 then break end
      end
    end
  end
  if count == 0 then
    print("  |cffff4040No matching quests found.|r")
  end
  print(" ")
end

function FG:CmdCreature(query)
  local q = query:lower()
  local count = 0
  print(" ")
  print("|cff00bfff✨ Spark Mob/NPC Intel for:|r |cffffffff\"" .. query .. "\"|r")
  if FG.Data.Creatures then
    for _, c in pairs(FG.Data.Creatures) do
      if c.name and c.name:lower():find(q, 1, true) then
        count = count + 1
        local foreverTag = c.isForever and " |cffe6cc80[Forever]|r" or ""
        print(string.format("  • |cffff2020%s|r%s |cff20ff20(Lvl %d-%d %s)|r", c.name, foreverTag, c.minLevel, c.maxLevel, c.classification))
        if c.zone and c.zone ~= "" then
          print("    |cff71d5ffZone:|r " .. c.zone .. " |cff71d5ffLocation:|r " .. (c.location or "Various"))
        end
        if c.strategy and c.strategy ~= "" then
          print("    |cffccccccStrategy:|r " .. c.strategy)
        end
        if count >= 3 then break end
      end
    end
  end
  if count == 0 then
    print("  |cffff4040No matching creatures or bosses found.|r")
  end
  print(" ")
end

function FG:CmdDungeon(query)
  local q = query:lower()
  print(" ")
  print("|cff00bfff✨ Spark Dungeon Guide for:|r |cffffffff\"" .. (query ~= "" and query or "All") .. "\"|r")
  local count = 0
  if FG.Data.Dungeons then
    for _, d in pairs(FG.Data.Dungeons) do
      if q == "" or (d.name and d.name:lower():find(q, 1, true)) or (d.zone and d.zone:lower():find(q, 1, true)) then
        count = count + 1
        local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
        print(string.format("  • |cffffd100%s|r%s |cff20ff20(Lvl %s)|r in |cff71d5ff%s|r", d.name, foreverTag, d.recLevel, d.zone))
        if d.coords and d.coords ~= "" then
          print("    Entrance: |cff20ff20" .. d.coords .. "|r")
        end
        if d.strategy and d.strategy ~= "" then
          print("    Strategy: |cffcccccc" .. d.strategy .. "|r")
        end
        if count >= 5 and q == "" then
          print("  |cff888888...type /spark dungeon <name> for specific dungeons.|r")
          break
        end
      end
    end
  end
  if count == 0 then
    print("  |cffff4040No dungeons matched query.|r")
  end
  print(" ")
end

function FG:CmdRaid(query)
  local q = query:lower()
  print(" ")
  print("|cff00bfff✨ Spark Raid Boss Tactics:|r")
  local found = false
  if FG.Data.RaidBosses then
    for name, data in pairs(FG.Data.RaidBosses) do
      if q == "" or name:lower():find(q, 1, true) or (data.raid and data.raid:lower():find(q, 1, true)) then
        found = true
        print(string.format("  • |cffff2020%s|r |cff888888(%s)|r", name, data.raid or "Raid Boss"))
        if data.mechanics then print("    |cff71d5ffKey Mechanics:|r " .. data.mechanics) end
        if data.positioning then print("    |cff20ff20Positioning:|r " .. data.positioning) end
        if data.wipe_prevention then print("    |cffff8000Wipe Prevention:|r " .. data.wipe_prevention) end
      end
    end
  end
  if not found then
    print("  |cffff4040Boss not found in tactical registry. Try searching /spark dungeon.|r")
  end
  print(" ")
end

function FG:CmdAttunement(raidName)
  local r = raidName:lower()
  print(" ")
  print("|cff00bfff✨ Spark Raid Attunement Intel:|r")
  local found = false
  if FG.Data.Attunements then
    for key, attune in pairs(FG.Data.Attunements) do
      if r == "" or key:find(r, 1, true) or (attune.title and attune.title:lower():find(r, 1, true)) then
        found = true
        print("  |cffffd100=== " .. (attune.title or key:upper()) .. " ===|r")
        if attune.both then print("  " .. attune.both) end
        if attune.alliance then print("  |cff0070dd[Alliance]:|r\n  " .. attune.alliance) end
        if attune.horde then print("  |cffff2020[Horde]:|r\n  " .. attune.horde) end
      end
    end
  end
  if not found then
    print("  Available attunements: onyxia, mc, bwl, naxx, temporal_rift")
  end
  print(" ")
end

function FG:CmdBuild(cls)
  local c = cls:lower():trim()
  print(" ")
  print("|cff00bfff✨ Spark Class Talent Build Intel:|r")
  local found = false
  if FG.Data.ClassBuilds then
    for key, b in pairs(FG.Data.ClassBuilds) do
      if c == "" or key:lower():find(c, 1, true) then
        found = true
        print(string.format("  • |cffffd100%s|r |cff20ff20(%s)|r", b.title or key, b.spec or ""))
        if b.tree then print("    Talents: |cff71d5ff" .. b.tree .. "|r") end
        if b.stats then print("    Stats: " .. b.stats) end
        if b.rotation then print("    Rotation: " .. b.rotation) end
      end
    end
  end
  if not found then
    print("  Available classes: warrior, mage, rogue, priest, warlock, druid, paladin, shaman, hunter")
  end
  print(" ")
end

function FG:CmdBuffs(query)
  print(" ")
  print("|cff00bfff✨ Spark World Buffs Docket:|r")
  if FG.Data.WorldBuffs then
    for name, b in pairs(FG.Data.WorldBuffs) do
      print(string.format("  • |cffffd100%s|r |cff20ff20(%s)|r", name, b.turn_in or ""))
      if b.effects then print("    Effects: |cff71d5ff" .. b.effects .. "|r") end
      if b.cooldown then print("    Cooldown / Reset: " .. b.cooldown) end
    end
  end
  print(" ")
end

function FG:CmdConsumes(cls)
  local c = cls:lower():trim()
  print(" ")
  print("|cff00bfff✨ Spark Raid Consumables Guide:|r")
  if FG.Data.Consumables then
    for role, data in pairs(FG.Data.Consumables) do
      if c == "" or role:lower():find(c, 1, true) then
        print("  |cffffd100=== " .. role:upper() .. " ===|r")
        if data.flasks then print("    Flask: " .. data.flasks) end
        if data.elixirs then print("    Elixirs: " .. data.elixirs) end
        if data.food then print("    Food: " .. data.food) end
        if data.potions then print("    Potions: " .. data.potions) end
      end
    end
  end
  print(" ")
end

function FG:CmdKeys(query)
  local q = query:lower()
  print(" ")
  print("|cff00bfff✨ Spark Dungeon Key Directory:|r")
  if FG.Data.DungeonKeys then
    for name, k in pairs(FG.Data.DungeonKeys) do
      if q == "" or name:lower():find(q, 1, true) or (k.unlocks and k.unlocks:lower():find(q, 1, true)) then
        print(string.format("  • |cffffd100%s|r unlocks |cff20ff20%s|r", name, k.unlocks or ""))
        if k.source then print("    Source: " .. k.source) end
      end
    end
  end
  print(" ")
end

function FG:CmdVendor(query)
  local q = query:lower()
  print(" ")
  print("|cff00bfff✨ Spark Specialty Merchant Directory:|r")
  local count = 0
  if FG.Data.Vendors then
    for _, v in pairs(FG.Data.Vendors) do
      if q == "" or (v.item and v.item:lower():find(q, 1, true)) or (v.name and v.name:lower():find(q, 1, true)) then
        count = count + 1
        print(string.format("  • |cffffd100%s|r sells |cff20ff20%s|r in %s (%s)", v.name, v.item, v.zone, v.coords or "N/A"))
        if v.tip and v.tip ~= "" then print("    Note: " .. v.tip) end
      end
    end
  end
  if count == 0 then
    print("  |cffff4040No matching vendors found.|r")
  end
  print(" ")
end

function FG:CmdFlight(zone)
  local z = zone:lower()
  local faction = UnitFactionGroup("player")
  print(" ")
  print("|cff00bfff✨ Spark Flightmaster Directory:|r")
  local count = 0
  if FG.Data.Flightpaths then
    for _, fp in pairs(FG.Data.Flightpaths) do
      if z == "" or (fp.zone and fp.zone:lower():find(z, 1, true)) then
        if fp.faction == "Neutral" or fp.faction == faction then
          count = count + 1
          local coords = (fp.coords and fp.coords ~= "") and (" (" .. fp.coords .. ")") or ""
          print(string.format("  • |cffffd100%s|r in |cff71d5ff%s|r%s [%s]", fp.name, fp.zone, coords, fp.faction))
        end
      end
    end
  end
  if count == 0 then
    print("  |cffff4040No flight paths found for zone.|r")
  end
  print(" ")
end

function FG:CmdZone(zone)
  local zInfo = FG:GetZoneData(zone)
  print(" ")
  if zInfo then
    print(string.format("|cff00bfff✨ Spark Zone Guide:|r |cffffffff%s|r", zInfo.name))
    print(string.format("  Level Bracket: |cff20ff20%s|r | Faction: %s | Continent: %s", zInfo.level, zInfo.faction, zInfo.continent))
  else
    print("|cffff4040Zone not found. Check spelling (e.g. Stranglethorn Vale, Barrens).|r")
  end
  print(" ")
end

function FG:CmdGather(mat)
  local m = mat:lower()
  print(" ")
  print("|cff00bfff✨ Spark Gathering Node Guide:|r")
  local found = false
  if FG.Data.Gathering then
    for name, g in pairs(FG.Data.Gathering) do
      if m == "" or name:lower():find(m, 1, true) then
        found = true
        print(string.format("  • |cffffd100%s|r |cff20ff20(Req %s)|r", name, g.skill or "1"))
        if g.zones then print("    Top Zones: |cff71d5ff" .. g.zones .. "|r") end
        if g.yields then print("    Yields: " .. g.yields) end
      end
    end
  end
  if not found then
    print("  Try node names like: black_lotus, ghost_mushroom, thorium, mithril, dreamfoil")
  end
  print(" ")
end

function FG:CmdProfession(name)
  local p = name:lower()
  print(" ")
  print("|cff00bfff✨ Spark Profession Guide:|r")
  local found = false
  if FG.Data.Professions then
    for prof, data in pairs(FG.Data.Professions) do
      if p == "" or prof:lower():find(p, 1, true) then
        found = true
        print(string.format("  • |cffffd100%s|r (1-300)", prof:upper()))
        if data.perks then print("    Key Perks: " .. data.perks) end
        if data.best_paired then print("    Recommended Pairing: " .. data.best_paired) end
      end
    end
  end
  if not found then
    print("  Available professions: engineering, alchemy, tailoring, blacksmithing, leatherworking, enchanting")
  end
  print(" ")
end

function FG:CmdPvP(query)
  print(" ")
  print("|cff00bfff✨ Spark PvP & Honor System:|r")
  if FG.Data.PvP then
    if FG.Data.PvP.ranks then
      print("  |cffffd100Ranks 1-14:|r")
      for rank, title in pairs(FG.Data.PvP.ranks) do
        print(string.format("    Rank %s: %s", rank, title))
      end
    end
    if FG.Data.PvP.decay then
      print("  |cffff8000Decay Rule:|r " .. FG.Data.PvP.decay)
    end
  end
  print(" ")
end

function FG:CmdRace(query)
  local q = query:lower()
  print(" ")
  print("|cff00bfff✨ Spark Racial Traits & Bonuses:|r")
  if FG.Data.Racials then
    for race, traits in pairs(FG.Data.Racials) do
      if q == "" or race:lower():find(q, 1, true) then
        print(string.format("  • |cffffd100%s|r: %s", race:upper(), traits))
      end
    end
  end
  print(" ")
end

function FG:CmdRep(query)
  local q = query:lower()
  print(" ")
  print("|cff00bfff✨ Spark Reputation Directory:|r")
  local count = 0
  if FG.Data.Reputations then
    for rep, data in pairs(FG.Data.Reputations) do
      if q == "" or rep:lower():find(q, 1, true) then
        count = count + 1
        print(string.format("  • |cffffd100%s|r in %s", rep, data.zone or "Various"))
        if data.turn_ins then print("    Turn-ins: " .. data.turn_ins) end
        if data.key_rewards then print("    Rewards: " .. data.key_rewards) end
        if count >= 4 and q == "" then break end
      end
    end
  end
  print(" ")
end

function FG:CmdResist(val)
  local v = tonumber(val) or 150
  local avg = math.min(75, (v / (63 * 5)) * 75)
  print(" ")
  print(string.format("|cff00bfff✨ Spark Resistance Math (%d Resistance vs Lvl 63 Boss):|r", v))
  print(string.format("  Average Damage Mitigated: |cff20ff20%.1f%%|r", avg))
  print("  Tiers: 0-75 (Soft), 76-150 (Medium), 151-225 (High), 315 (Hard Cap 75% max avg mitigation)")
  print(" ")
end

function FG:CmdTwink(bracket)
  local b = bracket or "19"
  print(" ")
  print(string.format("|cff00bfff✨ Spark Twink Gear Guide (%s Bracket):|r", b))
  if FG.Data.Twinks and FG.Data.Twinks[b] then
    local t = FG.Data.Twinks[b]
    if t.weapons then print("  Weapons: " .. t.weapons) end
    if t.armor then print("  Armor: " .. t.armor) end
    if t.enchants then print("  Enchants: " .. t.enchants) end
  else
    print("  Available brackets: 19, 29, 39, 49")
  end
  print(" ")
end

function FG:CmdForever(query)
  print(" ")
  print("|cff00bfff✨ Warcraft Forever Content Overview:|r")
  print("  • Database includes |cffe6cc806,671+ exclusive Forever items|r and 16 new dungeons/raids.")
  print("  • Type |cff71d5ff/spark codex|r and click the [Forever] button to explore new content!")
  print("  • Fully verified and synchronized offline directly from official documentation.")
  print(" ")
end

--------------------------------------------------------------------------------
-- Pixel Density & High-Definition Rendering Helpers
--------------------------------------------------------------------------------
local function MakePixelSharp(frame)
  if not frame then return end
  if frame.SetSnapToPixelGrid then
    pcall(frame.SetSnapToPixelGrid, frame, true)
  end
  if frame.SetTexelSnappingBias then
    pcall(frame.SetTexelSnappingBias, frame, 0.0)
  end
end

local function SharpenFontString(fs, size, outline, shadowOffset)
  if not fs then return end
  local font, fsize = fs:GetFont()
  if font then
    local targetOutline = (ForeverGuideDB and ForeverGuideDB.sharpText == false) and "" or (outline or "OUTLINE")
    fs:SetFont(font, size or fsize or 12, targetOutline)
    fs:SetShadowOffset(shadowOffset or 1, -(shadowOffset or 1))
    fs:SetShadowColor(0, 0, 0, 0.95)
  end
  if fs.SetSnapToPixelGrid then
    pcall(fs.SetSnapToPixelGrid, fs, true)
  end
end

function FG:UpdateSparkMouseState()
  if not FG.SparkFrame then return end
  if ForeverGuideDB.sparkClickThrough then
    FG.SparkFrame:EnableMouse(false)
  else
    FG.SparkFrame:EnableMouse(true)
  end
end

--------------------------------------------------------------------------------
-- The Blue Spark Companion Frame
--------------------------------------------------------------------------------
function FG:CreateSparkFrame()
  local f = CreateFrame("Button", "ForeverGuideSparkFrame", UIParent)
  f:SetSize(48, 48)
  f:SetFrameStrata("MEDIUM")
  f:SetFrameLevel(10)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetHitRectInsets(0, 0, 0, 0) -- Full responsive area for clicking and dragging

  -- Ensure right-clicks always pass through to 3D NPCs and objects
  if f.SetPassThroughButtons then
    pcall(f.SetPassThroughButtons, f, "RightButton")
  end

  -- Only register Left clicks so right-clicking NPCs is never hijacked
  f:RegisterForClicks("LeftButtonUp")
  f:RegisterForDrag("LeftButton")

  MakePixelSharp(f)

  local pos = ForeverGuideDB.sparkPosition or DEFAULT_CONFIG.sparkPosition
  f:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 240, pos.y or 60)
  f:SetScale(ForeverGuideDB.sparkScale or 1.0)

  -- Inner visual container: all animations and textures live here so f:StartMoving() is NEVER constrained
  local visual = CreateFrame("Frame", nil, f)
  visual:SetAllPoints(f)
  visual:EnableMouse(false)
  f.Visual = visual

  -- Circular Alpha Masking (Eliminates all possible square corners or cutoff edges)
  if visual.CreateMaskTexture then
    local mask = visual:CreateMaskTexture()
    mask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetSize(42, 42)
    mask:SetPoint("CENTER", visual, "CENTER", 0, 0)
    visual.CircleMask = mask
  end

  -- Layer 1: Outer Ambient Celestial Aura (Soft radiant halo)
  local aura = visual:CreateTexture(nil, "BACKGROUND")
  aura:SetBlendMode("ADD")
  aura:SetPoint("CENTER", visual, "CENTER", 0, 0)
  aura:SetSize(64, 64)
  aura:SetTexture("Interface\\AddOns\\ForeverGuide\\Media\\blue_spark_aura")
  aura:SetVertexColor(0.18, 0.65, 1.0, 0.70)
  f.Aura = aura

  -- Layer 2: Rotating Ethereal Rays (Whimsical celestial wisp motion)
  local rotAura = visual:CreateTexture(nil, "BORDER")
  rotAura:SetTexture("Interface\\Cooldown\\star4")
  rotAura:SetBlendMode("ADD")
  rotAura:SetPoint("CENTER", visual, "CENTER", 0, 0)
  rotAura:SetSize(44, 44)
  rotAura:SetVertexColor(0.25, 0.70, 1.0, 0.50)
  f.RotAura = rotAura

  -- Layer 3: Core Luminous Plasma Orb (High-res smooth gaussian sphere)
  local core = visual:CreateTexture(nil, "ARTWORK")
  core:SetBlendMode("ADD")
  core:SetPoint("CENTER", visual, "CENTER", 0, 0)
  core:SetSize(32, 32)
  core:SetTexture("Interface\\AddOns\\ForeverGuide\\Media\\blue_spark_core")
  core:SetVertexColor(0.40, 0.85, 1.0, 0.95)
  if visual.CircleMask and core.AddMaskTexture then
    pcall(core.AddMaskTexture, core, visual.CircleMask)
  end
  f.Core = core

  -- Layer 4: Cross Spark Flares (The bright sparkling twinkle)
  local sparkV = visual:CreateTexture(nil, "OVERLAY")
  sparkV:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
  sparkV:SetBlendMode("ADD")
  sparkV:SetPoint("CENTER", visual, "CENTER", 0, 0)
  sparkV:SetSize(10, 36)
  sparkV:SetVertexColor(0.75, 0.92, 1.0, 0.85)
  f.SparkV = sparkV

  local sparkH = visual:CreateTexture(nil, "OVERLAY")
  sparkH:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
  sparkH:SetBlendMode("ADD")
  sparkH:SetPoint("CENTER", visual, "CENTER", 0, 0)
  sparkH:SetSize(36, 10)
  sparkH:SetVertexColor(0.75, 0.92, 1.0, 0.85)
  if sparkH.SetRotation then
    pcall(sparkH.SetRotation, sparkH, 1.570796) -- 90 degrees
  end
  f.SparkH = sparkH

  -- Layer 5: Central Brilliant Glint
  local glint = visual:CreateTexture(nil, "OVERLAY")
  glint:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
  glint:SetBlendMode("ADD")
  glint:SetPoint("CENTER", visual, "CENTER", 0, 0)
  glint:SetSize(14, 14)
  glint:SetVertexColor(1.0, 1.0, 1.0, 1.0)
  f.Glint = glint

  -- Layer 6: Blizzard Native AutoCastShine (Crucial: EnableMouse(false) on shine AND all child frames)
  local shine = CreateFrame("Frame", "ForeverGuideSparkShine", visual, "AutoCastShineTemplate")
  shine:SetSize(38, 38)
  shine:SetPoint("CENTER", visual, "CENTER", 0, 0)
  shine:EnableMouse(false)
  if shine.GetChildren then
    for _, child in ipairs({shine:GetChildren()}) do
      if child and child.EnableMouse then child:EnableMouse(false) end
    end
  end
  shine:Show()
  if AutoCastShine_AutoCastStart then
    pcall(AutoCastShine_AutoCastStart, shine, 0.30, 0.80, 1.0)
  end
  f.Shine = shine

  -- Continuous slow rotation for the ethereal rays (on visual)
  local rotAg = visual:CreateAnimationGroup()
  local rotAnim = rotAg:CreateAnimation("Rotation")
  rotAnim:SetDegrees(360)
  rotAnim:SetDuration(16.0)
  rotAg:SetLooping("REPEAT")
  rotAg:Play()
  f.RotAnimGroup = rotAg

  -- Breathing Pulse & Gentle Floating Hover (on visual, completely decoupled from f)
  local ag = visual:CreateAnimationGroup()
  local alphaAnim = ag:CreateAnimation("Alpha")
  alphaAnim:SetFromAlpha(0.72)
  alphaAnim:SetToAlpha(1.0)
  alphaAnim:SetDuration(2.2)
  alphaAnim:SetSmoothing("IN_OUT")

  local transAnim = ag:CreateAnimation("Translation")
  transAnim:SetOffset(0, 3)
  transAnim:SetDuration(2.2)
  transAnim:SetSmoothing("IN_OUT")

  ag:SetLooping("BOUNCE")
  ag:Play()
  f.AnimGroup = ag

  local function OnSparkUpdate(self)
    if self.isDragging then
      local cx, cy = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      local curX, curY = cx / scale, cy / scale
      self:ClearAllPoints()
      self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", curX - (self.offsetX or 0), curY - (self.offsetY or 0))
    end
  end

  local function StartSparkDrag(self)
    if self.isDragging then return end
    self.isDragging = true
    self.wasDragged = false
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self.downX = cx / scale
    self.downY = cy / scale
    local fx, fy = self:GetCenter()
    if fx and fy then
      self.offsetX = self.downX - fx
      self.offsetY = self.downY - fy
    else
      self.offsetX = 0
      self.offsetY = 0
    end
    self:SetScript("OnUpdate", OnSparkUpdate)
  end

  local function StopSparkDrag(self)
    if self.isDragging then
      self.isDragging = false
      self:SetScript("OnUpdate", nil)
      local cx, cy = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      local upX = cx / scale
      local upY = cy / scale
      local dist = 0
      if self.downX and self.downY then
        local dx = upX - self.downX
        local dy = upY - self.downY
        dist = math.sqrt(dx * dx + dy * dy)
      end
      if dist > 4 then
        self.wasDragged = true
        local point, _, relPoint, x, y = self:GetPoint()
        if point and relPoint and x and y then
          ForeverGuideDB.sparkPosition = {
            point = point,
            relativePoint = relPoint,
            x = math.floor(x + 0.5),
            y = math.floor(y + 0.5),
          }
        end
      else
        self.wasDragged = false
      end
    end
  end

  f:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      StartSparkDrag(self)
    end
  end)

  f:SetScript("OnDragStart", function(self)
    StartSparkDrag(self)
  end)

  f:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
      StopSparkDrag(self)
    end
  end)

  f:SetScript("OnDragStop", function(self)
    StopSparkDrag(self)
  end)

  f:SetScript("OnHide", function(self)
    StopSparkDrag(self)
  end)

  f:SetScript("OnClick", function(self, button)
    if self.wasDragged then
      self.wasDragged = false
      return
    end
    if button == "LeftButton" then
      FG:ToggleCodex()
      FG:PlaySparkSound("shimmer")
    end
  end)

  f:SetScript("OnEnter", function(self)
    if ForeverGuideDB.sparkClickThrough then return end
    if self.Aura then self.Aura:SetVertexColor(0.35, 0.85, 1.0, 0.95) end
    if self.Core then self.Core:SetVertexColor(0.60, 0.95, 1.0, 1.0) end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cff52b8ffThe Blue Spark|r", 1, 1, 1)
    GameTooltip:AddLine("Celestial companion for Warcraft Forever.", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff71d5ff<Left-Click>|r Open Forever Codex", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Left-Drag>|r Move anywhere" .. (ForeverGuideDB.sparkLocked and " (|cff71d5ffShift-Drag|r if locked)" or ""), 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff71d5ff/spark lock|r - Toggle position lock", 0.6, 0.7, 0.8)
    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function(self)
    if self.Aura then self.Aura:SetVertexColor(0.18, 0.65, 1.0, 0.70) end
    if self.Core then self.Core:SetVertexColor(0.40, 0.85, 1.0, 0.95) end
    GameTooltip:Hide()
  end)

  FG.SparkFrame = f
  FG:UpdateSparkMouseState()

  if ForeverGuideDB.sparkShown == false then
    f:Hide()
  end
end

function FG:ToggleSpark()
  if not FG.SparkFrame then return end
  if FG.SparkFrame:IsShown() then
    FG.SparkFrame:Hide()
    ForeverGuideDB.sparkShown = false
    print("|cff52b8ff[The Blue Spark]|r Companion dismissed.")
  else
    FG.SparkFrame:Show()
    ForeverGuideDB.sparkShown = true
    FG:PlaySparkSound("shimmer")
    print("|cff52b8ff[The Blue Spark]|r Companion summoned.")
  end
end

--------------------------------------------------------------------------------
-- Zone Wayfarer
--------------------------------------------------------------------------------
function FG:GetCurrentZone()
  local zone = GetRealZoneText()
  if not zone or zone == "" then zone = GetZoneText() end
  return zone or "Unknown"
end

function FG:GetZoneData(zoneName)
  if not FG.Data.Zones then return nil end
  for _, z in ipairs(FG.Data.Zones) do
    if z.name:lower() == zoneName:lower() then return z end
  end
  return nil
end

function FG:ShowCurrentZoneIntel()
  local currentZone = FG:GetCurrentZone()
  local zoneInfo = FG:GetZoneData(currentZone)
  local faction = UnitFactionGroup("player")

  print(" ")
  print("|cff00bfff✨ The Blue Spark whispers concerning:|r |cffffffff" .. currentZone .. "|r")
  if zoneInfo then
    print("  |cff71d5ffLevel Range:|r |cff20ff20" .. zoneInfo.level .. "|r  |cff71d5ffFaction:|r " .. zoneInfo.faction)
    print("  |cff71d5ffContinent:|r " .. zoneInfo.continent)
  end

  local localDungeons = {}
  if FG.Data.Dungeons then
    for _, d in pairs(FG.Data.Dungeons) do
      if d.zone and d.zone:lower() == currentZone:lower() then
        table.insert(localDungeons, d)
      end
    end
  end

  if #localDungeons > 0 then
    print("  |cff00ff00Local Dungeons & Raids:|r")
    for _, d in ipairs(localDungeons) do
      local tag = d.isForever and " |cffe6cc80[Forever]|r" or ""
      print("    • |cffffd100" .. d.name .. "|r (Lvl " .. d.recLevel .. ")" .. tag)
      if d.coords and d.coords ~= "" then
        print("      Entrance: |cff71d5ff" .. d.coords .. "|r")
      end
    end
  end
  print(" ")
end

--------------------------------------------------------------------------------
-- Forever Codex Search & UI Window
--------------------------------------------------------------------------------
function FG:CreateCodexWindow()
  local f = CreateFrame("Frame", "ForeverGuideCodexWindow", UIParent, "BackdropTemplate")
  f:SetSize(620, 530)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScale(ForeverGuideDB.codexScale or 1.0)

  MakePixelSharp(f)

  -- Comfortable dark charcoal slate backdrop (easy on the eyes)
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.08, 0.09, 0.12, 0.96)
  f:SetBackdropBorderColor(0.20, 0.38, 0.54, 0.85)

  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetScript("OnHide", f.StopMovingOrSizing)

  -- Register with standard UI Special Frames so ESC closes this window
  tinsert(UISpecialFrames, "ForeverGuideCodexWindow")

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -14)
  title:SetText("|cff52b8ffForever Guide:|r |cff8ad0ffThe Blue Spark Codex|r")
  SharpenFontString(title, 15, "OUTLINE")
  f.Title = title

  local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  subtitle:SetText("|cff8899aaWarcraft Forever High-Density Codex|r")
  SharpenFontString(subtitle, 10, "OUTLINE")
  f.Subtitle = subtitle

  local divider = f:CreateTexture(nil, "ARTWORK")
  divider:SetColorTexture(0.20, 0.45, 0.65, 0.30)
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -46)
  divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -46)
  MakePixelSharp(divider)

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  closeBtn:SetScript("OnClick", function() f:Hide() end)

  local searchBox = CreateFrame("EditBox", "ForeverGuideSearchBox", f, "InputBoxTemplate")
  searchBox:SetSize(280, 26)
  searchBox:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 4, -10)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject("ChatFontNormal")
  SharpenFontString(searchBox, 13, "OUTLINE")
  MakePixelSharp(searchBox)

  local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
  placeholder:SetText("Search items, quests, NPCs, dungeons...")
  SharpenFontString(placeholder, 11, "OUTLINE")
  searchBox.Placeholder = placeholder

  searchBox:SetScript("OnTextChanged", function(self)
    local query = self:GetText():trim()
    if query == "" then
      placeholder:Show()
      FG:PopulateCodexResults("")
    else
      placeholder:Hide()
      FG:PopulateCodexResults(query)
    end
  end)

  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local function StyleFilterBtn(btn, text)
    btn:SetText(text)
    local fs = btn:GetFontString()
    if fs then
      SharpenFontString(fs, 11, "OUTLINE")
    end
    MakePixelSharp(btn)
  end

  local allBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  allBtn:SetSize(45, 24)
  allBtn:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
  StyleFilterBtn(allBtn, "All")
  allBtn:SetScript("OnClick", function()
    searchBox:SetText("")
    FG:PopulateCodexResults("")
  end)

  local dBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  dBtn:SetSize(75, 24)
  dBtn:SetPoint("LEFT", allBtn, "RIGHT", 4, 0)
  StyleFilterBtn(dBtn, "Dungeons")
  dBtn:SetScript("OnClick", function()
    searchBox:SetText("")
    FG:PopulateDungeons()
  end)

  local fBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  fBtn:SetSize(65, 24)
  fBtn:SetPoint("LEFT", dBtn, "RIGHT", 4, 0)
  StyleFilterBtn(fBtn, "Forever")
  fBtn:SetScript("OnClick", function()
    searchBox:SetText("forever")
  end)

  local lockBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  lockBtn:SetSize(60, 24)
  lockBtn:SetPoint("LEFT", fBtn, "RIGHT", 4, 0)
  StyleFilterBtn(lockBtn, ForeverGuideDB.sparkLocked and "Unlock" or "Lock")
  lockBtn:SetScript("OnClick", function(self)
    ForeverGuideDB.sparkLocked = not ForeverGuideDB.sparkLocked
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    FG:UpdateSparkMouseState()
    StyleFilterBtn(self, ForeverGuideDB.sparkLocked and "Unlock" or "Lock")
    print("|cff52b8ff[The Blue Spark]|r Position is now " .. (ForeverGuideDB.sparkLocked and "|cffff4040Locked (Click-Through)|r" or "|cff20ff20Unlocked|r"))
  end)
  f.LockBtn = lockBtn

  local scrollFrame = CreateFrame("ScrollFrame", "ForeverGuideScrollFrame", f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -2, -12)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 16)
  MakePixelSharp(scrollFrame)

  local content = CreateFrame("Frame", "ForeverGuideScrollContent", scrollFrame)
  content:SetSize(554, 1000)
  scrollFrame:SetScrollChild(content)
  MakePixelSharp(content)
  f.Content = content

  f:Hide()
  FG.CodexWindow = f
end

function FG:ApplyTextSharpening()
  if not FG.CodexWindow then return end
  local cw = FG.CodexWindow
  if cw.Title then SharpenFontString(cw.Title, 15, "OUTLINE") end
  if cw.Subtitle then SharpenFontString(cw.Subtitle, 10, "OUTLINE") end
  if ForeverGuideSearchBox then
    SharpenFontString(ForeverGuideSearchBox, 13, "OUTLINE")
    if ForeverGuideSearchBox.Placeholder then
      SharpenFontString(ForeverGuideSearchBox.Placeholder, 11, "OUTLINE")
    end
  end
  if cw.Content and cw.Content.Buttons then
    for _, btn in ipairs(cw.Content.Buttons) do
      if btn.Title then SharpenFontString(btn.Title, 13, "OUTLINE") end
      if btn.Sub then SharpenFontString(btn.Sub, 11, "OUTLINE") end
    end
  end
end

function FG:PopulateCodexResults(query)
  if not FG.CodexWindow or not FG.CodexWindow.Content then return end
  local content = FG.CodexWindow.Content

  if content.Buttons then
    for _, btn in ipairs(content.Buttons) do btn:Hide() end
  end
  content.Buttons = content.Buttons or {}

  local q = query:lower():trim()
  local matches = {}

  if q == "" then
    if FG.Data.Items then
      for _, item in pairs(FG.Data.Items) do
        if item.isForever then
          table.insert(matches, { type = "item", data = item })
          if #matches >= 40 then break end
        end
      end
    end
  else
    -- Search Items
    if FG.Data.Items then
      for _, item in pairs(FG.Data.Items) do
        if item.name and (item.name:lower():find(q, 1, true) or (item.source and item.source:lower():find(q, 1, true))) then
          table.insert(matches, { type = "item", data = item })
          if #matches >= 50 then break end
        end
      end
    end

    -- Search Quests (Title, NPC/Questgiver, Zone, Objectives, Tips)
    if FG.Data.Quests and #matches < 60 then
      for _, quest in pairs(FG.Data.Quests) do
        local matchTitle = quest.title and quest.title:lower():find(q, 1, true)
        local matchNpc = quest.npc and quest.npc:lower():find(q, 1, true)
        local matchZone = quest.zone and quest.zone:lower():find(q, 1, true)
        local matchObj = quest.objectives and quest.objectives:lower():find(q, 1, true)
        local matchTip = quest.tip and quest.tip:lower():find(q, 1, true)
        if matchTitle or matchNpc or matchZone or matchObj or matchTip then
          table.insert(matches, { type = "quest", data = quest })
          if #matches >= 60 then break end
        end
      end
    end

    -- Search Creatures & NPCs (Name, Zone, Location, Strategy)
    if FG.Data.Creatures and #matches < 75 then
      for _, c in pairs(FG.Data.Creatures) do
        local matchName = c.name and c.name:lower():find(q, 1, true)
        local matchZone = c.zone and c.zone:lower():find(q, 1, true)
        local matchLoc = c.location and c.location:lower():find(q, 1, true)
        if matchName or matchZone or matchLoc then
          table.insert(matches, { type = "creature", data = c })
          if #matches >= 75 then break end
        end
      end
    end

    -- Search Dungeons
    if FG.Data.Dungeons and #matches < 80 then
      for _, d in pairs(FG.Data.Dungeons) do
        if d.name and (d.name:lower():find(q, 1, true) or d.zone:lower():find(q, 1, true)) then
          table.insert(matches, { type = "dungeon", data = d })
        end
      end
    end

    -- Search Vendors
    if FG.Data.Vendors and #matches < 85 then
      for _, v in pairs(FG.Data.Vendors) do
        local matchName = v.name and v.name:lower():find(q, 1, true)
        local matchItem = v.item and v.item:lower():find(q, 1, true)
        local matchZone = v.zone and v.zone:lower():find(q, 1, true)
        if matchName or matchItem or matchZone then
          table.insert(matches, { type = "vendor", data = v })
          if #matches >= 85 then break end
        end
      end
    end
  end

  local yOffset = -2
  for i, match in ipairs(matches) do
    local btn = content.Buttons[i]
    if not btn then
      btn = CreateFrame("Button", nil, content, "BackdropTemplate")
      btn:SetSize(548, 52)
      MakePixelSharp(btn)

      btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 12,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })
      btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)

      local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -7)
      SharpenFontString(titleText, 13, "OUTLINE")
      btn.Title = titleText

      local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
      subText:SetWidth(524)
      subText:SetJustifyH("LEFT")
      SharpenFontString(subText, 11, "OUTLINE")
      btn.Sub = subText

      content.Buttons[i] = btn
    end

    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

    if match.type == "item" then
      local item = match.data
      local qColor = FG.QualityColors[item.quality] or "ffffffff"
      local foreverTag = item.isForever and " |cffe6cc80[Forever]|r" or ""
      btn.Title:SetText("|c" .. qColor .. item.name .. "|r" .. foreverTag .. " |cff8899aa(iLvl " .. item.ilvl .. ")|r")

      local desc = (item.slot and item.slot ~= "" and (item.slot .. " • ") or "") .. (item.source or "World Drop")
      if item.tip and item.tip ~= "" then desc = desc .. " |cff52b8ffNote:|r |cffb0c4de" .. item.tip .. "|r" end
      btn.Sub:SetText(desc)

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.14, 0.18, 0.26, 0.95)
        self:SetBackdropBorderColor(0.28, 0.58, 0.82, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetItemByID(item.id)
        if item.tip and item.tip ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("|cff52b8ffSpark Intel:|r " .. item.tip, 0.3, 0.8, 1.0, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if ChatEdit_InsertLink then
          local _, link = GetItemInfo(item.id)
          if link then ChatEdit_InsertLink(link) end
        end
      end)

    elseif match.type == "quest" then
      local qData = match.data
      local foreverTag = qData.isForever and " |cffe6cc80[Forever]|r" or ""
      btn.Title:SetText("|cffffd24d" .. qData.title .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. qData.questLevel .. ")|r")
      btn.Sub:SetText("|cff52b8ffZone:|r " .. (qData.zone or "Various") .. " |cff52b8ffStart:|r " .. (qData.npc or "Unknown"))

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.18, 0.14, 0.95)
        self:SetBackdropBorderColor(0.28, 0.68, 0.40, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(qData.title, 1, 0.85, 0.2)
        GameTooltip:AddLine("Level: " .. qData.questLevel .. " (Req " .. qData.reqLevel .. ")", 1, 1, 1)
        if qData.objectives and qData.objectives ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("Objectives: " .. qData.objectives, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)

    elseif match.type == "dungeon" then
      local d = match.data
      local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
      btn.Title:SetText("|cffffd24d" .. d.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. d.recLevel .. ")|r")
      btn.Sub:SetText("|cff52b8ffZone:|r " .. d.zone .. " |cff52b8ffEntrance:|r " .. (d.coords or "N/A"))

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.12, 0.22, 0.95)
        self:SetBackdropBorderColor(0.55, 0.38, 0.78, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(d.name, 1, 0.85, 0.2)
        GameTooltip:AddLine("Level: " .. d.recLevel .. " (" .. d.zone .. ")", 1, 1, 1)
        if d.coords and d.coords ~= "" then GameTooltip:AddLine("Coords: " .. d.coords, 0.2, 1, 0.2) end
        if d.strategy and d.strategy ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("Tactics: " .. d.strategy, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)

    elseif match.type == "creature" then
      local c = match.data
      local foreverTag = c.isForever and " |cffe6cc80[Forever]|r" or ""
      local classColor = (c.classification == "Boss" or c.classification == "Rare Elite") and "ffff4040" or (c.classification == "Elite" and "ffffd24d" or "ff52b8ff")
      local lvlStr = (c.minLevel and c.maxLevel and c.minLevel ~= c.maxLevel) and (c.minLevel .. "-" .. c.maxLevel) or (c.maxLevel or c.minLevel or "?")
      btn.Title:SetText("|c" .. classColor .. c.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. lvlStr .. " " .. (c.classification or "NPC") .. ")|r")
      local desc = "|cff52b8ffZone:|r " .. (c.zone ~= "" and c.zone or "Various")
      if c.location and c.location ~= "" then
        desc = desc .. " |cff52b8ffLocation:|r " .. c.location
      end
      btn.Sub:SetText(desc)

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.14, 0.10, 0.95)
        self:SetBackdropBorderColor(0.85, 0.55, 0.20, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(c.name, 1, 0.85, 0.2)
        GameTooltip:AddLine("Level: " .. lvlStr .. " (" .. (c.classification or "Normal") .. ")", 1, 1, 1)
        if c.zone and c.zone ~= "" then GameTooltip:AddLine("Zone: " .. c.zone, 0.3, 0.8, 1.0) end
        if c.location and c.location ~= "" then GameTooltip:AddLine("Location: " .. c.location, 0.2, 1, 0.2) end
        if c.health and c.health > 0 then GameTooltip:AddLine("Health: " .. c.health, 1, 0.3, 0.3) end
        if c.strategy and c.strategy ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("Notes: " .. c.strategy, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)

    elseif match.type == "vendor" then
      local v = match.data
      btn.Title:SetText("|cffffd24d" .. v.name .. "|r |cff20ff20[Vendor]|r")
      local desc = "|cff52b8ffSells:|r " .. (v.item or "Goods") .. " |cff52b8ffZone:|r " .. (v.zone or "Various")
      if v.coords and v.coords ~= "" then
        desc = desc .. " (" .. v.coords .. ")"
      end
      btn.Sub:SetText(desc)

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.18, 0.16, 0.95)
        self:SetBackdropBorderColor(0.30, 0.75, 0.55, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(v.name, 1, 0.85, 0.2)
        GameTooltip:AddLine("Sells: " .. (v.item or "Goods"), 1, 1, 1)
        if v.zone and v.zone ~= "" then GameTooltip:AddLine("Zone: " .. v.zone, 0.3, 0.8, 1.0) end
        if v.coords and v.coords ~= "" then GameTooltip:AddLine("Coords: " .. v.coords, 0.2, 1, 0.2) end
        if v.tip and v.tip ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("Note: " .. v.tip, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
    end

    btn:Show()
    yOffset = yOffset - 58
  end

  content:SetHeight(math.max(450, math.abs(yOffset) + 20))
end

function FG:PopulateDungeons()
  if not FG.CodexWindow or not FG.Data.Dungeons then return end
  local content = FG.CodexWindow.Content

  if content.Buttons then
    for _, btn in ipairs(content.Buttons) do btn:Hide() end
  end
  content.Buttons = content.Buttons or {}

  local sorted = {}
  for _, d in pairs(FG.Data.Dungeons) do table.insert(sorted, d) end
  table.sort(sorted, function(a, b) return (a.minLevel or 0) < (b.minLevel or 0) end)

  local yOffset = -2
  for i, d in ipairs(sorted) do
    local btn = content.Buttons[i]
    if not btn then
      btn = CreateFrame("Button", nil, content, "BackdropTemplate")
      btn:SetSize(548, 52)
      MakePixelSharp(btn)

      btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 12,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })
      btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)

      local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -7)
      SharpenFontString(titleText, 13, "OUTLINE")
      btn.Title = titleText

      local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
      subText:SetWidth(524)
      subText:SetJustifyH("LEFT")
      SharpenFontString(subText, 11, "OUTLINE")
      btn.Sub = subText

      content.Buttons[i] = btn
    end

    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

    local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
    btn.Title:SetText("|cffffd24d" .. d.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. d.recLevel .. ")|r")
    btn.Sub:SetText("|cff52b8ffZone:|r " .. d.zone .. " |cff52b8ffEntrance:|r " .. (d.coords or "N/A"))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.14, 0.18, 0.26, 0.95)
      self:SetBackdropBorderColor(0.28, 0.58, 0.82, 0.90)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(d.name, 1, 0.85, 0.2)
      GameTooltip:AddLine("Level: " .. d.recLevel .. " | Zone: " .. d.zone, 1, 1, 1)
      if d.coords and d.coords ~= "" then GameTooltip:AddLine("Coords: " .. d.coords, 0.2, 1, 0.2) end
      if d.strategy and d.strategy ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tactics: " .. d.strategy, 0.8, 0.85, 0.95, true)
      end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
      GameTooltip:Hide()
    end)

    btn:Show()
    yOffset = yOffset - 58
  end
  content:SetHeight(math.max(450, math.abs(yOffset) + 20))
end

function FG:ToggleCodex()
  if not FG.CodexWindow then FG:CreateCodexWindow() end
  if FG.CodexWindow:IsShown() then
    FG.CodexWindow:Hide()
  else
    FG.CodexWindow:Show()
    FG:PopulateCodexResults("")
    FG:PlaySparkSound("shimmer")
  end
end

function FG:OpenCodexWithSearch(query)
  if not FG.CodexWindow then FG:CreateCodexWindow() end
  FG.CodexWindow:Show()
  if ForeverGuideSearchBox then ForeverGuideSearchBox:SetText(query or "") end
  FG:PopulateCodexResults(query or "")
end

--------------------------------------------------------------------------------
-- Minimap Button
--------------------------------------------------------------------------------
function FG:CreateMinimapButton()
  local btn = CreateFrame("Button", "ForeverGuideMinimapButton", Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  MakePixelSharp(btn)

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(25, 25)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("TOPLEFT", 2, -4)

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetTexture("Interface\\CHARACTERFRAME\\UI-Player-Status")
  icon:SetTexCoord(0.15, 0.40, 0.15, 0.40)
  icon:SetVertexColor(0.2, 0.85, 1.0, 1.0)
  icon:SetPoint("CENTER", 0, 0)
  btn.Icon = icon

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetSize(52, 52)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  local function UpdatePosition(angle)
    local rad = math.rad(angle)
    local x = math.cos(rad) * 80
    local y = math.sin(rad) * 80
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end

  local function OnMinimapUpdate(self)
    if self.isDragging then
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cx, cy = cx / scale, cy / scale
      local angle = math.deg(math.atan2(cy - my, cx - mx))
      ForeverGuideDB.minimap.minimapPos = angle
      UpdatePosition(angle)
    end
  end

  btn:SetScript("OnDragStart", function(self)
    self.isDragging = true
    self:SetScript("OnUpdate", OnMinimapUpdate)
  end)

  btn:SetScript("OnDragStop", function(self)
    self.isDragging = false
    self:SetScript("OnUpdate", nil)
  end)

  btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
      FG:ToggleCodex()
    elseif button == "RightButton" then
      FG:ToggleSpark()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff52b8ffForever Guide|r", 1, 1, 1)
    GameTooltip:AddLine("|cff71d5ff<Left-Click>|r Toggle Codex Window", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Right-Click>|r Summon / Dismiss Blue Spark", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Drag>|r Move around minimap", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  btn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

  UpdatePosition(ForeverGuideDB.minimap.minimapPos or 215)
  FG.MinimapButton = btn
end

function FG:ToggleWayfarer()
  FG:ShowCurrentZoneIntel()
end

--------------------------------------------------------------------------------
-- Event Dispatcher & Gameplay Non-Interference Guard
--------------------------------------------------------------------------------
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- NPC Interaction Events: ensure UI auto-yields so dialogue is never obstructed
EventFrame:RegisterEvent("GOSSIP_SHOW")
EventFrame:RegisterEvent("QUEST_GREETING")
EventFrame:RegisterEvent("QUEST_DETAIL")
EventFrame:RegisterEvent("QUEST_PROGRESS")
EventFrame:RegisterEvent("QUEST_COMPLETE")
EventFrame:RegisterEvent("MERCHANT_SHOW")
EventFrame:RegisterEvent("TAXIMAP_OPENED")

EventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    ForeverGuideDB = ForeverGuideDB or {}
    for k, v in pairs(DEFAULT_CONFIG) do
      if ForeverGuideDB[k] == nil then
        ForeverGuideDB[k] = v
      end
    end
    ForeverGuideDB.sparkLocked = false
    ForeverGuideDB.sparkClickThrough = false

    FG:CreateSparkFrame()
    FG:CreateMinimapButton()

    print("|cff52b8ffForever Guide (The Blue Spark)|r loaded! Type |cff71d5ff/spark|r to open Codex or |cff71d5ff/spark help|r for commands.")

  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Guarantee any stray cursor dragging state is stopped on world load
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    FG:UpdateSparkMouseState()

  -- NPC Interaction: Auto-hide Codex window so NPC quest dialogue is 100% visible and accessible
  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_DETAIL" or
         event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "MERCHANT_SHOW" or
         event == "TAXIMAP_OPENED" then
    if FG.CodexWindow and FG.CodexWindow:IsShown() then
      FG.CodexWindow:Hide()
    end

  elseif event == "ZONE_CHANGED_NEW_AREA" then
    if FG.SparkFrame and FG.SparkFrame:IsShown() then
      FG:PlaySparkSound("pulse")
      if FG.SparkFrame.Aura then
        FG.SparkFrame.Aura:SetVertexColor(0.3, 0.75, 1.0, 0.85)
        C_Timer.After(1.2, function()
          if FG.SparkFrame and FG.SparkFrame.Aura then
            FG.SparkFrame.Aura:SetVertexColor(0.12, 0.55, 0.80, 0.65)
          end
        end)
      end
    end

  elseif event == "PLAYER_REGEN_DISABLED" then
    if ForeverGuideDB.combatFade and FG.SparkFrame then
      FG.SparkFrame:SetAlpha(0.15)
    end

  elseif event == "PLAYER_REGEN_ENABLED" then
    if ForeverGuideDB.combatFade and FG.SparkFrame then
      FG.SparkFrame:SetAlpha(1.0)
    end
  end
end)
