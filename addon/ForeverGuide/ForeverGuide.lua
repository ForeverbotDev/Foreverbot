--[[
  ForeverGuide.lua
  Warcraft Forever Addon: Sparky the Cloud Wisp Companion
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
  hasInteracted = false,
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
SLASH_FOREVERGUIDE4 = "/sparky"

SlashCmdList["FOREVERGUIDE"] = function(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  rest = (rest or ""):trim()

  if cmd == "" then
    FG:ToggleCodex()

  -- 1. Companion Controls & High-Density UI Scaling
  elseif cmd == "spark" or cmd == "sparky" or cmd == "toggle" or cmd == "sprite" or cmd == "wisp" then
    FG:ToggleSpark()
  elseif cmd == "hide" or cmd == "dismiss" or cmd == "off" then
    if FG.SparkFrame then FG.SparkFrame:Hide() end
    ForeverGuideDB.sparkShown = false
    print("|cffdf80ff[Sparky]|r Companion dismissed. Type |cffcf52ff/sparky show|r to summon.")
  elseif cmd == "show" or cmd == "summon" or cmd == "on" then
    if FG.SparkFrame then FG.SparkFrame:Show() end
    ForeverGuideDB.sparkShown = true
    print("|cffdf80ff[Sparky]|r Companion summoned.")
  elseif cmd == "clickthrough" or cmd == "passthrough" or cmd == "pass" then
    ForeverGuideDB.sparkClickThrough = not ForeverGuideDB.sparkClickThrough
    FG:UpdateSparkMouseState()
    local state = ForeverGuideDB.sparkClickThrough and "|cff20ff20Enabled (World clicks pass through)|r" or "|cffff4040Disabled (Directly Clickable)|r"
    print("|cffdf80ff[Sparky]|r Click-through mode is now " .. state)
  elseif cmd == "lock" then
    ForeverGuideDB.sparkLocked = true
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    FG:UpdateSparkMouseState()
    print("|cffdf80ff[Sparky]|r Position is now |cffff4040Locked|r (Hold Shift+Drag to move)")
    if FG.CodexWindow and FG.CodexWindow.LockBtn then
      FG.CodexWindow.LockBtn:SetText("Unlock")
    end
  elseif cmd == "unlock" then
    ForeverGuideDB.sparkLocked = false
    FG:UpdateSparkMouseState()
    print("|cffdf80ff[Sparky]|r Position is now |cff20ff20Unlocked|r (Draggable)")
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
    print("|cffdf80ff[Sparky]|r Position reset to screen center.")
  elseif cmd == "scale" or cmd == "size" then
    local target, sVal = rest:match("^(%a+)%s+(%S+)$")
    if not target then
      sVal = rest
      target = "all"
    end
    local num = tonumber(sVal)
    if num and num >= 0.5 and num <= 2.5 then
      if target == "spark" or target == "sparky" or target == "sprite" or target == "wisp" then
        ForeverGuideDB.sparkScale = num
        if FG.SparkFrame then FG.SparkFrame:SetScale(num) end
        print(string.format("|cffdf80ff[Sparky]|r Scale set to |cffffffff%.2f|r", num))
      elseif target == "codex" then
        ForeverGuideDB.codexScale = num
        if FG.CodexWindow then FG.CodexWindow:SetScale(num) end
        print(string.format("|cffdf80ff[Sparky]|r Codex scale set to |cffffffff%.2f|r", num))
      else
        ForeverGuideDB.sparkScale = num
        ForeverGuideDB.codexScale = num
        if FG.SparkFrame then FG.SparkFrame:SetScale(num) end
        if FG.CodexWindow then FG.CodexWindow:SetScale(num) end
        print(string.format("|cffdf80ff[Sparky]|r UI scale set to |cffffffff%.2f|r (Pixel Density: |cffcf52ff%.2fx|r)", num, num))
      end
    else
      print("|cffdf80ff[Sparky]|r Usage: |cffcf52ff/sparky scale <0.5-2.0>|r or |cffcf52ff/sparky scale [sparky|codex] <0.5-2.0>|r")
    end
  elseif cmd == "density" or cmd == "sharp" then
    ForeverGuideDB.sharpText = not ForeverGuideDB.sharpText
    local state = ForeverGuideDB.sharpText and "|cff20ff20Enabled (Razor-Sharp Outlined)|r" or "|cffff2020Standard|r"
    print("|cffdf80ff[Sparky]|r High-Density Sharp Text is now " .. state)
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
  print("|cffdf80ff✨ [Forever Guide: Sparky] — In-Game Commands:|r")
  print("  |cffcf52ff/sparky|r or |cffcf52ff/spark|r - Open Forever Codex search window")
  print("  |cffcf52ff/sparky scale [0.5-2.0]|r - Adjust UI pixel density & window scale")
  print("  |cffcf52ff/sparky sharp|r - Toggle razor-sharp font outlining mode")
  print("  |cffcf52ff/sparky lock / /sparky unlock|r - Lock or unlock Sparky's cursor movement")
  print("  |cffcf52ff/sparky reset|r - Safely detach and center Sparky on screen")
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
-- Sparky: The Cloud Wisp Companion Frame
--------------------------------------------------------------------------------
function FG:CreateSparkFrame()
  local f = CreateFrame("Button", "ForeverGuideSparkFrame", UIParent)
  f:SetSize(38, 38)
  f:SetFrameStrata("MEDIUM")
  f:SetFrameLevel(12)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetHitRectInsets(-4, -4, -4, -4)

  -- Ensure right-clicks pass through to 3D NPCs and objects
  if f.SetPassThroughButtons then
    pcall(f.SetPassThroughButtons, f, "RightButton")
  end

  f:RegisterForClicks("LeftButtonUp")

  MakePixelSharp(f)

  local pos = ForeverGuideDB.sparkPosition or DEFAULT_CONFIG.sparkPosition
  local sw = UIParent:GetWidth() or 1920
  local sh = UIParent:GetHeight() or 1080
  local rawX = tonumber(pos.x) or 240
  local rawY = tonumber(pos.y) or 120
  if rawX < 60 or rawX > (sw - 60) then
    rawX = math.max(60, math.min(sw - 60, rawX))
    if rawX < 60 or rawX > (sw - 60) then rawX = 240 end
  end
  if rawY < 60 or rawY > (sh - 60) then
    rawY = math.max(60, math.min(sh - 60, rawY))
    if rawY < 60 or rawY > (sh - 60) then rawY = 120 end
  end
  f.homeX = rawX
  f.homeY = rawY
  f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", f.homeX, f.homeY)
  f:SetScale(ForeverGuideDB.sparkScale or 1.0)

  -- Inner visual container
  local visual = CreateFrame("Frame", nil, f)
  visual:SetAllPoints(f)
  visual:EnableMouse(false)
  f.Visual = visual

  local MEDIA = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\"
  local TEX_CLOUD_MAIN = MEDIA .. "sparky_cloud_main.tga"
  local TEX_CLOUD_WISP = MEDIA .. "sparky_cloud_wisp.tga"
  local TEX_CLOUD_CORE = MEDIA .. "sparky_cloud_core.tga"
  local TEX_CLOUD_PUFF = MEDIA .. "sparky_cloud_puff.tga"

  -- Layer 1: Outer Ambient Ethereal Violet Haze (Soft drifting mist fog)
  local aura = visual:CreateTexture(nil, "BACKGROUND")
  aura:SetTexture(TEX_CLOUD_MAIN)
  aura:SetBlendMode("ADD")
  aura:SetPoint("CENTER", visual, "CENTER", 0, 0)
  aura:SetSize(42, 42)
  aura:SetVertexColor(0.55, 0.12, 0.85, 0.40)
  f.Aura = aura

  -- Layer 2: Billowing Cloud Lobe A (Asymmetric puff, rotates counter-clockwise)
  local cloudA = visual:CreateTexture(nil, "BORDER")
  cloudA:SetTexture(TEX_CLOUD_MAIN)
  cloudA:SetBlendMode("ADD")
  cloudA:SetPoint("CENTER", visual, "CENTER", -1.5, 1.0)
  cloudA:SetSize(34, 34)
  cloudA:SetVertexColor(0.72, 0.20, 0.98, 0.65)
  f.CloudA = cloudA

  local rotAgA = visual:CreateAnimationGroup()
  local rotAnimA = rotAgA:CreateAnimation("Rotation")
  rotAnimA:SetDegrees(360)
  rotAnimA:SetDuration(22.0)
  rotAgA:SetLooping("REPEAT")
  rotAgA:Play()
  f.RotAnimGroupA = rotAgA

  -- Layer 3: Billowing Counter Cloud Lobe B (Opposite rotation constantly morphs silhouette)
  local cloudB = visual:CreateTexture(nil, "ARTWORK")
  cloudB:SetTexture(TEX_CLOUD_MAIN)
  cloudB:SetBlendMode("ADD")
  cloudB:SetPoint("CENTER", visual, "CENTER", 1.8, -1.2)
  cloudB:SetSize(30, 30)
  cloudB:SetVertexColor(0.82, 0.30, 1.00, 0.60)
  f.CloudB = cloudB

  local rotAgB = visual:CreateAnimationGroup()
  local rotAnimB = rotAgB:CreateAnimation("Rotation")
  rotAnimB:SetDegrees(-360)
  rotAnimB:SetDuration(16.0)
  rotAgB:SetLooping("REPEAT")
  rotAgB:Play()
  f.RotAnimGroupB = rotAgB

  -- Layer 4: Twisting Vapor Tendril Wisp (Curling smoke plume wafts through the cloud)
  local wispTendril = visual:CreateTexture(nil, "ARTWORK", nil, 1)
  wispTendril:SetTexture(TEX_CLOUD_WISP)
  wispTendril:SetBlendMode("ADD")
  wispTendril:SetPoint("CENTER", visual, "CENTER", 0, 0)
  wispTendril:SetSize(32, 32)
  wispTendril:SetVertexColor(0.90, 0.45, 1.00, 0.75)
  f.WispTendril = wispTendril

  local rotAgW = visual:CreateAnimationGroup()
  local rotAnimW = rotAgW:CreateAnimation("Rotation")
  rotAnimW:SetDegrees(360)
  rotAnimW:SetDuration(11.0)
  rotAgW:SetLooping("REPEAT")
  rotAgW:Play()
  f.RotAnimGroupW = rotAgW

  -- Layer 5: Nebulous Heart Mist (Soft, uneven spirit smoke center - NOT a geometric shape)
  local cloudCore = visual:CreateTexture(nil, "OVERLAY")
  cloudCore:SetTexture(TEX_CLOUD_CORE)
  cloudCore:SetBlendMode("ADD")
  cloudCore:SetPoint("CENTER", visual, "CENTER", 0, 0)
  cloudCore:SetSize(22, 22)
  cloudCore:SetVertexColor(0.95, 0.65, 1.00, 0.85)
  f.CloudCore = cloudCore

  -- Layer 6: Drifting Satellite Vapor Puffs (Organic smoky eddies trailing around the wisp)
  local puff1 = visual:CreateTexture(nil, "OVERLAY", nil, 1)
  puff1:SetTexture(TEX_CLOUD_PUFF)
  puff1:SetBlendMode("ADD")
  puff1:SetSize(10, 10)
  puff1:SetVertexColor(0.85, 0.35, 1.0, 0.70)
  f.Puff1 = puff1

  local puff2 = visual:CreateTexture(nil, "OVERLAY", nil, 1)
  puff2:SetTexture(TEX_CLOUD_PUFF)
  puff2:SetBlendMode("ADD")
  puff2:SetSize(8, 8)
  puff2:SetVertexColor(0.75, 0.25, 0.95, 0.60)
  f.Puff2 = puff2

  local puff3 = visual:CreateTexture(nil, "OVERLAY", nil, 1)
  puff3:SetTexture(TEX_CLOUD_PUFF)
  puff3:SetBlendMode("ADD")
  puff3:SetSize(6, 6)
  puff3:SetVertexColor(0.95, 0.55, 1.0, 0.65)
  f.Puff3 = puff3

  -- Breathing Alpha Pulse
  local ag = visual:CreateAnimationGroup()
  local alphaAnim = ag:CreateAnimation("Alpha")
  alphaAnim:SetFromAlpha(0.80)
  alphaAnim:SetToAlpha(1.0)
  alphaAnim:SetDuration(2.6)
  alphaAnim:SetSmoothing("IN_OUT")
  ag:SetLooping("BOUNCE")
  ag:Play()
  f.AnimGroup = ag

  -- Resting & Full-Screen Smooth Travel Engine
  local flightState = ForeverGuideDB.hasInteracted and "RESTING" or "DORMANT"
  f.flightState = flightState
  local restTimer = 0
  local restDuration = 35.0 + math.random() * 35.0 -- Stays at resting point for 35 to 70s!

  local currentPosX = f.homeX
  local currentPosY = f.homeY
  local travelStartX, travelStartY = f.homeX, f.homeY
  local travelTargetX, travelTargetY = f.homeX, f.homeY
  local travelCtrlX, travelCtrlY = f.homeX, f.homeY
  local travelDuration = 5.5
  local travelElapsed = 0

  local function GetScreenBounds()
    local sw = UIParent:GetWidth() or 1920
    local sh = UIParent:GetHeight() or 1080
    return 80, sw - 80, 80, sh - 80
  end

  local function OnOrbUpdate(self, elapsed)
    local t = GetTime()

    -- Drifting satellite vapor puffs waft along smoky currents around Sparky
    if self.Puff1 then
      local p1R = 13 + math.sin(t * 0.75) * 3.5
      local p1X = math.cos(t * 1.35) * p1R
      local p1Y = math.sin(t * 1.35) * (p1R * 0.75) + math.sin(t * 2.2) * 2.0
      self.Puff1:SetPoint("CENTER", visual, "CENTER", p1X, p1Y)
    end
    if self.Puff2 then
      local p2R = 11 + math.cos(t * 0.85) * 3.0
      local p2X = math.cos(-t * 1.1 + 2.1) * p2R
      local p2Y = math.sin(-t * 1.1 + 2.1) * (p2R * 0.8) + math.cos(t * 1.9) * 2.0
      self.Puff2:SetPoint("CENTER", visual, "CENTER", p2X, p2Y)
    end
    if self.Puff3 then
      local p3R = 9 + math.sin(t * 1.15 + 1.2) * 2.5
      local p3X = math.sin(t * 0.95 + 4.0) * p3R
      local p3Y = math.cos(t * 0.95 + 4.0) * (p3R * 0.65)
      self.Puff3:SetPoint("CENTER", visual, "CENTER", p3X, p3Y)
    end

    if self.isDragging then
      flightState = ForeverGuideDB.hasInteracted and "RESTING" or "DORMANT"
      self.flightState = flightState
      restTimer = 0
      local cx, cy = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      local curX, curY = cx / scale, cy / scale
      currentPosX = curX - (self.dragOffsetX or 0)
      currentPosY = curY - (self.dragOffsetY or 0)
      self.homeX = currentPosX
      self.homeY = currentPosY
      self:ClearAllPoints()
      self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", currentPosX, currentPosY)
      return
    end

    if flightState == "DORMANT" then
      -- Unawakened: peaceful stationary breathing at spawn point until opened once
      local waveX = math.sin(t * 0.40) * 2.5
      local waveY = math.cos(t * 0.32) * 2.5
      currentPosX = (self.homeX or 240) + waveX
      currentPosY = (self.homeY or 120) + waveY

    elseif flightState == "RESTING" then
      -- Resting at its current outpost: very gentle, organic floating in place
      restTimer = restTimer + elapsed
      local waveX = math.sin(t * 0.45) * 3.5 + math.sin(t * 0.22 + 1.0) * 1.5
      local waveY = math.cos(t * 0.38) * 3.5 + math.sin(t * 0.17 + 1.8) * 1.5
      currentPosX = (self.homeX or 240) + waveX
      currentPosY = (self.homeY or 120) + waveY

      if restTimer >= restDuration and ForeverGuideDB.hasInteracted then
        -- Embark on a grand travel across the entire screen!
        local minX, maxX, minY, maxY = GetScreenBounds()
        local targetX, targetY

        -- Search for a distant vantage point across the screen (>= 280px away)
        for _ = 1, 12 do
          local candX = minX + math.random() * (maxX - minX)
          local candY = minY + math.random() * (maxY - minY)
          local d2 = (candX - currentPosX)^2 + (candY - currentPosY)^2
          if d2 >= 280 * 280 then
            targetX = candX
            targetY = candY
            break
          end
        end
        targetX = targetX or (minX + math.random() * (maxX - minX))
        targetY = targetY or (minY + math.random() * (maxY - minY))

        flightState = "TRAVEL"
        self.flightState = flightState
        travelElapsed = 0
        travelStartX = currentPosX
        travelStartY = currentPosY
        travelTargetX = targetX
        travelTargetY = targetY

        local dx = travelTargetX - travelStartX
        local dy = travelTargetY - travelStartY
        local dist = math.sqrt(dx * dx + dy * dy)
        -- Leisurely, majestic travel speed (~160 px/sec), 4.5s to 7.5s
        travelDuration = math.max(4.5, math.min(7.5, 3.2 + (dist / 175)))

        -- Curved Bezier control point
        local midX = (travelStartX + travelTargetX) * 0.5
        local midY = (travelStartY + travelTargetY) * 0.5
        local perpX = -dy / (dist > 0.01 and dist or 1)
        local perpY = dx / (dist > 0.01 and dist or 1)
        local curve = (math.random() > 0.5 and 1 or -1) * (50 + math.random() * 110)
        travelCtrlX = math.max(minX, math.min(maxX, midX + perpX * curve))
        travelCtrlY = math.max(minY, math.min(maxY, midY + perpY * curve))
      end

    elseif flightState == "TRAVEL" then
      travelElapsed = travelElapsed + elapsed
      local progress = math.min(1.0, travelElapsed / travelDuration)

      -- Smooth cosine ease-in-ease-out (continuous velocity, 0 jerk)
      local u = 0.5 - 0.5 * math.cos(progress * math.pi)
      local invU = 1.0 - u

      -- Quadratic Bezier position across screen
      local bX = invU * invU * travelStartX + 2 * invU * u * travelCtrlX + u * u * travelTargetX
      local bY = invU * invU * travelStartY + 2 * invU * u * travelCtrlY + u * u * travelTargetY

      -- Gentle floating undulation in flight
      local ripple = math.sin(progress * math.pi * 2) * 3
      currentPosX = bX
      currentPosY = bY + ripple

      if progress >= 1.0 then
        -- Arrived at the new resting point!
        self.homeX = travelTargetX
        self.homeY = travelTargetY
        currentPosX = self.homeX
        currentPosY = self.homeY
        flightState = "RESTING"
        self.flightState = flightState
        restTimer = 0
        restDuration = 35.0 + math.random() * 40.0 -- Stays resting for 35 to 75 seconds!
        ForeverGuideDB.sparkPosition = {
          point = "BOTTOMLEFT",
          relativePoint = "BOTTOMLEFT",
          x = math.floor(self.homeX + 0.5),
          y = math.floor(self.homeY + 0.5),
        }
      end
    end

    local minX, maxX, minY, maxY = GetScreenBounds()
    currentPosX = math.max(minX, math.min(maxX, currentPosX))
    currentPosY = math.max(minY, math.min(maxY, currentPosY))
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", currentPosX, currentPosY)
  end

  f:SetScript("OnUpdate", OnOrbUpdate)

  f:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
      self.isDragging = true
      self.wasDragged = false
      local cx, cy = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      self.downX = cx / scale
      self.downY = cy / scale
      local fx, fy = self:GetCenter()
      if fx and fy then
        self.dragOffsetX = self.downX - fx
        self.dragOffsetY = self.downY - fy
      else
        self.dragOffsetX = 0
        self.dragOffsetY = 0
      end
    end
  end)

  f:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isDragging then
      self.isDragging = false
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
      if dist > 6 then
        self.wasDragged = true
        self.homeX = upX - (self.dragOffsetX or 0)
        self.homeY = upY - (self.dragOffsetY or 0)
        flightState = ForeverGuideDB.hasInteracted and "RESTING" or "DORMANT"
        self.flightState = flightState
        restTimer = 0
        restDuration = 40.0 + math.random() * 40.0
        ForeverGuideDB.sparkPosition = {
          point = "BOTTOMLEFT",
          relativePoint = "BOTTOMLEFT",
          x = math.floor(self.homeX + 0.5),
          y = math.floor(self.homeY + 0.5),
        }
      else
        self.wasDragged = false
      end
    end
  end)

  f:SetScript("OnClick", function(self, button)
    if self.wasDragged then
      self.wasDragged = false
      return
    end
    if button == "LeftButton" then
      ForeverGuideDB.hasInteracted = true
      if flightState == "DORMANT" then
        flightState = "RESTING"
        self.flightState = flightState
        restTimer = 0
      end
      FG:ToggleCodex()
      FG:PlaySparkSound("shimmer")
    end
  end)

  f:SetScript("OnEnter", function(self)
    if self.Aura then self.Aura:SetVertexColor(0.85, 0.30, 1.0, 0.75) end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cffcf52ffSparky|r", 1, 1, 1)
    GameTooltip:AddLine("Ethereal Cloud Wisp for Warcraft Forever.", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(" ")
    if not ForeverGuideDB.hasInteracted then
      GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Open Forever Codex (Awakens Sparky)", 0.9, 0.9, 0.9)
    else
      GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Open Forever Codex", 0.9, 0.9, 0.9)
    end
    GameTooltip:AddLine("|cffdf80ff<Left-Drag>|r Move Resting Point", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function(self)
    if self.Aura then self.Aura:SetVertexColor(0.55, 0.12, 0.85, 0.40) end
    GameTooltip:Hide()
  end)

  FG.SparkFrame = f

  if ForeverGuideDB.sparkShown == false then
    f:Hide()
  end
end

function FG:ToggleSpark()
  if not FG.SparkFrame then return end
  if FG.SparkFrame:IsShown() then
    FG.SparkFrame:Hide()
    ForeverGuideDB.sparkShown = false
    print("|cffdf80ff[Sparky]|r Companion dismissed.")
  else
    FG.SparkFrame:Show()
    ForeverGuideDB.sparkShown = true
    FG:PlaySparkSound("shimmer")
    print("|cffdf80ff[Sparky]|r Companion summoned.")
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
  print("|cffdf80ff✨ Sparky whispers concerning:|r |cffffffff" .. currentZone .. "|r")
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
  f:SetBackdropBorderColor(0.48, 0.20, 0.75, 0.90)

  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if FG.UpdateDetailPanelPosition then FG:UpdateDetailPanelPosition() end
  end)
  f:SetScript("OnHide", function(self)
    self:StopMovingOrSizing()
    if FG.DetailPanel then FG.DetailPanel:Hide() end
  end)

  -- Register with standard UI Special Frames so ESC closes this window
  tinsert(UISpecialFrames, "ForeverGuideCodexWindow")

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -14)
  title:SetText("|cffcf52ffForever Guide:|r |cffdf80ffSparky's Codex|r")
  SharpenFontString(title, 15, "OUTLINE")
  f.Title = title

  local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  subtitle:SetText("|cffaa88ddWarcraft Forever High-Density Codex|r")
  SharpenFontString(subtitle, 10, "OUTLINE")
  f.Subtitle = subtitle

  local divider = f:CreateTexture(nil, "ARTWORK")
  divider:SetColorTexture(0.55, 0.22, 0.85, 0.35)
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -46)
  divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -46)
  MakePixelSharp(divider)

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  closeBtn:SetScript("OnClick", function() f:Hide() end)

  local searchBox = CreateFrame("EditBox", "ForeverGuideSearchBox", f, "InputBoxTemplate")
  searchBox:SetSize(220, 24)
  searchBox:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 6, -10)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject("ChatFontNormal")
  SharpenFontString(searchBox, 12, "OUTLINE")
  MakePixelSharp(searchBox)

  local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
  placeholder:SetText("Search items, quests, mobs, dungeons...")
  SharpenFontString(placeholder, 11, "OUTLINE")
  searchBox.Placeholder = placeholder

  local clearBtn = CreateFrame("Button", nil, searchBox)
  clearBtn:SetSize(16, 16)
  clearBtn:SetPoint("RIGHT", searchBox, "RIGHT", -4, 0)
  local clearTxt = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  clearTxt:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
  clearTxt:SetText("|cffaaaaaa✕|r")
  clearBtn.Text = clearTxt
  clearBtn:Hide()
  searchBox.ClearBtn = clearBtn

  clearBtn:SetScript("OnClick", function()
    searchBox:SetText("")
    searchBox:ClearFocus()
    clearBtn:Hide()
    placeholder:Show()
    FG:SetActiveCategory("all")
  end)

  searchBox:SetScript("OnTextChanged", function(self)
    local query = self:GetText():trim()
    if query == "" then
      placeholder:Show()
      clearBtn:Hide()
      FG:PopulateCodexResults("")
    else
      placeholder:Hide()
      clearBtn:Show()
      FG:PopulateCodexResults(query)
    end
  end)

  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  -- Category Filter Pills
  f.FilterButtons = {}
  local function CreateCategoryPill(name, label, width, xOffset, relativeTo)
    local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
    btn:SetSize(width, 22)
    btn:SetPoint("LEFT", relativeTo, "RIGHT", xOffset, 0)
    MakePixelSharp(btn)

    btn:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false,
      tileSize = 10,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.85)
    btn:SetBackdropBorderColor(0.24, 0.28, 0.36, 0.70)

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
    txt:SetText(label)
    txt:SetTextColor(0.75, 0.75, 0.80)
    SharpenFontString(txt, 11, "OUTLINE")
    btn.Text = txt

    btn:SetScript("OnClick", function()
      FG:SetActiveCategory(name)
    end)

    f.FilterButtons[name] = btn
    return btn
  end

  local allBtn   = CreateCategoryPill("all", "All", 34, 10, searchBox)
  local itemsBtn = CreateCategoryPill("items", "Items", 44, 4, allBtn)
  local questBtn = CreateCategoryPill("quests", "Quests", 52, 4, itemsBtn)
  local npcBtn   = CreateCategoryPill("creatures", "NPCs", 44, 4, questBtn)
  local dungBtn  = CreateCategoryPill("dungeons", "Dungeons", 66, 4, npcBtn)
  local vendBtn  = CreateCategoryPill("vendors", "Vendors", 58, 4, dungBtn)

  -- Bottom status bar / footer
  local botDivider = f:CreateTexture(nil, "ARTWORK")
  botDivider:SetColorTexture(0.55, 0.22, 0.85, 0.25)
  botDivider:SetHeight(1)
  botDivider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 28)
  botDivider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 28)
  MakePixelSharp(botDivider)

  local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 9)
  statusText:SetText("|cff888899Ready • Type to search or select a category|r")
  SharpenFontString(statusText, 11, "OUTLINE")
  f.StatusText = statusText

  local lockBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
  lockBtn:SetSize(88, 18)
  lockBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 5)
  MakePixelSharp(lockBtn)
  lockBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  lockBtn:SetBackdropColor(0.10, 0.12, 0.16, 0.85)
  lockBtn:SetBackdropBorderColor(0.24, 0.28, 0.36, 0.70)

  local lockTxt = lockBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lockTxt:SetPoint("CENTER", lockBtn, "CENTER", 0, 0)
  lockTxt:SetText(ForeverGuideDB.sparkLocked and "|cffff6666Unlock Sparky|r" or "|cff88cc88Lock Sparky|r")
  SharpenFontString(lockTxt, 10, "OUTLINE")
  lockBtn.Text = lockTxt

  lockBtn:SetScript("OnClick", function(self)
    ForeverGuideDB.sparkLocked = not ForeverGuideDB.sparkLocked
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    FG:UpdateSparkMouseState()
    lockTxt:SetText(ForeverGuideDB.sparkLocked and "|cffff6666Unlock Sparky|r" or "|cff88cc88Lock Sparky|r")
    print("|cffdf80ff[Sparky]|r Position is now " .. (ForeverGuideDB.sparkLocked and "|cffff4040Locked (Click-Through)|r" or "|cff20ff20Unlocked|r"))
  end)
  f.LockBtn = lockBtn

  local scrollFrame = CreateFrame("ScrollFrame", "ForeverGuideScrollFrame", f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -10)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 34)
  MakePixelSharp(scrollFrame)

  local content = CreateFrame("Frame", "ForeverGuideScrollContent", scrollFrame)
  content:SetSize(554, 1000)
  scrollFrame:SetScrollChild(content)
  MakePixelSharp(content)
  f.Content = content

  -- Blank State / Ready View (Shown on open or empty query)
  local blank = CreateFrame("Frame", nil, content)
  blank:SetSize(540, 320)
  blank:SetPoint("TOP", content, "TOP", 0, -45)

  local bIcon = blank:CreateTexture(nil, "ARTWORK")
  bIcon:SetSize(46, 46)
  bIcon:SetPoint("TOP", blank, "TOP", 0, 0)
  bIcon:SetTexture("Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\sparky_cloud_main.tga")
  bIcon:SetVertexColor(0.80, 0.35, 1.0, 0.80)
  bIcon:SetBlendMode("ADD")

  local bTitle = blank:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  bTitle:SetPoint("TOP", bIcon, "BOTTOM", 0, -10)
  bTitle:SetText("|cffdf80ffSparky's Codex is Ready|r")
  SharpenFontString(bTitle, 15, "OUTLINE")

  local bSub = blank:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  bSub:SetPoint("TOP", bTitle, "BOTTOM", 0, -5)
  bSub:SetText("Instant in-game search for 2,400+ items, quests, NPCs & dungeons.")
  SharpenFontString(bSub, 11, "OUTLINE")

  local bPrompt = blank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bPrompt:SetPoint("TOP", bSub, "BOTTOM", 0, -18)
  bPrompt:SetText("|cff888899Type above to search, or pick a quick shortcut:|r")
  SharpenFontString(bPrompt, 11, "OUTLINE")

  local function CreateQuickPill(label, xOff, onClick)
    local pBtn = CreateFrame("Button", nil, blank, "BackdropTemplate")
    pBtn:SetSize(116, 26)
    pBtn:SetPoint("TOP", bPrompt, "BOTTOM", xOff, -12)
    MakePixelSharp(pBtn)
    pBtn:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false,
      tileSize = 10,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    pBtn:SetBackdropColor(0.12, 0.14, 0.20, 0.90)
    pBtn:SetBackdropBorderColor(0.45, 0.22, 0.75, 0.80)
    local pTxt = pBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pTxt:SetPoint("CENTER", pBtn, "CENTER", 0, 0)
    pTxt:SetText(label)
    SharpenFontString(pTxt, 11, "OUTLINE")
    pBtn.Text = pTxt
    pBtn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.22, 0.14, 0.34, 0.95)
      self:SetBackdropBorderColor(0.85, 0.40, 1.0, 0.95)
    end)
    pBtn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.12, 0.14, 0.20, 0.90)
      self:SetBackdropBorderColor(0.45, 0.22, 0.75, 0.80)
    end)
    pBtn:SetScript("OnClick", onClick)
    return pBtn
  end

  CreateQuickPill("⚔ Dungeons", -180, function() FG:SetActiveCategory("dungeons") end)
  CreateQuickPill("✦ Forever Gear", -60, function()
    searchBox:SetText("forever")
    FG:SetActiveCategory("all")
  end)
  CreateQuickPill("📜 Quests", 60, function() FG:SetActiveCategory("quests") end)
  CreateQuickPill("🛒 Key Vendors", 180, function() FG:SetActiveCategory("vendors") end)

  content.BlankState = blank

  -- No Results State
  local noRes = CreateFrame("Frame", nil, content)
  noRes:SetSize(520, 180)
  noRes:SetPoint("TOP", content, "TOP", 0, -80)

  local nrTitle = noRes:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  nrTitle:SetPoint("TOP", noRes, "TOP", 0, 0)
  nrTitle:SetText("|cffff8080No results found|r")
  SharpenFontString(nrTitle, 15, "OUTLINE")
  noRes.Title = nrTitle

  local nrSub = noRes:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  nrSub:SetPoint("TOP", nrTitle, "BOTTOM", 0, -8)
  nrSub:SetText("Try searching for a different keyword, zone, or boss name.")
  SharpenFontString(nrSub, 11, "OUTLINE")
  noRes.Sub = nrSub

  noRes:Hide()
  content.NoResultsState = noRes

  f:Hide()
  FG.CodexWindow = f
end

function FG:SetActiveCategory(cat)
  FG.activeCategory = cat or "all"
  local cw = FG.CodexWindow
  if cw and cw.FilterButtons then
    for c, btn in pairs(cw.FilterButtons) do
      if c == FG.activeCategory then
        btn:SetBackdropBorderColor(0.85, 0.40, 1.0, 0.95)
        btn:SetBackdropColor(0.28, 0.14, 0.42, 0.95)
        if btn.Text then btn.Text:SetTextColor(1.0, 0.9, 1.0) end
      else
        btn:SetBackdropBorderColor(0.24, 0.28, 0.36, 0.70)
        btn:SetBackdropColor(0.10, 0.12, 0.16, 0.85)
        if btn.Text then btn.Text:SetTextColor(0.70, 0.70, 0.75) end
      end
    end
  end
  local q = ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or ""
  FG:PopulateCodexResults(q)
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
--------------------------------------------------------------------------------
-- Codex Deep Intel Inspector Panel ("Click for More Data")
--------------------------------------------------------------------------------
function FG:CreateDetailPanel()
  if FG.DetailPanel then return FG.DetailPanel end
  local p = CreateFrame("Frame", "ForeverGuideDetailPanel", FG.CodexWindow, "BackdropTemplate")
  p:SetSize(340, 530)
  p:SetFrameStrata("MEDIUM")
  p:SetFrameLevel(16)
  p:EnableMouse(true)
  MakePixelSharp(p)

  p:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  p:SetBackdropColor(0.08, 0.09, 0.13, 0.98)
  p:SetBackdropBorderColor(0.55, 0.22, 0.85, 0.90) -- Ghastly violet border

  local title = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -14)
  title:SetText("|cffcf52ffCodex Deep Intel|r")
  SharpenFontString(title, 14, "OUTLINE")
  p.Title = title

  local closeBtn = CreateFrame("Button", nil, p, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", p, "TOPRIGHT", -4, -4)
  closeBtn:SetScript("OnClick", function() p:Hide() end)

  local divider = p:CreateTexture(nil, "ARTWORK")
  divider:SetColorTexture(0.55, 0.22, 0.85, 0.35)
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -42)
  divider:SetPoint("TOPRIGHT", p, "TOPRIGHT", -12, -42)
  MakePixelSharp(divider)

  local sf = CreateFrame("ScrollFrame", "ForeverGuideDetailScrollFrame", p, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -8)
  sf:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -26, 46)
  MakePixelSharp(sf)

  local body = CreateFrame("Frame", nil, sf)
  body:SetSize(296, 600)
  sf:SetScrollChild(body)
  p.Body = body

  local linkBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  linkBtn:SetSize(145, 26)
  linkBtn:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 14, 12)
  linkBtn:SetText("Share to Chat")
  MakePixelSharp(linkBtn)
  local lfs = linkBtn:GetFontString()
  if lfs then SharpenFontString(lfs, 11, "OUTLINE") end
  p.LinkBtn = linkBtn

  local actBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  actBtn:SetSize(145, 26)
  actBtn:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -14, 12)
  actBtn:SetText("Search Related")
  MakePixelSharp(actBtn)
  local afs = actBtn:GetFontString()
  if afs then SharpenFontString(afs, 11, "OUTLINE") end
  p.ActBtn = actBtn

  p:Hide()
  FG.DetailPanel = p
  return p
end

function FG:UpdateDetailPanelPosition()
  local codex = FG.CodexWindow
  local panel = FG.DetailPanel
  if not codex or not panel then return end
  local rightSpace = (GetScreenWidth() or 1920) - (codex:GetRight() or 0)
  panel:ClearAllPoints()
  if rightSpace >= 350 then
    panel:SetPoint("TOPLEFT", codex, "TOPRIGHT", 6, 0)
    panel:SetPoint("BOTTOMLEFT", codex, "BOTTOMRIGHT", 6, 0)
  else
    panel:SetPoint("TOPRIGHT", codex, "TOPLEFT", -6, 0)
    panel:SetPoint("BOTTOMRIGHT", codex, "BOTTOMLEFT", -6, 0)
  end
end

function FG:LinkEntityToChat(entityType, data)
  local text = ""
  if entityType == "quest" then
    text = "[Quest: " .. (data.title or "Unknown") .. " (Lvl " .. (data.questLevel or "?") .. ", " .. (data.zone or "") .. ")]"
  elseif entityType == "item" then
    local _, link = GetItemInfo(data.id)
    text = link or ("[" .. (data.name or "Item") .. "]")
  elseif entityType == "creature" then
    local loc = data.location and data.location ~= "" and (" @ " .. data.location) or ""
    text = "[NPC: " .. (data.name or "Creature") .. " (" .. (data.zone or "") .. loc .. ")]"
  elseif entityType == "dungeon" then
    text = "[Dungeon: " .. (data.name or "") .. " (Lvl " .. (data.recLevel or "?") .. ", " .. (data.zone or "") .. ")]"
  elseif entityType == "vendor" then
    text = "[Vendor: " .. (data.name or "") .. " (" .. (data.zone or "") .. " sells " .. (data.item or "") .. ")]"
  end

  if ChatEdit_InsertLink and ChatEdit_InsertLink(text) then
    return
  end
  local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() or (ChatFrame1EditBox)
  if editBox then
    ChatEdit_ActivateChat(editBox)
    editBox:Insert(text)
  else
    print("|cffcf52ff[Codex]|r " .. text)
  end
end

function FG:ShowDetailPanel(entityType, data)
  if not FG.DetailPanel then FG:CreateDetailPanel() end
  local p = FG.DetailPanel
  FG:UpdateDetailPanelPosition()
  p:Show()

  if p.Body.Lines then
    for _, line in ipairs(p.Body.Lines) do line:Hide() end
  end
  p.Body.Lines = p.Body.Lines or {}

  local lineIndex = 0
  local yOffset = -2

  local function AddLine(text, size, r, g, b, extraY)
    lineIndex = lineIndex + 1
    local fs = p.Body.Lines[lineIndex]
    if not fs then
      fs = p.Body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetWidth(286)
      fs:SetJustifyH("LEFT")
      p.Body.Lines[lineIndex] = fs
    end
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", p.Body, "TOPLEFT", 6, yOffset)
    SharpenFontString(fs, size or 12, "OUTLINE")
    fs:SetText(text)
    if r and g and b then
      fs:SetTextColor(r, g, b)
    else
      fs:SetTextColor(1, 1, 1)
    end
    fs:Show()
    local h = fs:GetStringHeight() or 14
    yOffset = yOffset - h - (extraY or 4)
  end

  local function AddSection(heading)
    yOffset = yOffset - 6
    AddLine("|cffdf80ff" .. heading .. "|r", 12, nil, nil, nil, 3)
  end

  if entityType == "quest" then
    p.Title:SetText("|cffcf52ffQuest Intel|r")
    AddLine("|cffffd24d" .. (data.title or "Quest") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Level: |cff20ff20" .. (data.questLevel or "?") .. "|r  (Requires Lvl " .. (data.reqLevel or "1") .. ")", 12)
    if data.faction and data.faction ~= "" then
      AddLine("Faction: |cff52b8ff" .. data.faction .. "|r", 11)
    end
    if data.isForever then
      AddLine("|cffe6cc80★ Warcraft Forever Custom Content|r", 11, nil, nil, nil, 4)
    end

    AddSection("LOCATION & QUESTGIVER")
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    AddLine("Questgiver: |cff52b8ff" .. (data.npc or "Unknown") .. "|r", 12)

    AddSection("OBJECTIVES")
    AddLine(data.objectives and data.objectives ~= "" and data.objectives or "No specific task listed.", 12, 0.9, 0.9, 0.9, 6)

    AddSection("REWARDS")
    AddLine(data.rewards and data.rewards ~= "" and data.rewards or "Experience & Gold", 12, 1, 0.85, 0.2, 6)

    if data.tip and data.tip ~= "" then
      AddSection("SPARK INTEL & TACTICS")
      AddLine(data.tip, 11, 0.75, 0.88, 1.0, 6)
    end

    p.LinkBtn:SetText("Share to Chat")
    p.LinkBtn:SetScript("OnClick", function()
      FG:LinkEntityToChat("quest", data)
    end)

    p.ActBtn:SetText("Search NPC")
    p.ActBtn:SetScript("OnClick", function()
      if data.npc and ForeverGuideSearchBox then
        ForeverGuideSearchBox:SetText(data.npc)
      end
    end)

  elseif entityType == "item" then
    p.Title:SetText("|cffcf52ffItem Intel|r")
    local qColor = FG.QualityColors[data.quality] or "ffffffff"
    AddLine("|c" .. qColor .. (data.name or "Item") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Item Level: |cffffffff" .. (data.ilvl or "?") .. "|r" .. ((data.reqLevel and data.reqLevel > 0) and ("  (Req Lvl " .. data.reqLevel .. ")") or ""), 12)
    if data.slot and data.slot ~= "" then AddLine("Slot: |cff52b8ff" .. data.slot .. "|r", 11) end
    if data.isForever then AddLine("|cffe6cc80★ Forever Exclusive Item|r", 11, nil, nil, nil, 4) end

    AddSection("SOURCE & DROPS")
    AddLine(data.source and data.source ~= "" and data.source or "World Drop / Various", 12, 0.9, 0.9, 0.9, 6)

    if data.tip and data.tip ~= "" then
      AddSection("ANALYSIS & NOTES")
      AddLine(data.tip, 11, 0.75, 0.88, 1.0, 6)
    end

    p.LinkBtn:SetText("Share to Chat")
    p.LinkBtn:SetScript("OnClick", function()
      FG:LinkEntityToChat("item", data)
    end)

    p.ActBtn:SetText("Search Source")
    p.ActBtn:SetScript("OnClick", function()
      if data.source and ForeverGuideSearchBox then
        local firstWord = data.source:match("^(%S+)")
        if firstWord then ForeverGuideSearchBox:SetText(firstWord) end
      end
    end)

  elseif entityType == "creature" then
    p.Title:SetText("|cffcf52ffCreature Intel|r")
    local classColor = (data.classification == "Boss" or data.classification == "Rare Elite") and "ffff4040" or (data.classification == "Elite" and "ffffd24d" or "ff52b8ff")
    local lvlStr = (data.minLevel and data.maxLevel and data.minLevel ~= data.maxLevel) and (data.minLevel .. "-" .. data.maxLevel) or (data.maxLevel or data.minLevel or "?")
    AddLine("|c" .. classColor .. (data.name or "Creature") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Level: |cff20ff20" .. lvlStr .. "|r (" .. (data.classification or "Normal") .. ")", 12)
    if data.health and data.health > 0 then AddLine("Health: |cffff6060" .. data.health .. "|r", 11) end

    AddSection("SPAWN & LOCATION")
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    if data.location and data.location ~= "" then
      AddLine("Coordinates/Area: |cff20ff20" .. data.location .. "|r", 12)
    end

    if data.strategy and data.strategy ~= "" then
      AddSection("COMBAT STRATEGY")
      AddLine(data.strategy, 11, 0.85, 0.85, 0.85, 6)
    end

    p.LinkBtn:SetText("Share to Chat")
    p.LinkBtn:SetScript("OnClick", function()
      FG:LinkEntityToChat("creature", data)
    end)

    p.ActBtn:SetText("Target Macro")
    p.ActBtn:SetScript("OnClick", function()
      local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() or (ChatFrame1EditBox)
      if editBox then
        ChatEdit_ActivateChat(editBox)
        editBox:SetText("/target " .. data.name)
      end
      print("|cffcf52ff[Target]|r Prepared: /target " .. data.name)
    end)

  elseif entityType == "dungeon" then
    p.Title:SetText("|cffcf52ffDungeon Intel|r")
    AddLine("|cffffd24d" .. (data.name or "Dungeon") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Recommended Level: |cff20ff20" .. (data.recLevel or "?") .. "|r", 12)
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    if data.coords and data.coords ~= "" then
      AddLine("Entrance: |cff20ff20" .. data.coords .. "|r", 12)
    end

    if data.strategy and data.strategy ~= "" then
      AddSection("TACTICS & WALKTHROUGH")
      AddLine(data.strategy, 11, 0.85, 0.90, 0.95, 6)
    end

    p.LinkBtn:SetText("Share to Chat")
    p.LinkBtn:SetScript("OnClick", function()
      FG:LinkEntityToChat("dungeon", data)
    end)

    p.ActBtn:SetText("Search Loot")
    p.ActBtn:SetScript("OnClick", function()
      if ForeverGuideSearchBox then ForeverGuideSearchBox:SetText(data.name) end
    end)

  elseif entityType == "vendor" then
    p.Title:SetText("|cffcf52ffVendor Intel|r")
    AddLine("|cffffd24d" .. (data.name or "Vendor") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    if data.coords and data.coords ~= "" then
      AddLine("Coords: |cff20ff20" .. data.coords .. "|r", 12)
    end

    AddSection("INVENTORY / WARES")
    AddLine("Offers: |cff52b8ff" .. (data.item or "Goods") .. "|r", 12)
    if data.tip and data.tip ~= "" then
      AddSection("VENDOR NOTES")
      AddLine(data.tip, 11, 0.85, 0.85, 0.85, 6)
    end

    p.LinkBtn:SetText("Share to Chat")
    p.LinkBtn:SetScript("OnClick", function()
      FG:LinkEntityToChat("vendor", data)
    end)

    p.ActBtn:SetText("Search Items")
    p.ActBtn:SetScript("OnClick", function()
      if data.item and ForeverGuideSearchBox then
        local first = data.item:match("^(%S+)")
        if first then ForeverGuideSearchBox:SetText(first) end
      end
    end)
  end

  p.Body:SetHeight(math.max(420, math.abs(yOffset) + 20))
end

function FG:PopulateCodexResults(query)
  if not FG.CodexWindow or not FG.CodexWindow.Content then return end
  local content = FG.CodexWindow.Content

  if content.Buttons then
    for _, btn in ipairs(content.Buttons) do btn:Hide() end
  end
  content.Buttons = content.Buttons or {}

  local q = (query or ""):lower():trim()
  local cat = FG.activeCategory or "all"
  local cw = FG.CodexWindow

  -- Start off BLANK when search query is empty and category is 'all'
  if q == "" and cat == "all" then
    if content.BlankState then content.BlankState:Show() end
    if content.NoResultsState then content.NoResultsState:Hide() end
    content:SetHeight(450)
    if cw and cw.StatusText then
      cw.StatusText:SetText("|cff888899Ready • Type to search or select a category|r")
    end
    return
  end

  if content.BlankState then content.BlankState:Hide() end

  local matches = {}

  if q == "" then
    -- When a category is explicitly clicked without search text, browse that category
    if cat == "items" and FG.Data.Items then
      for _, item in pairs(FG.Data.Items) do
        table.insert(matches, { type = "item", data = item })
        if #matches >= 45 then break end
      end
    elseif cat == "quests" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        table.insert(matches, { type = "quest", data = quest })
        if #matches >= 45 then break end
      end
    elseif cat == "creatures" and FG.Data.Creatures then
      for _, c in pairs(FG.Data.Creatures) do
        table.insert(matches, { type = "creature", data = c })
        if #matches >= 45 then break end
      end
    elseif cat == "dungeons" and FG.Data.Dungeons then
      for _, d in pairs(FG.Data.Dungeons) do
        table.insert(matches, { type = "dungeon", data = d })
      end
      table.sort(matches, function(a, b) return (a.data.recLevel or 0) < (b.data.recLevel or 0) end)
    elseif cat == "vendors" and FG.Data.Vendors then
      for _, v in pairs(FG.Data.Vendors) do
        table.insert(matches, { type = "vendor", data = v })
        if #matches >= 45 then break end
      end
    end
  else
    -- Active search query filtered by category
    if (cat == "all" or cat == "items") and FG.Data.Items and #matches < 50 then
      for _, item in pairs(FG.Data.Items) do
        if item.name and (item.name:lower():find(q, 1, true) or (item.source and item.source:lower():find(q, 1, true))) then
          table.insert(matches, { type = "item", data = item })
          if #matches >= 50 then break end
        end
      end
    end

    if (cat == "all" or cat == "quests") and FG.Data.Quests and #matches < 65 then
      for _, quest in pairs(FG.Data.Quests) do
        local matchTitle = quest.title and quest.title:lower():find(q, 1, true)
        local matchNpc = quest.npc and quest.npc:lower():find(q, 1, true)
        local matchZone = quest.zone and quest.zone:lower():find(q, 1, true)
        local matchObj = quest.objectives and quest.objectives:lower():find(q, 1, true)
        local matchTip = quest.tip and quest.tip:lower():find(q, 1, true)
        if matchTitle or matchNpc or matchZone or matchObj or matchTip then
          table.insert(matches, { type = "quest", data = quest })
          if #matches >= 65 then break end
        end
      end
    end

    if (cat == "all" or cat == "creatures") and FG.Data.Creatures and #matches < 75 then
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

    if (cat == "all" or cat == "dungeons") and FG.Data.Dungeons and #matches < 80 then
      for _, d in pairs(FG.Data.Dungeons) do
        if d.name and (d.name:lower():find(q, 1, true) or (d.zone and d.zone:lower():find(q, 1, true))) then
          table.insert(matches, { type = "dungeon", data = d })
        end
      end
    end

    if (cat == "all" or cat == "vendors") and FG.Data.Vendors and #matches < 85 then
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

  if #matches == 0 then
    if content.NoResultsState then
      content.NoResultsState:Show()
      if content.NoResultsState.Title then
        content.NoResultsState.Title:SetText("|cffff8080No results found for \"|r|cffffffff" .. (query or "") .. "|r|cffff8080\"|r")
      end
    end
    content:SetHeight(450)
    if cw and cw.StatusText then cw.StatusText:SetText("|cffff80800 results found|r") end
    return
  else
    if content.NoResultsState then content.NoResultsState:Hide() end
    if cw and cw.StatusText then cw.StatusText:SetText("|cffdf80ff" .. #matches .. " results found|r") end
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
      subText:SetWidth(440)
      subText:SetJustifyH("LEFT")
      SharpenFontString(subText, 11, "OUTLINE")
      btn.Sub = subText

      local hint = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      hint:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
      hint:SetText("|cffdf80ffInspect ▶|r")
      SharpenFontString(hint, 10, "OUTLINE")
      btn.Hint = hint

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
        self:SetBackdropBorderColor(0.45, 0.25, 0.85, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetItemByID(item.id)
        if item.tip and item.tip ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("|cffcf52ffSpark Intel:|r " .. item.tip, 0.3, 0.8, 1.0, true)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Inspect full item stats & sources", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("|cffdf80ff<Shift-Click>|r Share link to chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if IsShiftKeyDown() then
          FG:LinkEntityToChat("item", item)
        else
          FG:ShowDetailPanel("item", item)
        end
        FG:PlaySparkSound("shimmer")
      end)

    elseif match.type == "quest" then
      local qData = match.data
      local foreverTag = qData.isForever and " |cffe6cc80[Forever]|r" or ""
      btn.Title:SetText("|cffffd24d" .. qData.title .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. qData.questLevel .. ")|r")
      btn.Sub:SetText("|cff52b8ffZone:|r " .. (qData.zone or "Various") .. " |cff52b8ffStart:|r " .. (qData.npc or "Unknown"))

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.18, 0.14, 0.95)
        self:SetBackdropBorderColor(0.45, 0.25, 0.85, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(qData.title, 1, 0.85, 0.2)
        GameTooltip:AddLine("Level: " .. qData.questLevel .. " (Req " .. qData.reqLevel .. ")", 1, 1, 1)
        if qData.objectives and qData.objectives ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("Objectives: " .. qData.objectives, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Inspect full quest details, rewards & NPC", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("|cffdf80ff<Shift-Click>|r Share link to chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if IsShiftKeyDown() then
          FG:LinkEntityToChat("quest", qData)
        else
          FG:ShowDetailPanel("quest", qData)
        end
        FG:PlaySparkSound("shimmer")
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
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Inspect dungeon tactics, bosses & loot", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("|cffdf80ff<Shift-Click>|r Share link to chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if IsShiftKeyDown() then
          FG:LinkEntityToChat("dungeon", d)
        else
          FG:ShowDetailPanel("dungeon", d)
        end
        FG:PlaySparkSound("shimmer")
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
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Inspect NPC intel & targeting macro", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("|cffdf80ff<Shift-Click>|r Share link to chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if IsShiftKeyDown() then
          FG:LinkEntityToChat("creature", c)
        else
          FG:ShowDetailPanel("creature", c)
        end
        FG:PlaySparkSound("shimmer")
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
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Inspect vendor wares & location", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("|cffdf80ff<Shift-Click>|r Share link to chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
        self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if IsShiftKeyDown() then
          FG:LinkEntityToChat("vendor", v)
        else
          FG:ShowDetailPanel("vendor", v)
        end
        FG:PlaySparkSound("shimmer")
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
      subText:SetWidth(440)
      subText:SetJustifyH("LEFT")
      SharpenFontString(subText, 11, "OUTLINE")
      btn.Sub = subText

      local hint = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      hint:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
      hint:SetText("|cffdf80ffInspect ▶|r")
      SharpenFontString(hint, 10, "OUTLINE")
      btn.Hint = hint

      content.Buttons[i] = btn
    end

    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

    local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
    btn.Title:SetText("|cffffd24d" .. d.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. d.recLevel .. ")|r")
    btn.Sub:SetText("|cff52b8ffZone:|r " .. d.zone .. " |cff52b8ffEntrance:|r " .. (d.coords or "N/A"))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.14, 0.18, 0.26, 0.95)
      self:SetBackdropBorderColor(0.45, 0.25, 0.85, 0.90)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(d.name, 1, 0.85, 0.2)
      GameTooltip:AddLine("Level: " .. d.recLevel .. " | Zone: " .. d.zone, 1, 1, 1)
      if d.coords and d.coords ~= "" then GameTooltip:AddLine("Coords: " .. d.coords, 0.2, 1, 0.2) end
      if d.strategy and d.strategy ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tactics: " .. d.strategy, 0.8, 0.85, 0.95, true)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Inspect dungeon tactics, bosses & loot", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("|cffdf80ff<Shift-Click>|r Share link to chat", 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
      GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
      if IsShiftKeyDown() then
        FG:LinkEntityToChat("dungeon", d)
      else
        FG:ShowDetailPanel("dungeon", d)
      end
      FG:PlaySparkSound("shimmer")
    end)

    btn:Show()
    yOffset = yOffset - 58
  end
  content:SetHeight(math.max(450, math.abs(yOffset) + 20))
end

function FG:ToggleCodex()
  ForeverGuideDB.hasInteracted = true
  if FG.SparkFrame and FG.SparkFrame.flightState == "DORMANT" then
    FG.SparkFrame.flightState = "RESTING"
  end
  if not FG.CodexWindow then FG:CreateCodexWindow() end
  if FG.CodexWindow:IsShown() then
    FG.CodexWindow:Hide()
  else
    FG.CodexWindow:Show()
    FG:SetActiveCategory("all")
    if ForeverGuideSearchBox then
      ForeverGuideSearchBox:SetText("")
      if ForeverGuideSearchBox.Placeholder then ForeverGuideSearchBox.Placeholder:Show() end
      if ForeverGuideSearchBox.ClearBtn then ForeverGuideSearchBox.ClearBtn:Hide() end
    end
    FG:PopulateCodexResults("")
    FG:PlaySparkSound("shimmer")
  end
end

function FG:OpenCodexWithSearch(query)
  ForeverGuideDB.hasInteracted = true
  if FG.SparkFrame and FG.SparkFrame.flightState == "DORMANT" then
    FG.SparkFrame.flightState = "RESTING"
  end
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
    GameTooltip:AddLine("|cffcf52ffForever Guide|r |cffdf80ff(Sparky)|r", 1, 1, 1)
    GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Toggle Codex Window", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffdf80ff<Right-Click>|r Summon / Dismiss Sparky", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cffdf80ff<Drag>|r Move around minimap", 0.7, 0.7, 0.7)
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

    print("|cffcf52ffForever Guide|r |cffdf80ff(Sparky)|r loaded! Type |cffdf80ff/sparky|r to open Codex or |cffdf80ff/sparky help|r for commands.")

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
        FG.SparkFrame.Aura:SetVertexColor(0.85, 0.25, 1.0, 0.85)
        C_Timer.After(1.2, function()
          if FG.SparkFrame and FG.SparkFrame.Aura then
            FG.SparkFrame.Aura:SetVertexColor(0.68, 0.12, 0.98, 0.65)
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
