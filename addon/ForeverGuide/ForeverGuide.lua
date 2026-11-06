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

  -- Nearby Area Intel Radar (/spark nearby)
  elseif cmd == "nearby" or cmd == "radar" or cmd == "local" or cmd == "area" then
    if not FG.CodexWindow then FG:CreateCodexWindow() end
    FG.CodexWindow:Show()
    FG:SetActiveCategory("nearby")
    if rest ~= "" and ForeverGuideSearchBox then
      ForeverGuideSearchBox:SetText(rest)
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

local function FormatNumber(n)
  if not n then return "0" end
  local str = tostring(math.floor(tonumber(n) or 0))
  local left, num, right = string.match(str, "^([^%d]*%d)(%d*)(.-)$")
  if not left then return tostring(n) end
  return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
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

  -- =========================================================================
  -- SPARKY AUTONOMOUS AI & HIGH-FPS FLUID MOTION ENGINE
  -- =========================================================================
  local flightState = ForeverGuideDB.hasInteracted and "RESTING" or "DORMANT"
  f.flightState = flightState

  local currentPosX = f.homeX or 240
  local currentPosY = f.homeY or 120
  -- =========================================================================
  -- SPARKY COZY HOME-ANCHORED WANDERING & FLUID MOTION ENGINE
  -- =========================================================================
  local flightState = ForeverGuideDB.hasInteracted and "RESTING" or "DORMANT"
  f.flightState = flightState

  local anchorX = f.homeX or 240
  local anchorY = f.homeY or 120
  local currentPosX = anchorX
  local currentPosY = anchorY
  local lastPosX, lastPosY = currentPosX, currentPosY
  local currentVelX, currentVelY = 0, 0

  -- State & Decision Timers
  local stateTimer = 0
  local stateDuration = 2.4 + math.random() * 2.2 -- Snappy 2.4-4.6s rest before next gentle drift

  -- Float & Roam Parameters
  local travelStartX, travelStartY = currentPosX, currentPosY
  local travelTargetX, travelTargetY = currentPosX, currentPosY
  local travelCtrlX, travelCtrlY = currentPosX, currentPosY
  local travelDuration = 1.6
  local travelElapsed = 0

  -- Cycle counter to venture out a bit occasionally
  local wanderCycle = 0

  -- Death Bounce Physics
  local deathBounceTimer = 0
  local deathBounceSide = "RIGHT"

  -- Lagging Spring-Damper Trails for Puffs
  local puff1LagX, puff1LagY = 0, 0
  local puff2LagX, puff2LagY = 0, 0
  local puff3LagX, puff3LagY = 0, 0

  local function GetScreenBounds()
    local sw = UIParent:GetWidth() or 1920
    local sh = UIParent:GetHeight() or 1080
    return 50, sw - 50, 50, sh - 50
  end

  local function PickNeighborhoodPoint()
    wanderCycle = wanderCycle + 1
    local minX, maxX, minY, maxY = GetScreenBounds()

    local radius
    if wanderCycle % 5 == 0 then
      -- Venturing out a bit! (70 to 110px away from home)
      radius = 70 + math.random() * 40
    else
      -- Hang out in small area around its home (18 to 48px away)
      radius = 16 + math.random() * 32
    end

    local angle = math.random() * math.pi * 2
    local tx = anchorX + math.cos(angle) * radius
    local ty = anchorY + math.sin(angle) * radius

    tx = math.max(minX, math.min(maxX, tx))
    ty = math.max(minY, math.min(maxY, ty))
    return tx, ty
  end

  local function StartGentleFloat(targetX, targetY)
    travelStartX = currentPosX
    travelStartY = currentPosY
    travelTargetX = targetX
    travelTargetY = targetY
    travelElapsed = 0

    local dx = travelTargetX - travelStartX
    local dy = travelTargetY - travelStartY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then dist = 1 end

    -- Gentle, smooth wisp float (35 to 65 px/sec) - floaty and organic!
    travelDuration = math.max(1.3, math.min(2.4, 0.9 + (dist / 45.0)))

    -- Subtle organic curve
    local midX = (travelStartX + travelTargetX) * 0.5
    local midY = (travelStartY + travelTargetY) * 0.5
    local perpX = -dy / dist
    local perpY = dx / dist
    local curveDist = (math.random() > 0.5 and 1 or -1) * (10 + math.random() * 25)
    travelCtrlX = midX + perpX * curveDist
    travelCtrlY = midY + perpY * curveDist
  end

  function f:TransitionTo(newState)
    flightState = newState
    self.flightState = newState
    stateTimer = 0

    if newState == "RESTING" then
      stateDuration = 2.2 + math.random() * 2.4 -- Rest 2.2 to 4.6 seconds
      if visual then visual:SetSize(28, 28) end

    elseif newState == "WANDER" then
      local tx, ty = PickNeighborhoodPoint()
      StartGentleFloat(tx, ty)

    elseif newState == "DEATH_BOUNCE" then
      deathBounceTimer = 0
      local sw = UIParent:GetWidth() or 1920
      deathBounceSide = (currentPosX > sw * 0.5) and "RIGHT" or "LEFT"
      if f.Aura then f.Aura:SetVertexColor(0.95, 0.20, 1.0, 0.90) end
      FG:PlaySparkSound("shimmer")

    elseif newState == "CELEBRATE" then
      stateDuration = 1.6
      StartGentleFloat(anchorX, anchorY + 30)
    end
  end

  local function OnOrbUpdate(self, elapsed)
    local dt = math.min(elapsed, 0.05) -- Clamp delta-time for silky smooth frame rendering
    local t = GetTime()

    if self.isDragging then
      flightState = ForeverGuideDB.hasInteracted and "RESTING" or "DORMANT"
      self.flightState = flightState
      stateTimer = 0
      local cx, cy = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      local curX, curY = cx / scale, cy / scale
      currentPosX = curX - (self.dragOffsetX or 0)
      currentPosY = curY - (self.dragOffsetY or 0)
      anchorX = currentPosX
      anchorY = currentPosY
      self.homeX = anchorX
      self.homeY = anchorY
      self:ClearAllPoints()
      self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", currentPosX, currentPosY)
      lastPosX, lastPosY = currentPosX, currentPosY
      return
    end

    if flightState == "DORMANT" then
      -- Peaceful stationary breathing at spawn point until opened once
      local waveX = math.sin(t * 0.40) * 2.5
      local waveY = math.cos(t * 0.32) * 2.5
      currentPosX = anchorX + waveX
      currentPosY = anchorY + waveY

    elseif flightState == "RESTING" then
      -- Resting gently right near its current spot with soft organic hovering
      stateTimer = stateTimer + dt
      local bobX = math.sin(t * 0.95) * 2.5 + math.sin(t * 0.40) * 1.0
      local bobY = math.cos(t * 0.80) * 2.5 + math.sin(t * 0.25) * 1.0
      currentPosX = travelTargetX + bobX
      currentPosY = travelTargetY + bobY

      -- After resting briefly, take a gentle float around home
      if stateTimer >= stateDuration and ForeverGuideDB.hasInteracted then
        f:TransitionTo("WANDER")
      end

    elseif flightState == "WANDER" then
      travelElapsed = travelElapsed + dt
      local progress = math.min(1.0, travelElapsed / travelDuration)

      -- Smooth cosine ease: gentle acceleration and soft deceleration into hover
      local u = 0.5 - 0.5 * math.cos(progress * math.pi)
      local invU = 1.0 - u

      local bX = invU * invU * travelStartX + 2 * invU * u * travelCtrlX + u * u * travelTargetX
      local bY = invU * invU * travelStartY + 2 * invU * u * travelCtrlY + u * u * travelTargetY

      local ripple = math.sin(progress * math.pi * 2) * 2.0
      currentPosX = bX
      currentPosY = bY + ripple

      if progress >= 1.0 then
        f:TransitionTo("RESTING")
      end

    elseif flightState == "ZIG_ZAG" then
      travelElapsed = travelElapsed + dt
      local progress = math.min(1.0, travelElapsed / travelDuration)
      local u = 0.5 - 0.5 * math.cos(progress * math.pi)
      currentPosX = travelStartX + (travelTargetX - travelStartX) * u + math.sin(progress * math.pi * 2) * 8
      currentPosY = travelStartY + (travelTargetY - travelStartY) * u + math.cos(progress * math.pi * 2) * 5
      if progress >= 1.0 then
        f:TransitionTo("RESTING")
      end

    elseif flightState == "DEATH_BOUNCE" then
      -- Player died! Sparky dashes to the screen side and bounces with elastic cartoon physics
      deathBounceTimer = deathBounceTimer + dt
      local minX, maxX, minY, maxY = GetScreenBounds()
      local targetEdgeX = (deathBounceSide == "RIGHT") and (maxX - 15) or (minX + 15)

      -- Snap smoothly to screen side
      currentPosX = currentPosX + (targetEdgeX - currentPosX) * math.min(1.0, dt * 6.0)

      -- Rubber-ball bounce physics along the side of the screen!
      local bouncePeriod = 0.50 -- Brisk, comedic bounce cadence
      local phase = (deathBounceTimer % bouncePeriod) / bouncePeriod
      local bounceHeight = 165 + math.sin(deathBounceTimer * 2.2) * 30
      local groundY = minY + 50
      local arc = 4 * phase * (1 - phase) -- Parabola 0 -> 1 -> 0
      currentPosY = groundY + arc * bounceHeight

      -- Side-wall impact wobble
      local wallKick = math.sin(phase * math.pi) * 16
      currentPosX = targetEdgeX + ((deathBounceSide == "RIGHT") and -wallKick or wallKick)

      -- Impact squash & stretch
      if phase < 0.12 or phase > 0.88 then
        visual:SetSize(36, 20) -- Squashed on bounce floor!
        if self.Aura then self.Aura:SetVertexColor(1.0, 0.30, 0.95, 0.90) end
      else
        visual:SetSize(22, 32) -- Stretched tall soaring upward!
        if self.Aura then self.Aura:SetVertexColor(0.78, 0.22, 1.0, 0.70) end
      end

      -- If player has revived, celebrate and return home!
      if not UnitIsDeadOrGhost("player") then
        f:TransitionTo("CELEBRATE")
      end

    elseif flightState == "CELEBRATE" then
      stateTimer = stateTimer + dt
      travelElapsed = travelElapsed + dt
      local progress = math.min(1.0, travelElapsed / travelDuration)
      local u = 0.5 - 0.5 * math.cos(progress * math.pi)
      local invU = 1.0 - u
      currentPosX = invU * travelStartX + u * anchorX + math.sin(progress * math.pi * 3) * 20
      currentPosY = invU * travelStartY + u * anchorY + math.cos(progress * math.pi * 3) * 15

      if progress >= 1.0 or stateTimer >= stateDuration then
        f:TransitionTo("RESTING")
      end
    end

    -- Smooth velocity tracking & subtle wisp tilt
    currentVelX = (currentPosX - lastPosX) / (dt > 0.0001 and dt or 0.01)
    currentVelY = (currentPosY - lastPosY) / (dt > 0.0001 and dt or 0.01)
    lastPosX, lastPosY = currentPosX, currentPosY
    local speedMag = math.sqrt(currentVelX * currentVelX + currentVelY * currentVelY)

    if flightState ~= "DEATH_BOUNCE" then
      local stretch = math.min(0.20, (speedMag / 400) * 0.20)
      visual:SetSize(28 * (1.0 + stretch), 28 / (1.0 + stretch * 0.5))
    end

    -- Gentle particle trailing for satellite puffs
    local lagFactor = math.min(1.0, dt * 14.0)
    local targetLagX = -currentVelX * 0.025
    local targetLagY = -currentVelY * 0.025
    puff1LagX = puff1LagX + (targetLagX - puff1LagX) * lagFactor
    puff1LagY = puff1LagY + (targetLagY - puff1LagY) * lagFactor

    if self.Puff1 then
      local p1R = 12 + math.sin(t * 1.0) * 3.0
      local p1X = math.cos(t * 1.8) * p1R + puff1LagX * 0.6
      local p1Y = math.sin(t * 1.8) * (p1R * 0.75) + puff1LagY * 0.6
      self.Puff1:SetPoint("CENTER", visual, "CENTER", p1X, p1Y)
    end
    if self.Puff2 then
      local p2R = 9 + math.cos(t * 1.2) * 2.5
      local p2X = math.cos(-t * 1.5 + 2.1) * p2R + puff1LagX * 0.8
      local p2Y = math.sin(-t * 1.5 + 2.1) * (p2R * 0.8) + puff1LagY * 0.8
      self.Puff2:SetPoint("CENTER", visual, "CENTER", p2X, p2Y)
    end
    if self.Puff3 then
      local p3R = 7 + math.sin(t * 1.4 + 1.2) * 2.0
      local p3X = math.sin(t * 1.3 + 4.0) * p3R + puff1LagX * 1.0
      local p3Y = math.cos(t * 1.3 + 4.0) * (p3R * 0.65) + puff1LagY * 1.0
      self.Puff3:SetPoint("CENTER", visual, "CENTER", p3X, p3Y)
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
        anchorX = self.homeX
        anchorY = self.homeY
        ForeverGuideDB.hasInteracted = true
        if self.TransitionTo then
          self:TransitionTo("RESTING")
        else
          flightState = "RESTING"
          self.flightState = flightState
        end
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
-- Virtual Scrolling & Codex Row Pool System
--------------------------------------------------------------------------------
function FG:FormatNumber(n)
  if not n then return "0" end
  local str = tostring(n)
  return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function FG:GetPlayerZoneInfo()
  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  local sub = (GetSubZoneText and GetSubZoneText()) or (GetMinimapZoneText and GetMinimapZoneText()) or ""
  if (zone == "" or zone == "Azeroth") and sub ~= "" and FG.Data and FG.Data.Subzones then
    local parent = FG.Data.Subzones[sub:lower()]
    if parent then zone = parent end
  end
  if zone == "" then
    zone = FG.lastKnownZone or "Elwynn Forest"
  else
    FG.lastKnownZone = zone
  end
  return zone, sub
end

function FG:CreateCodexRowButton(parent, i)
  local btn = CreateFrame("Button", "ForeverGuideRowButton" .. i, parent, "BackdropTemplate")
  btn:SetSize(548, 50)
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

  local iconFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
  iconFrame:SetSize(34, 34)
  iconFrame:SetPoint("LEFT", btn, "LEFT", 8, 0)
  MakePixelSharp(iconFrame)
  iconFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 10,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  iconFrame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)

  local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
  iconTex:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
  iconTex:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
  iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  btn.IconFrame = iconFrame
  btn.Icon = iconTex

  local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
  SharpenFontString(titleText, 13, "OUTLINE")
  btn.Title = titleText

  local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
  subText:SetWidth(400)
  subText:SetJustifyH("LEFT")
  SharpenFontString(subText, 11, "OUTLINE")
  btn.Sub = subText

  local hint = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
  hint:SetText("|cffdf80ffInspect >|r")
  SharpenFontString(hint, 10, "OUTLINE")
  btn.Hint = hint

  return btn
end

function FG:ConfigureRowButton(btn, match)
  if not match then return end
  btn.match = match

  if match.type == "folder" then
    local folder = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.08, 0.11, 0.16, 0.95)
    btn:SetBackdropBorderColor(0.24, 0.38, 0.58, 0.85)

    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture("Interface\\Icons\\inv_misc_bag_08")
      btn.IconFrame:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -3)
    btn.Sub:SetWidth(400)

    btn.Title:SetText("|cff66ccff" .. folder.name .. "|r")
    btn.Sub:SetText("|cff8899aa" .. (folder.desc or folder.count or "Folder") .. "|r")
    btn.Hint:SetText("|cff33bbffOpen >|r")

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.14, 0.20, 0.30, 0.98)
      self:SetBackdropBorderColor(0.40, 0.70, 1.0, 0.95)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(folder.name, 0.4, 0.8, 1.0)
      GameTooltip:AddLine(folder.desc or "Click to open folder", 0.8, 0.8, 0.8, true)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.08, 0.11, 0.16, 0.95)
      self:SetBackdropBorderColor(0.24, 0.38, 0.58, 0.85)
      GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
      FG:NavigateToFolder(folder.path)
      FG:PlaySparkSound("shimmer")
    end)

  elseif match.type == "item" then
    local item = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffdf80ffInspect >|r")

    if btn.IconFrame then
      btn.IconFrame:Show()
      local tex = (item.icon and item.icon ~= "") and ("Interface\\Icons\\" .. item.icon) or "Interface\\Icons\\inv_misc_questionmark"
      btn.Icon:SetTexture(tex)
      local q = item.quality or "Common"
      if q == "Legendary" then btn.IconFrame:SetBackdropBorderColor(1.0, 0.5, 0.0, 1.0)
      elseif q == "Epic" then btn.IconFrame:SetBackdropBorderColor(0.64, 0.21, 0.93, 1.0)
      elseif q == "Rare" then btn.IconFrame:SetBackdropBorderColor(0.0, 0.44, 0.87, 1.0)
      elseif q == "Uncommon" then btn.IconFrame:SetBackdropBorderColor(0.12, 1.0, 0.0, 1.0)
      else btn.IconFrame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8) end
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -3)
    btn.Sub:SetWidth(400)

    local qColor = FG.QualityColors[item.quality] or "ffffffff"
    local foreverTag = item.isForever and " |cffe6cc80[Forever]|r" or ""
    local nearbyPrefix = match.isNearby and "|cff20ff20[Loot]|r " or ""
    btn.Title:SetText(nearbyPrefix .. "|c" .. qColor .. item.name .. "|r" .. foreverTag .. " |cff8899aa(iLvl " .. item.ilvl .. ")|r")

    local desc = (item.slot and item.slot ~= "" and (item.slot .. " - ") or "") .. (item.source or "World Drop")
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
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffdf80ffInspect >|r")

    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture("Interface\\Icons\\inv_misc_book_07")
      btn.IconFrame:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.9)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -3)
    btn.Sub:SetWidth(400)

    local foreverTag = qData.isForever and " |cffe6cc80[Forever]|r" or ""
    local nearbyPrefix = match.isNearby and "|cff20ff20[Quest]|r " or ""
    btn.Title:SetText(nearbyPrefix .. "|cffffd24d" .. qData.title .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. qData.questLevel .. ")|r")
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

  elseif match.type == "creature" then
    local c = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffdf80ffInspect >|r")

    if btn.IconFrame then
      btn.IconFrame:Show()
      local cTex = (c.classification == "Boss" or c.classification == "World Boss") and "Interface\\Icons\\inv_misc_head_dragon_01" or ((c.classification == "Elite" or c.classification == "Rare Elite") and "Interface\\Icons\\spell_shadow_summoninfernal" or "Interface\\Icons\\inv_misc_monsterhead_01")
      btn.Icon:SetTexture(cTex)
      if c.classification == "Boss" or c.classification == "World Boss" then
        btn.IconFrame:SetBackdropBorderColor(1.0, 0.2, 0.2, 1.0)
      elseif c.classification == "Elite" or c.classification == "Rare Elite" then
        btn.IconFrame:SetBackdropBorderColor(1.0, 0.8, 0.2, 1.0)
      else
        btn.IconFrame:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
      end
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -3)
    btn.Sub:SetWidth(400)

    local foreverTag = c.isForever and " |cffe6cc80[Forever]|r" or ""
    local classColor = (c.classification == "Boss" or c.classification == "Rare Elite" or c.classification == "World Boss") and "ffff4040" or (c.classification == "Elite" and "ffffd24d" or "ff52b8ff")
    local lvlStr = (c.minLevel and c.maxLevel and c.minLevel ~= c.maxLevel) and (c.minLevel .. "-" .. c.maxLevel) or (c.maxLevel or c.minLevel or "?")
    local tagPrefix = ""
    if match.isNearby then
      if c.classification == "Boss" or c.classification == "World Boss" then
        tagPrefix = "|cffff4040[Nearby Boss]|r "
      elseif c.classification == "Rare" or c.classification == "Rare Elite" then
        tagPrefix = "|cff33bbff[Nearby Rare]|r "
      else
        tagPrefix = "|cff20ff20[Nearby NPC]|r "
      end
    end
    btn.Title:SetText(tagPrefix .. "|c" .. classColor .. c.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. lvlStr .. " " .. (c.classification or "NPC") .. ")|r")
    local desc = "|cff52b8ffZone:|r " .. (c.zone ~= "" and c.zone or "Various")
    if c.location and c.location ~= "" then
      desc = desc .. " |cff52b8ffLocation:|r " .. c.location
    end
    if c.coords and c.coords ~= "" then
      desc = desc .. " (" .. c.coords .. ")"
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
      if c.coords and c.coords ~= "" then GameTooltip:AddLine("Coords: " .. c.coords, 0.2, 1, 0.2) end
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

  elseif match.type == "dungeon" then
    local d = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffdf80ffInspect >|r")

    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture("Interface\\Icons\\inv_helmet_08")
      btn.IconFrame:SetBackdropBorderColor(0.7, 0.4, 0.9, 0.9)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -3)
    btn.Sub:SetWidth(400)

    local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
    local nearbyPrefix = match.isNearby and "|cffaf50ff[Nearby Dungeon]|r " or ""
    btn.Title:SetText(nearbyPrefix .. "|cffffd24d" .. d.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. d.recLevel .. ")|r")
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

  elseif match.type == "vendor" then
    local v = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffdf80ffInspect >|r")

    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture("Interface\\Icons\\inv_misc_bag_07")
      btn.IconFrame:SetBackdropBorderColor(0.4, 0.8, 0.5, 0.9)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -7)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -3)
    btn.Sub:SetWidth(400)

    local nearbyPrefix = match.isNearby and "|cff20ff20[Vendor]|r " or ""
    btn.Title:SetText(nearbyPrefix .. "|cffffd24d" .. v.name .. "|r |cff20ff20[Vendor]|r")
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
end

function FG:UpdateVirtualRows()
  if not FG.CodexWindow or not FG.CodexWindow.Content then return end
  local content = FG.CodexWindow.Content
  local scrollFrame = ForeverGuideScrollFrame
  if not scrollFrame or not content.RowPool then return end
  local matches = FG.currentMatches or {}
  local numMatches = #matches
  if numMatches == 0 then
    for _, btn in ipairs(content.RowPool) do btn:Hide() end
    return
  end

  local ROW_HEIGHT = 54
  local scrollOffset = scrollFrame:GetVerticalScroll() or 0
  local startIndex = math.floor(scrollOffset / ROW_HEIGHT) + 1
  if startIndex < 1 then startIndex = 1 end

  for i = 1, #content.RowPool do
    local btn = content.RowPool[i]
    local matchIndex = startIndex + (i - 1)
    if matchIndex <= numMatches then
      local match = matches[matchIndex]
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((matchIndex - 1) * ROW_HEIGHT))
      FG:ConfigureRowButton(btn, match)
      btn:Show()
    else
      btn:Hide()
    end
  end
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
  searchBox:SetSize(190, 24)
  searchBox:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 6, -10)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject("ChatFontNormal")
  SharpenFontString(searchBox, 12, "OUTLINE")
  MakePixelSharp(searchBox)

  local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
  placeholder:SetPoint("RIGHT", searchBox, "RIGHT", -22, 0)
  placeholder:SetJustifyH("LEFT")
  placeholder:SetWordWrap(false)
  placeholder:SetText("Search codex...")
  SharpenFontString(placeholder, 11, "OUTLINE")
  searchBox.Placeholder = placeholder

  local clearBtn = CreateFrame("Button", nil, searchBox)
  clearBtn:SetSize(16, 16)
  clearBtn:SetPoint("RIGHT", searchBox, "RIGHT", -4, 0)
  local clearTxt = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  clearTxt:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
  clearTxt:SetText("|cffaaaaaaX|r")
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

  local allBtn    = CreateCategoryPill("all", "All", 36, 8, searchBox)
  local nearbyBtn = CreateCategoryPill("nearby", "Nearby", 52, 4, allBtn)
  local itemsBtn  = CreateCategoryPill("items", "Items", 42, 4, nearbyBtn)
  local questBtn  = CreateCategoryPill("quests", "Quests", 50, 4, itemsBtn)
  local npcBtn    = CreateCategoryPill("creatures", "NPCs", 42, 4, questBtn)
  local dungBtn   = CreateCategoryPill("dungeons", "Dungeons", 62, 4, npcBtn)
  local vendBtn   = CreateCategoryPill("vendors", "Vendors", 54, 4, dungBtn)

  -- Bottom status bar / footer
  local botDivider = f:CreateTexture(nil, "ARTWORK")
  botDivider:SetColorTexture(0.55, 0.22, 0.85, 0.25)
  botDivider:SetHeight(1)
  botDivider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 28)
  botDivider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 28)
  MakePixelSharp(botDivider)

  local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 9)
  statusText:SetText("|cff888899Ready - Type to search, browse folders, or view Nearby intel|r")
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

  -- Dolphin Folder Navigation Bar (Breadcrumb Trail + Up Button)
  local dolphinBar = CreateFrame("Frame", "ForeverGuideDolphinBar", f, "BackdropTemplate")
  dolphinBar:SetSize(588, 24)
  dolphinBar:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -2, -6)
  MakePixelSharp(dolphinBar)
  dolphinBar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  dolphinBar:SetBackdropColor(0.06, 0.08, 0.12, 0.90)
  dolphinBar:SetBackdropBorderColor(0.25, 0.30, 0.45, 0.75)
  f.DolphinBar = dolphinBar

  local upBtn = CreateFrame("Button", nil, dolphinBar, "UIPanelButtonTemplate")
  upBtn:SetSize(54, 20)
  upBtn:SetPoint("LEFT", dolphinBar, "LEFT", 4, 0)
  upBtn:SetText("< Up")
  MakePixelSharp(upBtn)
  local upFs = upBtn:GetFontString()
  if upFs then SharpenFontString(upFs, 10, "OUTLINE") end
  upBtn:SetScript("OnClick", function()
    FG:NavigateUpFolder()
  end)
  dolphinBar.UpBtn = upBtn

  local breadcrumbText = dolphinBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  breadcrumbText:SetPoint("LEFT", upBtn, "RIGHT", 8, 0)
  breadcrumbText:SetPoint("RIGHT", dolphinBar, "RIGHT", -8, 0)
  breadcrumbText:SetJustifyH("LEFT")
  SharpenFontString(breadcrumbText, 11, "OUTLINE")
  breadcrumbText:SetText("|cffcf52ffHome|r")
  dolphinBar.Breadcrumbs = breadcrumbText

  local scrollFrame = CreateFrame("ScrollFrame", "ForeverGuideScrollFrame", f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", dolphinBar, "BOTTOMLEFT", -2, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 34)
  MakePixelSharp(scrollFrame)

  local content = CreateFrame("Frame", "ForeverGuideScrollContent", scrollFrame)
  content:SetSize(554, 1000)
  scrollFrame:SetScrollChild(content)
  MakePixelSharp(content)
  f.Content = content

  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll() or 0
    local newScroll = current - (delta * 54 * 2)
    local maxScroll = math.max(0, (content:GetHeight() or 0) - self:GetHeight())
    if newScroll < 0 then newScroll = 0 end
    if newScroll > maxScroll then newScroll = maxScroll end
    self:SetVerticalScroll(newScroll)
    FG:UpdateVirtualRows()
  end)
  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FG:UpdateVirtualRows()
  end)

  content.RowPool = {}
  for i = 1, 12 do
    content.RowPool[i] = FG:CreateCodexRowButton(content, i)
    content.RowPool[i]:Hide()
  end
  content.Buttons = content.RowPool

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
  bSub:SetText("Instant in-game search for 40,000+ items, quests, NPCs & loot drops.")
  SharpenFontString(bSub, 11, "OUTLINE")
  blank.Sub = bSub

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

  CreateQuickPill("Dungeons", -180, function() FG:SetActiveCategory("dungeons") end)
  CreateQuickPill("Forever Gear", -60, function()
    searchBox:SetText("forever")
    FG:SetActiveCategory("all")
  end)
  CreateQuickPill("Quests", 60, function() FG:SetActiveCategory("quests") end)
  CreateQuickPill("Nearby Intel", 180, function() FG:SetActiveCategory("nearby") end)

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

  local folderMap = {
    ["all"] = "root",
    ["nearby"] = "nearby",
    ["items"] = "items",
    ["quests"] = "quests",
    ["creatures"] = "creatures",
    ["dungeons"] = "dungeons",
    ["vendors"] = "vendors",
  }
  local q = ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or ""
  if q == "" then
    FG.currentFolder = folderMap[FG.activeCategory] or "root"
  end
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

  local headerIconFrame = CreateFrame("Frame", nil, p, "BackdropTemplate")
  headerIconFrame:SetSize(24, 24)
  headerIconFrame:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -10)
  MakePixelSharp(headerIconFrame)
  headerIconFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 10,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  headerIconFrame:SetBackdropBorderColor(0.65, 0.35, 1.0, 0.9)
  local headerIconTex = headerIconFrame:CreateTexture(nil, "ARTWORK")
  headerIconTex:SetPoint("TOPLEFT", headerIconFrame, "TOPLEFT", 2, -2)
  headerIconTex:SetPoint("BOTTOMRIGHT", headerIconFrame, "BOTTOMRIGHT", -2, 2)
  headerIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  p.HeaderIconFrame = headerIconFrame
  p.HeaderIcon = headerIconTex

  local title = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("LEFT", headerIconFrame, "RIGHT", 8, 0)
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

  if p.Body.LootButtons then
    for _, btn in ipairs(p.Body.LootButtons) do btn:Hide() end
  end
  p.Body.LootButtons = p.Body.LootButtons or {}

  local lineIndex = 0
  local lootBtnIndex = 0
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

  local function AddLootButton(drop)
    lootBtnIndex = lootBtnIndex + 1
    local btn = p.Body.LootButtons[lootBtnIndex]
    if not btn then
      btn = CreateFrame("Button", nil, p.Body, "BackdropTemplate")
      btn:SetSize(286, 26)
      MakePixelSharp(btn)
      btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 12,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })
      btn:SetBackdropColor(0.10, 0.12, 0.17, 0.90)
      btn:SetBackdropBorderColor(0.25, 0.28, 0.38, 0.80)

      local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      titleText:SetPoint("LEFT", btn, "LEFT", 8, 0)
      titleText:SetWidth(196)
      titleText:SetJustifyH("LEFT")
      SharpenFontString(titleText, 11, "OUTLINE")
      btn.Title = titleText

      local rateText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      rateText:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
      rateText:SetJustifyH("RIGHT")
      SharpenFontString(rateText, 11, "OUTLINE")
      btn.Rate = rateText

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.16, 0.32, 0.95)
        self:SetBackdropBorderColor(0.65, 0.35, 1.0, 0.95)
        if self.itemData then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          if self.itemData.id and GameTooltip.SetItemByID then
            pcall(GameTooltip.SetItemByID, GameTooltip, self.itemData.id)
          else
            GameTooltip:SetText(self.itemData.name)
          end
          if self.itemData.pct then
            GameTooltip:AddLine("Drop Chance: |cff71d5ff" .. self.itemData.pct .. "|r")
          end
          GameTooltip:AddLine("|cffdf80ffClick to inspect in Codex|r", 0.8, 0.8, 0.8)
          GameTooltip:Show()
        end
      end)

      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.17, 0.90)
        self:SetBackdropBorderColor(0.25, 0.28, 0.38, 0.80)
        GameTooltip:Hide()
      end)

      btn:SetScript("OnClick", function(self)
        if self.itemData then
          local fullItem = self.itemData.id and FG.Data.Items and FG.Data.Items[self.itemData.id]
          if fullItem then
            FG:ShowDetailPanel("item", fullItem)
          elseif ForeverGuideSearchBox then
            ForeverGuideSearchBox:SetText(self.itemData.name)
          end
        end
      end)

      p.Body.LootButtons[lootBtnIndex] = btn
    end

    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", p.Body, "TOPLEFT", 6, yOffset)
    btn.itemData = drop
    local qColor = FG.QualityColors[drop.quality] or "ffffffff"
    btn.Title:SetText("|c" .. qColor .. (drop.name or "Item") .. "|r")
    btn.Rate:SetText("|cff71d5ff" .. (drop.pct or "") .. "|r")
    btn:Show()

    yOffset = yOffset - 28
  end

  if entityType == "quest" then
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture("Interface\\Icons\\inv_misc_book_07")
      p.HeaderIconFrame:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.9)
    end
    p.Title:SetText("|cffcf52ffQuest Intel|r")
    AddLine("|cffffd24d" .. (data.title or "Quest") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Level: |cff20ff20" .. (data.questLevel or "?") .. "|r  (Requires Lvl " .. (data.reqLevel or "1") .. ")", 12)
    if data.faction and data.faction ~= "" then
      AddLine("Faction: |cff52b8ff" .. data.faction .. "|r", 11)
    end
    if data.isForever then
      AddLine("|cffe6cc80[Forever] Warcraft Forever Custom Content|r", 11, nil, nil, nil, 4)
    end

    AddSection("LOCATION & QUESTGIVER")
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    AddLine("Questgiver: |cff52b8ff" .. (data.npc or "Unknown") .. "|r", 12)

    if data.details and data.details ~= "" then
      AddSection("QUEST STORY & LORE")
      AddLine(data.details, 11, 0.95, 0.95, 0.95, 6)
    end

    AddSection("OBJECTIVES")
    AddLine(data.objectives and data.objectives ~= "" and data.objectives or "No specific task listed.", 12, 0.9, 0.9, 0.9, 6)

    AddSection("REWARDS")
    AddLine(data.rewards and data.rewards ~= "" and data.rewards or "Experience & Gold", 12, 1, 0.85, 0.2, 6)

    if data.completion and data.completion ~= "" and data.completion ~= data.details then
      AddSection("COMPLETION DIALOG")
      AddLine(data.completion, 11, 0.85, 0.95, 0.85, 6)
    end

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
    if p.HeaderIcon then
      local iconTex = (data.icon and data.icon ~= "") and ("Interface\\Icons\\" .. data.icon) or "Interface\\Icons\\inv_misc_questionmark"
      p.HeaderIcon:SetTexture(iconTex)
      local q = data.quality or "Common"
      if q == "Legendary" then p.HeaderIconFrame:SetBackdropBorderColor(1.0, 0.5, 0.0, 1.0)
      elseif q == "Epic" then p.HeaderIconFrame:SetBackdropBorderColor(0.64, 0.21, 0.93, 1.0)
      elseif q == "Rare" then p.HeaderIconFrame:SetBackdropBorderColor(0.0, 0.44, 0.87, 1.0)
      elseif q == "Uncommon" then p.HeaderIconFrame:SetBackdropBorderColor(0.12, 1.0, 0.0, 1.0)
      else p.HeaderIconFrame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8) end
    end
    p.Title:SetText("|cffcf52ffItem Intel|r")
    local qColor = FG.QualityColors[data.quality] or "ffffffff"
    AddLine("|c" .. qColor .. (data.name or "Item") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Item Level: |cffffffff" .. (data.ilvl or "?") .. "|r" .. ((data.reqLvl and data.reqLvl > 0) and ("  (Req Lvl " .. data.reqLvl .. ")") or (data.reqLevel and data.reqLevel > 0 and ("  (Req Lvl " .. data.reqLevel .. ")") or "")), 12)

    local subType = (data.slot and data.slot ~= "" and data.slot or "")
    if data.itemType and data.itemType ~= "" and data.itemType ~= data.slot then
      subType = (subType ~= "" and (subType .. " • ") or "") .. data.itemType
    end
    if data.bonding and data.bonding ~= "" then
      subType = (subType ~= "" and (subType .. "  |cff8899aa(" .. data.bonding .. ")|r") or ("|cff8899aa" .. data.bonding .. "|r"))
    end
    if subType ~= "" then AddLine(subType, 11, 0.40, 0.80, 1.0, 4) end

    if data.isForever then AddLine("|cffe6cc80[Forever] Forever Exclusive Item|r", 11, nil, nil, nil, 4) end

    if data.itemSet and data.itemSet ~= "" then
      AddSection("ITEM SET")
      AddLine("|cffffd24dSet: " .. data.itemSet .. "|r", 12, 1.0, 0.85, 0.2, 4)
    end

    if data.stats and data.stats ~= "" then
      AddSection("STATS & ATTRIBUTES")
      AddLine(data.stats, 12, 0.20, 1.0, 0.30, 6)
    end

    if data.effects and data.effects ~= "" then
      AddSection("SPECIAL EFFECTS & ABILITIES")
      AddLine(data.effects, 12, 0.12, 1.0, 0.12, 6)
    end

    if data.desc and data.desc ~= "" then
      AddSection("DESCRIPTION & LORE")
      AddLine("|cffffd24d\"" .. data.desc .. "\"|r", 11, 1.0, 0.85, 0.40, 6)
    end

    AddSection("SOURCE & DROPS")
    AddLine(data.source and data.source ~= "" and data.source or "World Drop / Various", 12, 0.85, 0.90, 0.95, 6)

    if data.sellPrice and data.sellPrice ~= "" then
      AddLine("Vendor Price: |cffffffff" .. data.sellPrice .. "|r", 11, 0.9, 0.9, 0.9, 4)
    end

    if data.tip and data.tip ~= "" then
      AddSection("SPARK INTEL & NOTES")
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
    if p.HeaderIcon then
      local cTex = (data.classification == "Boss" or data.classification == "World Boss") and "Interface\\Icons\\inv_misc_head_dragon_01" or ((data.classification == "Elite" or data.classification == "Rare Elite") and "Interface\\Icons\\spell_shadow_summoninfernal" or "Interface\\Icons\\inv_misc_monsterhead_01")
      p.HeaderIcon:SetTexture(cTex)
      p.HeaderIconFrame:SetBackdropBorderColor(1.0, 0.2, 0.2, 1.0)
    end
    p.Title:SetText("|cffcf52ffCreature Intel|r")
    local classColor = (data.classification == "Boss" or data.classification == "Rare Elite") and "ffff4040" or (data.classification == "Elite" and "ffffd24d" or "ff52b8ff")
    local lvlStr = (data.minLevel and data.maxLevel and data.minLevel ~= data.maxLevel) and (data.minLevel .. "-" .. data.maxLevel) or (data.maxLevel or data.minLevel or "?")
    AddLine("|c" .. classColor .. (data.name or "Creature") .. "|r", 15, nil, nil, nil, 6)
    
    local typeStr = (data.classification or "Normal")
    if data.family and data.family ~= "" and data.family ~= "Unknown" then
      typeStr = typeStr .. " • |cff00e5ff" .. data.family .. "|r"
    end
    AddLine("Level: |cff20ff20" .. lvlStr .. "|r (" .. typeStr .. ")", 12)
    if data.health and data.health > 0 then AddLine("Health: |cffff6060" .. FormatNumber(data.health) .. " HP|r", 11) end

    AddSection("SPAWN & LOCATION")
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    if data.location and data.location ~= "" then
      AddLine("Area / Wing: |cff20ff20" .. data.location .. "|r", 12)
    end
    if data.coords and data.coords ~= "" then
      AddLine("Pinpoint Coordinates: |cff20ff20(" .. data.coords .. ")|r", 12, 0.3, 1.0, 0.3, 4)
    end

    if data.strategy and data.strategy ~= "" then
      AddSection("COMBAT STRATEGY & TACTICS")
      AddLine(data.strategy, 11, 0.85, 0.90, 0.95, 6)
    end

    AddSection("NOTABLE LOOT & DROPS")
    if data.loot and #data.loot > 0 then
      for _, drop in ipairs(data.loot) do
        AddLootButton(drop)
      end
    else
      AddLine("|cff888899No unique rare or high-value drops recorded.|r", 11)
    end

    p.LinkBtn:SetText("Share to Chat")
    p.LinkBtn:SetScript("OnClick", function()
      FG:LinkEntityToChat("creature", data)
    end)

    p.ActBtn:SetText("Target Macro")
    p.ActBtn:SetScript("OnClick", function()
      local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() or (ChatFrame1EditBox)
      local macroText = "/target " .. data.name
      if editBox then
        ChatEdit_ActivateChat(editBox)
        editBox:SetText(macroText)
      end
      local coordText = (data.coords and data.coords ~= "") and (" at (" .. data.coords .. ") in " .. (data.zone or "current zone")) or ""
      print("|cffcf52ff[Target]|r Prepared: " .. macroText .. coordText)
    end)

  elseif entityType == "dungeon" then
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture("Interface\\Icons\\inv_helmet_08")
      p.HeaderIconFrame:SetBackdropBorderColor(0.7, 0.4, 0.9, 0.9)
    end
    p.Title:SetText("|cffcf52ffDungeon Intel|r")
    AddLine("|cffffd24d" .. (data.name or "Dungeon") .. "|r", 15, nil, nil, nil, 6)
    AddLine("Recommended Level: |cff20ff20" .. (data.recLevel or "?") .. "|r", 12)
    AddLine("Zone: |cffffffff" .. (data.zone or "Various") .. "|r", 12)
    if data.coords and data.coords ~= "" then
      AddLine("Entrance: |cff20ff20" .. data.coords .. "|r", 12)
    end

    if data.bosses and data.bosses ~= "" then
      AddSection("NOTABLE BOSSES")
      AddLine(data.bosses, 11, 1.0, 0.85, 0.40, 6)
    end

    if data.notableLoot and data.notableLoot ~= "" then
      AddSection("NOTABLE LOOT")
      AddLine(data.notableLoot, 11, 0.20, 0.85, 1.0, 6)
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
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture("Interface\\Icons\\inv_misc_bag_07")
      p.HeaderIconFrame:SetBackdropBorderColor(0.4, 0.8, 0.5, 0.9)
    end
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

local KALIMDOR_ZONES = {
  ["Ashenvale"] = true, ["Azshara"] = true, ["Darkshore"] = true, ["Desolace"] = true,
  ["Durotar"] = true, ["Dustwallow Marsh"] = true, ["Felwood"] = true, ["Feralas"] = true,
  ["Moonglade"] = true, ["Mulgore"] = true, ["Orgrimmar"] = true, ["Silithus"] = true,
  ["Stonetalon Mountains"] = true, ["Tanaris"] = true, ["Teldrassil"] = true,
  ["The Barrens"] = true, ["Thousand Needles"] = true, ["Thunder Bluff"] = true,
  ["Un'Goro Crater"] = true, ["Winterspring"] = true,
}

local EK_ZONE_NAMES = {
  "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes",
  "Deadwind Pass", "Dun Morogh", "Duskwood", "Eastern Plaguelands", "Elwynn Forest",
  "Hillsbrad Foothills", "Loch Modan", "Redridge Mountains", "Searing Gorge", "Silverpine Forest",
  "Stormwind City", "Stranglethorn Vale", "Swamp of Sorrows", "The Hinterlands", "Tirisfal Glades",
  "Undercity", "Western Plaguelands", "Westfall", "Wetlands"
}

local KALIMDOR_ZONE_NAMES = {
  "Ashenvale", "Azshara", "Darkshore", "Desolace", "Durotar",
  "Dustwallow Marsh", "Felwood", "Feralas", "Moonglade", "Mulgore",
  "Orgrimmar", "Silithus", "Stonetalon Mountains", "Tanaris", "Teldrassil",
  "The Barrens", "Thousand Needles", "Thunder Bluff", "Un'Goro Crater", "Winterspring"
}

local ARMOR_SLOT_DEFS = {
  { slot = "Head", name = "Head", desc = "Helms, caps, hoods & visors", icon = "Interface\\Icons\\INV_Helmet_08" },
  { slot = "Shoulder", name = "Shoulders", desc = "Pauldrons, mantles & spaulders", icon = "Interface\\Icons\\INV_Shoulder_02" },
  { slot = "Chest", name = "Chest", desc = "Breastplates, robes, tunics & vests", icon = "Interface\\Icons\\INV_Chest_Plate08" },
  { slot = "Wrist", name = "Wrist (Bracers)", desc = "Bracers, wristguards & vambraces", icon = "Interface\\Icons\\INV_Bracer_07" },
  { slot = "Hands", name = "Hands (Gauntlets)", desc = "Gauntlets, gloves & mitts", icon = "Interface\\Icons\\INV_Gauntlets_10" },
  { slot = "Waist", name = "Waist (Belts)", desc = "Belts, girdles & sashes", icon = "Interface\\Icons\\INV_Belt_03" },
  { slot = "Legs", name = "Legs", desc = "Legplates, pants & leggings", icon = "Interface\\Icons\\INV_Pants_06" },
  { slot = "Feet", name = "Feet (Boots)", desc = "Boots, sabatons & footwear", icon = "Interface\\Icons\\INV_Boots_Plate_01" },
}

FG.currentFolder = "root"

FG.FolderTree = {
  ["root"] = {
    title = "Home",
    folders = {
      { path = "nearby", name = "Nearby Area Intel (Zone Radar)", desc = "Live radar: local mobs, quests, vendors & loot in current zone" },
      { path = "quests", name = "Quests", desc = "By Continent, Zone, Class, & Dungeon (A to Z)" },
      { path = "items", name = "Items & Equipment", desc = "Weapons, Armor, Reagents, Recipes & Custom Gear" },
      { path = "creatures", name = "Creatures & Bosses", desc = "Dungeon/Raid Bosses, Rares & NPC Families" },
      { path = "dungeons", name = "Dungeons & Raids", desc = "Starter, Mid, Endgame, Raids & Forever Instances" },
      { path = "vendors", name = "Vendors & Flight Paths", desc = "Flight Masters, PvP Quartermasters & Reagents" },
      { path = "forever", name = "[Forever] Warcraft Forever Custom Content", desc = "Exclusive items, quests, NPCs & dungeons" },
    },
  },

  -- NEARBY LIVE RADAR KDE DOLPHIN HIERARCHY
  ["nearby"] = {
    title = "Nearby Area Intel (Zone Radar)",
    parent = "root",
    folders = {
      { path = "nearby/quests", name = "Quests", desc = "Active quests and storyline objectives in this zone" },
      { path = "nearby/rares", name = "Rares & Bosses", desc = "Silver-dragon rare spawns and world encounters" },
      { path = "nearby/creatures", name = "Creatures & Mobs", desc = "Local beasts, humanoids, and monsters in immediate area" },
      { path = "nearby/vendors", name = "Vendors & Flight Masters", desc = "Flight paths, repairs, reagents, and local trade" },
      { path = "nearby/dungeons", name = "Dungeons & Raids", desc = "Instance entrances, meeting stones, and portals" },
      { path = "nearby/loot", name = "Notable Loot & Drops", desc = "Valuable BoE items, world recipes, and prized drops" },
    },
  },

  -- QUESTS HIERARCHY
  ["quests"] = {
    title = "Quests",
    parent = "root",
    folders = {
      { path = "quests/eastern_kingdoms", name = "Eastern Kingdoms", desc = "24 zones alphabetically (A to Z)" },
      { path = "quests/kalimdor", name = "Kalimdor", desc = "20 zones alphabetically (A to Z)" },
      { path = "quests/dungeons", name = "Dungeons & Raids", desc = "Instance questlines across Azeroth" },
      { path = "quests/class", name = "Class Quests", desc = "Quests for each of the 9 classes" },
      { path = "quests/professions", name = "Profession Quests", desc = "Trade skill quests & masteries" },
      { path = "quests/forever", name = "[Forever] Forever Quests", desc = "Exclusive server questlines" },
    },
  },

  ["quests/eastern_kingdoms"] = {
    title = "Eastern Kingdoms Quests",
    parent = "quests",
    folders = {
      { path = "quests/zone/Alterac Mountains", name = "Alterac Mountains", desc = "Zone quests" },
      { path = "quests/zone/Arathi Highlands", name = "Arathi Highlands", desc = "Zone quests" },
      { path = "quests/zone/Badlands", name = "Badlands", desc = "Zone quests" },
      { path = "quests/zone/Blasted Lands", name = "Blasted Lands", desc = "Zone quests" },
      { path = "quests/zone/Burning Steppes", name = "Burning Steppes", desc = "Zone quests" },
      { path = "quests/zone/Deadwind Pass", name = "Deadwind Pass", desc = "Zone quests" },
      { path = "quests/zone/Dun Morogh", name = "Dun Morogh", desc = "Zone quests" },
      { path = "quests/zone/Duskwood", name = "Duskwood", desc = "Zone quests" },
      { path = "quests/zone/Eastern Plaguelands", name = "Eastern Plaguelands", desc = "Zone quests" },
      { path = "quests/zone/Elwynn Forest", name = "Elwynn Forest", desc = "Zone quests" },
      { path = "quests/zone/Hillsbrad Foothills", name = "Hillsbrad Foothills", desc = "Zone quests" },
      { path = "quests/zone/Loch Modan", name = "Loch Modan", desc = "Zone quests" },
      { path = "quests/zone/Redridge Mountains", name = "Redridge Mountains", desc = "Zone quests" },
      { path = "quests/zone/Searing Gorge", name = "Searing Gorge", desc = "Zone quests" },
      { path = "quests/zone/Silverpine Forest", name = "Silverpine Forest", desc = "Zone quests" },
      { path = "quests/zone/Stormwind City", name = "Stormwind City", desc = "Zone quests" },
      { path = "quests/zone/Stranglethorn Vale", name = "Stranglethorn Vale", desc = "Zone quests" },
      { path = "quests/zone/Swamp of Sorrows", name = "Swamp of Sorrows", desc = "Zone quests" },
      { path = "quests/zone/The Hinterlands", name = "The Hinterlands", desc = "Zone quests" },
      { path = "quests/zone/Tirisfal Glades", name = "Tirisfal Glades", desc = "Zone quests" },
      { path = "quests/zone/Undercity", name = "Undercity", desc = "Zone quests" },
      { path = "quests/zone/Western Plaguelands", name = "Western Plaguelands", desc = "Zone quests" },
      { path = "quests/zone/Westfall", name = "Westfall", desc = "Zone quests" },
      { path = "quests/zone/Wetlands", name = "Wetlands", desc = "Zone quests" },
    },
  },

  ["quests/kalimdor"] = {
    title = "Kalimdor Quests",
    parent = "quests",
    folders = {
      { path = "quests/zone/Ashenvale", name = "Ashenvale", desc = "Zone quests" },
      { path = "quests/zone/Azshara", name = "Azshara", desc = "Zone quests" },
      { path = "quests/zone/Darkshore", name = "Darkshore", desc = "Zone quests" },
      { path = "quests/zone/Desolace", name = "Desolace", desc = "Zone quests" },
      { path = "quests/zone/Durotar", name = "Durotar", desc = "Zone quests" },
      { path = "quests/zone/Dustwallow Marsh", name = "Dustwallow Marsh", desc = "Zone quests" },
      { path = "quests/zone/Felwood", name = "Felwood", desc = "Zone quests" },
      { path = "quests/zone/Feralas", name = "Feralas", desc = "Zone quests" },
      { path = "quests/zone/Moonglade", name = "Moonglade", desc = "Zone quests" },
      { path = "quests/zone/Mulgore", name = "Mulgore", desc = "Zone quests" },
      { path = "quests/zone/Orgrimmar", name = "Orgrimmar", desc = "Zone quests" },
      { path = "quests/zone/Silithus", name = "Silithus", desc = "Zone quests" },
      { path = "quests/zone/Stonetalon Mountains", name = "Stonetalon Mountains", desc = "Zone quests" },
      { path = "quests/zone/Tanaris", name = "Tanaris", desc = "Zone quests" },
      { path = "quests/zone/Teldrassil", name = "Teldrassil", desc = "Zone quests" },
      { path = "quests/zone/The Barrens", name = "The Barrens", desc = "Zone quests" },
      { path = "quests/zone/Thousand Needles", name = "Thousand Needles", desc = "Zone quests" },
      { path = "quests/zone/Thunder Bluff", name = "Thunder Bluff", desc = "Zone quests" },
      { path = "quests/zone/Un'Goro Crater", name = "Un'Goro Crater", desc = "Zone quests" },
      { path = "quests/zone/Winterspring", name = "Winterspring", desc = "Zone quests" },
    },
  },

  ["quests/class"] = {
    title = "Class Quests",
    parent = "quests",
    folders = {
      { path = "quests/class/Druid Class Quests", name = "Druid", desc = "Bear form, aquatic, travel quests" },
      { path = "quests/class/Hunter Class Quests", name = "Hunter", desc = "Pet taming & class quests" },
      { path = "quests/class/Mage Class Quests", name = "Mage", desc = "Arcane, portal & robe quests" },
      { path = "quests/class/Paladin Class Quests", name = "Paladin", desc = "Warhorse, hammer & redemption" },
      { path = "quests/class/Priest Class Quests", name = "Priest", desc = "Devotion & Benediction quests" },
      { path = "quests/class/Rogue Class Quests", name = "Rogue", desc = "Poison brewing & lockpicking" },
      { path = "quests/class/Shaman Class Quests", name = "Shaman", desc = "Earth, Fire, Water, Air totems" },
      { path = "quests/class/Warlock Class Quests", name = "Warlock", desc = "Demon summons & Dreadsteed" },
      { path = "quests/class/Warrior Class Quests", name = "Warrior", desc = "Defensive & Berserker stances" },
    },
  },

  ["quests/professions"] = {
    title = "Profession Quests",
    parent = "quests",
    folders = {
      { path = "quests/prof/Alchemy", name = "Alchemy", desc = "Potions & masteries" },
      { path = "quests/prof/Blacksmithing", name = "Blacksmithing", desc = "Armorsmith & Weaponsmith" },
      { path = "quests/prof/Cooking", name = "Cooking", desc = "Recipes & feast quests" },
      { path = "quests/prof/Enchanting", name = "Enchanting", desc = "Rods & enchanting quests" },
      { path = "quests/prof/Engineering", name = "Engineering", desc = "Gnomish & Goblin engineering" },
      { path = "quests/prof/First Aid", name = "First Aid", desc = "Triage & artisan bandages" },
      { path = "quests/prof/Fishing", name = "Fishing", desc = "Nat Pagle & artisan angling" },
      { path = "quests/prof/Leatherworking", name = "Leatherworking", desc = "Dragonscale, Elemental, Tribal" },
      { path = "quests/prof/Mining", name = "Mining", desc = "Smelting & dark iron quests" },
      { path = "quests/prof/Tailoring", name = "Tailoring", desc = "Mooncloth & specialized weaves" },
    },
  },

  -- ITEMS HIERARCHY
  ["items"] = {
    title = "Items & Equipment",
    parent = "root",
    folders = {
      { path = "items/weapons", name = "Weapons", desc = "Swords, Axes, Maces, Staves, Bows..." },
      { path = "items/armor", name = "Armor", desc = "Cloth, Leather, Mail, Plate, Shields" },
      { path = "items/accessories", name = "Jewelry & Accessories", desc = "Rings, Trinkets, Necklaces, Cloaks" },
      { path = "items/consumables", name = "Consumables", desc = "Potions, Food, Bandages, Scrolls" },
      { path = "items/trade_goods", name = "Trade Goods", desc = "Herbs, Ore, Leather, Cloth, Reagents" },
      { path = "items/recipes", name = "Recipes & Plans", desc = "Crafting Recipes & Manuals" },
      { path = "items/forever", name = "[Forever] Forever Custom Gear", desc = "Exclusive Warcraft Forever items" },
    },
  },

  ["items/weapons"] = {
    title = "Weapons",
    parent = "items",
    folders = {
      { path = "items/sub/One-Handed Axes", name = "One-Handed Axes", filter = { slot = "One-Hand", itemType = "Axe" } },
      { path = "items/sub/Two-Handed Axes", name = "Two-Handed Axes", filter = { slot = "Two-Hand", itemType = "Axe" } },
      { path = "items/sub/Bows", name = "Bows & Crossbows", filter = { itemType = "Bow" } },
      { path = "items/sub/Daggers", name = "Daggers", filter = { itemType = "Dagger" } },
      { path = "items/sub/Guns", name = "Guns & Ranged", filter = { itemType = "Gun" } },
      { path = "items/sub/One-Handed Maces", name = "One-Handed Maces", filter = { slot = "One-Hand", itemType = "Mace" } },
      { path = "items/sub/Two-Handed Maces", name = "Two-Handed Maces", filter = { slot = "Two-Hand", itemType = "Mace" } },
      { path = "items/sub/Polearms", name = "Polearms", filter = { itemType = "Polearm" } },
      { path = "items/sub/Staves", name = "Staves", filter = { itemType = "Staff" } },
      { path = "items/sub/One-Handed Swords", name = "One-Handed Swords", filter = { slot = "One-Hand", itemType = "Sword" } },
      { path = "items/sub/Two-Handed Swords", name = "Two-Handed Swords", filter = { slot = "Two-Hand", itemType = "Sword" } },
      { path = "items/sub/Wands", name = "Wands", filter = { itemType = "Wand" } },
      { path = "items/sub/Fist Weapons", name = "Fist Weapons", filter = { itemType = "Fist Weapon" } },
    },
  },

  ["items/armor"] = {
    title = "Armor",
    parent = "items",
    folders = {
      { path = "items/armor/cloth", name = "Cloth Armor", desc = "Head, Chest, Belt, Boots, etc." },
      { path = "items/armor/leather", name = "Leather Armor", desc = "Head, Chest, Belt, Boots, etc." },
      { path = "items/armor/mail", name = "Mail Armor", desc = "Head, Chest, Belt, Boots, etc." },
      { path = "items/armor/plate", name = "Plate Armor", desc = "Head, Chest, Belt, Boots, etc." },
      { path = "items/sub/Shields", name = "Shields", desc = "Off-Hand Shields (iLvl Low to High)" },
      { path = "items/sub/Cloaks", name = "Cloaks & Capes", desc = "Back slot cloaks (iLvl Low to High)" },
    },
  },

  ["items/armor/cloth"] = {
    title = "Cloth Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/cloth/Head", name = "Head", desc = "Cloth helms, hoods & circlets" },
      { path = "items/armor/cloth/Shoulder", name = "Shoulders", desc = "Cloth mantles & shoulderpads" },
      { path = "items/armor/cloth/Chest", name = "Chest", desc = "Cloth robes, vests & tunics" },
      { path = "items/armor/cloth/Wrist", name = "Wrist (Bracers)", desc = "Cloth bracers & cuffs" },
      { path = "items/armor/cloth/Hands", name = "Hands (Gloves)", desc = "Cloth gloves & mitts" },
      { path = "items/armor/cloth/Waist", name = "Waist (Belts)", desc = "Cloth belts & sashes" },
      { path = "items/armor/cloth/Legs", name = "Legs (Pants)", desc = "Cloth pants & leggings" },
      { path = "items/armor/cloth/Feet", name = "Feet (Boots)", desc = "Cloth boots & slippers" },
    },
  },

  ["items/armor/leather"] = {
    title = "Leather Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/leather/Head", name = "Head", desc = "Leather helms, caps & headbands" },
      { path = "items/armor/leather/Shoulder", name = "Shoulders", desc = "Leather spaulders & shoulderpads" },
      { path = "items/armor/leather/Chest", name = "Chest", desc = "Leather vests, jerkins & armor" },
      { path = "items/armor/leather/Wrist", name = "Wrist (Bracers)", desc = "Leather bracers & wristguards" },
      { path = "items/armor/leather/Hands", name = "Hands (Gloves)", desc = "Leather gloves & gauntlets" },
      { path = "items/armor/leather/Waist", name = "Waist (Belts)", desc = "Leather belts & girdles" },
      { path = "items/armor/leather/Legs", name = "Legs (Pants)", desc = "Leather pants & breeches" },
      { path = "items/armor/leather/Feet", name = "Feet (Boots)", desc = "Leather boots & footwear" },
    },
  },

  ["items/armor/mail"] = {
    title = "Mail Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/mail/Head", name = "Head", desc = "Mail helms & coifs" },
      { path = "items/armor/mail/Shoulder", name = "Shoulders", desc = "Mail pauldrons & epaulets" },
      { path = "items/armor/mail/Chest", name = "Chest", desc = "Mail hauberks, mail & armor" },
      { path = "items/armor/mail/Wrist", name = "Wrist (Bracers)", desc = "Mail bracers & armsplints" },
      { path = "items/armor/mail/Hands", name = "Hands (Gauntlets)", desc = "Mail gauntlets & grips" },
      { path = "items/armor/mail/Waist", name = "Waist (Belts)", desc = "Mail belts & girdles" },
      { path = "items/armor/mail/Legs", name = "Legs (Legguards)", desc = "Mail legplates & greaves" },
      { path = "items/armor/mail/Feet", name = "Feet (Boots)", desc = "Mail boots & sabatons" },
    },
  },

  ["items/armor/plate"] = {
    title = "Plate Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/plate/Head", name = "Head", desc = "Plate helms & visors" },
      { path = "items/armor/plate/Shoulder", name = "Shoulders", desc = "Plate pauldrons & spaulders" },
      { path = "items/armor/plate/Chest", name = "Chest", desc = "Plate breastplates & chestguards" },
      { path = "items/armor/plate/Wrist", name = "Wrist (Bracers)", desc = "Plate bracers & vambraces" },
      { path = "items/armor/plate/Hands", name = "Hands (Gauntlets)", desc = "Plate gauntlets & gloves" },
      { path = "items/armor/plate/Waist", name = "Waist (Belts)", desc = "Plate belts & girdles" },
      { path = "items/armor/plate/Legs", name = "Legs (Legplates)", desc = "Plate legplates & leggings" },
      { path = "items/armor/plate/Feet", name = "Feet (Boots)", desc = "Plate boots & sabatons" },
    },
  },

  ["items/accessories"] = {
    title = "Jewelry & Accessories",
    parent = "items",
    folders = {
      { path = "items/sub/Amulets", name = "Amulets & Necklaces", filter = { slot = "Neck" } },
      { path = "items/sub/Rings", name = "Rings & Bands", filter = { slot = "Finger" } },
      { path = "items/sub/Trinkets", name = "Trinkets", filter = { slot = "Trinket" } },
      { path = "items/sub/Cloaks", name = "Cloaks & Capes", filter = { slot = "Back" } },
    },
  },

  ["items/consumables"] = {
    title = "Consumables",
    parent = "items",
    folders = {
      { path = "items/sub/Potions", name = "Potions & Elixirs", filter = { itemType = "Potion" } },
      { path = "items/sub/Food", name = "Food & Drink", filter = { itemType = "Food & Drink" } },
      { path = "items/sub/Bandages", name = "Bandages", filter = { itemType = "Bandage" } },
      { path = "items/sub/Scrolls", name = "Scrolls", filter = { itemType = "Scroll" } },
    },
  },

  ["items/trade_goods"] = {
    title = "Trade Goods",
    parent = "items",
    folders = {
      { path = "items/sub/Herbs", name = "Herbs", filter = { itemType = "Herb" } },
      { path = "items/sub/Ore", name = "Metal & Stone", filter = { itemType = "Metal & Stone" } },
      { path = "items/sub/Parts", name = "Parts & Devices", filter = { itemType = "Parts" } },
      { path = "items/sub/Reagents", name = "Reagents & Materials", filter = { itemType = "Reagent" } },
    },
  },

  ["items/recipes"] = {
    title = "Recipes & Plans",
    parent = "items",
    folders = {
      { path = "items/sub/All Recipes", name = "All Recipes & Plans", filter = { itemType = "Recipe" } },
    },
  },

  -- CREATURES HIERARCHY
  ["creatures"] = {
    title = "Creatures & Bosses",
    parent = "root",
    folders = {
      { path = "creatures/by_zone_ek", name = "Eastern Kingdoms (By Zone)", desc = "24 zones alphabetically (A to Z)" },
      { path = "creatures/by_zone_kalimdor", name = "Kalimdor (By Zone)", desc = "20 zones alphabetically (A to Z)" },
      { path = "creatures/bosses", name = "World & Dungeon Bosses", desc = "Major encounter bosses" },
      { path = "creatures/rares", name = "Rare & Rare Elite Encounters", desc = "Silver-dragon rare spawns" },
      { path = "creatures/beasts", name = "Beasts", desc = "Bears, Wolves, Cats, Raptors (By Zone or A to Z)" },
      { path = "creatures/humanoids", name = "Humanoids", desc = "Bandits, Pirates, Cultists (By Zone or A to Z)" },
      { path = "creatures/undead", name = "Undead", desc = "Scourge & Skeletons (By Zone or A to Z)" },
      { path = "creatures/demons", name = "Demons", desc = "Burning Legion demons (By Zone or A to Z)" },
      { path = "creatures/dragonkin", name = "Dragonkin", desc = "Black, Red, Green flights (By Zone or A to Z)" },
      { path = "creatures/elementals", name = "Elementals", desc = "Fire, Water, Earth, Air (By Zone or A to Z)" },
      { path = "creatures/giants", name = "Giants", desc = "Giants & Colossi (By Zone or A to Z)" },
      { path = "creatures/forever", name = "[Forever] Forever Custom NPCs", desc = "Exclusive server NPCs" },
    },
  },

  -- DUNGEONS HIERARCHY
  ["dungeons"] = {
    title = "Dungeons & Raids",
    parent = "root",
    folders = {
      { path = "dungeons/starter", name = "Starter Dungeons (Lvl 15-30)", desc = "Deadmines, WC, SFK, BFD, Stockade" },
      { path = "dungeons/mid", name = "Mid-Tier Dungeons (Lvl 30-50)", desc = "Gnomeregan, SM, RFK, RFD, Uldaman, ZF, Mara" },
      { path = "dungeons/endgame", name = "Endgame Dungeons (Lvl 50-60)", desc = "BRD, LBRS, UBRS, Strath, Scholo, DM, ST" },
      { path = "dungeons/raids", name = "Raid Dungeons (Lvl 60)", desc = "MC, Onyxia, BWL, ZG, AQ20, AQ40, Naxx" },
      { path = "dungeons/forever", name = "[Forever] Forever Custom Dungeons", desc = "Crypts, Thanes, Roots, Hateforge, Rift..." },
    },
  },

  -- VENDORS HIERARCHY
  ["vendors"] = {
    title = "Vendors & Flight Paths",
    parent = "root",
    folders = {
      { path = "vendors/flightpaths", name = "Flight Masters", desc = "Alliance & Horde Flight Masters" },
      { path = "vendors/pvp", name = "PvP Quartermasters", desc = "Battlegrounds & Honor Vendors" },
      { path = "vendors/specialty", name = "Specialty & Rare Goods", desc = "Limited Recipes, Pets & Unique items" },
    },
  },

  -- FOREVER CUSTOM CONTENT
  ["forever"] = {
    title = "[Forever] Warcraft Forever Custom Content",
    parent = "root",
    folders = {
      { path = "forever/items", name = "Forever Gear & Items", desc = "Custom itemization & set pieces" },
      { path = "forever/quests", name = "Forever Quests & Storylines", desc = "Custom narrative and story quests" },
      { path = "forever/creatures", name = "Forever NPCs & Bosses", desc = "Custom encounters and rare mobs" },
      { path = "forever/dungeons", name = "Forever Dungeons & Raids", desc = "Custom instances & progressive raids" },
    },
  },
}

function FG:NavigateToFolder(path)
  FG.currentFolder = path or "root"
  if ForeverGuideSearchBox then
    ForeverGuideSearchBox:SetText("")
    if ForeverGuideSearchBox.Placeholder then ForeverGuideSearchBox.Placeholder:Show() end
    if ForeverGuideSearchBox.ClearBtn then ForeverGuideSearchBox.ClearBtn:Hide() end
  end
  FG:PopulateCodexResults("")
end

function FG:NavigateUpFolder()
  local q = ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or ""
  if q ~= "" then
    ForeverGuideSearchBox:SetText("")
    if ForeverGuideSearchBox.Placeholder then ForeverGuideSearchBox.Placeholder:Show() end
    if ForeverGuideSearchBox.ClearBtn then ForeverGuideSearchBox.ClearBtn:Hide() end
    FG:PopulateCodexResults("")
    return
  end

  local cur = FG.currentFolder or "root"
  if cur == "root" then return end

  local folderDef = FG.FolderTree[cur]
  local parent = (folderDef and folderDef.parent)
  if not parent then
    if cur:find("^quests/zone/") then
      local zn = cur:sub(13)
      parent = KALIMDOR_ZONES[zn] and "quests/kalimdor" or "quests/eastern_kingdoms"
    elseif cur:find("^quests/class/") then
      parent = "quests/class"
    elseif cur:find("^quests/prof/") then
      parent = "quests/professions"
    elseif cur:find("^items/armor/[^/]+/[^/]+$") then
      local armorType = cur:match("^items/armor/([^/]+)/[^/]+$")
      parent = "items/armor/" .. armorType
    elseif cur:find("^items/armor/[^/]+$") then
      parent = "items/armor"
    elseif cur:find("^items/sub/") then
      local sub = cur:sub(11)
      if sub:find("Armor$") or sub == "Shields" or sub == "Cloaks" then
        parent = "items/armor"
      else
        parent = "items"
      end
    elseif cur:find("^nearby/") then
      parent = "nearby"
    elseif cur == "nearby" then
      parent = "root"
    elseif cur:find("^creatures/[^/]+/zone/") then
      local fam, zn = cur:match("^creatures/([^/]+)/zone/(.+)$")
      parent = KALIMDOR_ZONES[zn] and ("creatures/" .. fam .. "/kalimdor") or ("creatures/" .. fam .. "/ek")
    elseif cur:find("^creatures/[^/]+/[^/]+$") then
      local fam = cur:match("^creatures/([^/]+)/[^/]+$")
      parent = "creatures/" .. fam
    elseif cur:find("^creatures/zone/") then
      local zn = cur:sub(16)
      parent = KALIMDOR_ZONES[zn] and "creatures/by_zone_kalimdor" or "creatures/by_zone_ek"
    elseif cur:find("^creatures/[^/]+$") then
      parent = "creatures"
    elseif cur:find("/") then
      parent = cur:match("^(.*)/[^/]+$")
    else
      parent = "root"
    end
  end
  FG:NavigateToFolder(parent or "root")
end

function FG:UpdateDolphinBreadcrumbs(query, matchCount)
  local cw = FG.CodexWindow
  if not cw or not cw.DolphinBar or not cw.DolphinBar.Breadcrumbs then return end
  local bText = cw.DolphinBar.Breadcrumbs
  local upBtn = cw.DolphinBar.UpBtn

  local q = (query or ""):trim()
  local cur = FG.currentFolder or "root"

  if q ~= "" then
    if upBtn then
      upBtn:Enable()
      local ufs = upBtn:GetFontString()
      if ufs then ufs:SetTextColor(1, 1, 1) end
    end
    bText:SetText(string.format("|cffcf52ffHome|r |cff666688>|r |cffdf80ffSearch: \"|r|cffffffff%s|r|cffdf80ff\"|r |cff888899(%d items)|r", q, matchCount or 0))
    return
  end

  if cur == "root" then
    if upBtn then
      upBtn:Disable()
      local ufs = upBtn:GetFontString()
      if ufs then ufs:SetTextColor(0.45, 0.45, 0.50) end
    end
    bText:SetText("|cffcf52ffHome|r")
    return
  end

  if upBtn then
    upBtn:Enable()
    local ufs = upBtn:GetFontString()
    if ufs then ufs:SetTextColor(1, 1, 1) end
  end

  local trail = { "|cffcf52ffHome|r" }
  if cur:find("^nearby") or FG.activeCategory == "nearby" then
    local pZone, pSub = FG:GetPlayerZoneInfo()
    local zoneDisplay = pZone ~= "" and pZone or "Azeroth"
    if pSub and pSub ~= "" then zoneDisplay = zoneDisplay .. " (" .. pSub .. ")" end
    table.insert(trail, "|cff20ff20Nearby (" .. zoneDisplay .. ")|r")
    if cur == "nearby/quests" then table.insert(trail, "|cffffd24dQuests|r")
    elseif cur == "nearby/rares" then table.insert(trail, "|cffffd24dRares & Bosses|r")
    elseif cur == "nearby/creatures" then table.insert(trail, "|cffffd24dCreatures|r")
    elseif cur == "nearby/vendors" then table.insert(trail, "|cffffd24dVendors & Flight|r")
    elseif cur == "nearby/dungeons" then table.insert(trail, "|cffffd24dDungeons|r")
    elseif cur == "nearby/loot" then table.insert(trail, "|cffffd24dNotable Loot|r")
    end
  elseif cur:find("^quests") then
    table.insert(trail, "|cff88aaccQuests|r")
    if cur == "quests/eastern_kingdoms" then
      table.insert(trail, "|cffffffffEastern Kingdoms|r")
    elseif cur == "quests/kalimdor" then
      table.insert(trail, "|cffffffffKalimdor|r")
    elseif cur == "quests/class" then
      table.insert(trail, "|cffffffffClass Quests|r")
    elseif cur == "quests/professions" then
      table.insert(trail, "|cffffffffProfessions|r")
    elseif cur == "quests/dungeons" then
      table.insert(trail, "|cffffffffDungeon Quests|r")
    elseif cur == "quests/forever" then
      table.insert(trail, "|cffe6cc80[Forever] Quests|r")
    elseif cur:find("^quests/zone/") then
      local zn = cur:sub(13)
      local region = KALIMDOR_ZONES[zn] and "Kalimdor" or "Eastern Kingdoms"
      table.insert(trail, "|cff88aacc" .. region .. "|r")
      table.insert(trail, "|cffffd24d" .. zn .. "|r")
    elseif cur:find("^quests/class/") then
      table.insert(trail, "|cff88aaccClasses|r")
      table.insert(trail, "|cffffd24d" .. cur:sub(14):gsub(" Class Quests", "") .. "|r")
    elseif cur:find("^quests/prof/") then
      table.insert(trail, "|cff88aaccProfessions|r")
      table.insert(trail, "|cffffd24d" .. cur:sub(13) .. "|r")
    end
  elseif cur:find("^items") then
    table.insert(trail, "|cff88aaccItems|r")
    if cur == "items/weapons" then table.insert(trail, "|cffffffffWeapons|r")
    elseif cur == "items/armor" then table.insert(trail, "|cffffffffArmor|r")
    elseif cur:find("^items/armor/[^/]+/[^/]+$") then
      local armorType, slot = cur:match("^items/armor/([^/]+)/([^/]+)$")
      local slotDisplay = slot
      if slot == "Waist" then slotDisplay = "Waist (Belts)"
      elseif slot == "Wrist" then slotDisplay = "Wrist (Bracers)"
      elseif slot == "Hands" then slotDisplay = "Hands (Gauntlets)"
      elseif slot == "Feet" then slotDisplay = "Feet (Boots)"
      elseif slot == "Shoulder" then slotDisplay = "Shoulders"
      end
      table.insert(trail, "|cffffffffArmor|r")
      table.insert(trail, "|cff88aacc" .. armorType:gsub("^%l", string.upper) .. " Armor|r")
      table.insert(trail, "|cffffd24d" .. slotDisplay .. "|r")
    elseif cur:find("^items/armor/[^/]+$") then
      local armorType = cur:match("^items/armor/([^/]+)$")
      table.insert(trail, "|cffffffffArmor|r")
      table.insert(trail, "|cffffd24d" .. armorType:gsub("^%l", string.upper) .. " Armor|r")
    elseif cur == "items/accessories" then table.insert(trail, "|cffffffffAccessories|r")
    elseif cur == "items/consumables" then table.insert(trail, "|cffffffffConsumables|r")
    elseif cur == "items/trade_goods" then table.insert(trail, "|cffffffffTrade Goods|r")
    elseif cur == "items/recipes" then table.insert(trail, "|cffffffffRecipes|r")
    elseif cur == "items/forever" then table.insert(trail, "|cffe6cc80[Forever] Gear|r")
    elseif cur:find("^items/sub/") then
      table.insert(trail, "|cffffd24d" .. cur:sub(11) .. "|r")
    end
  elseif cur:find("^creatures") then
    table.insert(trail, "|cff88aaccCreatures|r")
    if cur == "creatures/by_zone_ek" then
      table.insert(trail, "|cffffffffEastern Kingdoms (Zones)|r")
    elseif cur == "creatures/by_zone_kalimdor" then
      table.insert(trail, "|cffffffffKalimdor (Zones)|r")
    elseif cur:find("^creatures/zone/") then
      local zn = cur:sub(16)
      local region = KALIMDOR_ZONES[zn] and "Kalimdor" or "Eastern Kingdoms"
      table.insert(trail, "|cff88aacc" .. region .. "|r")
      table.insert(trail, "|cffffd24d" .. zn .. "|r")
    elseif cur:find("^creatures/[^/]+/zone/") then
      local fam, zn = cur:match("^creatures/([^/]+)/zone/(.+)$")
      local region = KALIMDOR_ZONES[zn] and "Kalimdor" or "Eastern Kingdoms"
      table.insert(trail, "|cff88aacc" .. fam:gsub("^%l", string.upper) .. "|r")
      table.insert(trail, "|cffffffff" .. region .. "|r")
      table.insert(trail, "|cffffd24d" .. zn .. "|r")
    elseif cur:find("^creatures/[^/]+/ek$") then
      local fam = cur:match("^creatures/([^/]+)/ek$")
      table.insert(trail, "|cff88aacc" .. fam:gsub("^%l", string.upper) .. "|r")
      table.insert(trail, "|cffffd24dEastern Kingdoms|r")
    elseif cur:find("^creatures/[^/]+/kalimdor$") then
      local fam = cur:match("^creatures/([^/]+)/kalimdor$")
      table.insert(trail, "|cff88aacc" .. fam:gsub("^%l", string.upper) .. "|r")
      table.insert(trail, "|cffffd24dKalimdor|r")
    elseif cur:find("^creatures/[^/]+/all$") then
      local fam = cur:match("^creatures/([^/]+)/all$")
      table.insert(trail, "|cff88aacc" .. fam:gsub("^%l", string.upper) .. "|r")
      table.insert(trail, "|cffffd24dAll (A-Z)|r")
    elseif cur == "creatures/bosses" then table.insert(trail, "|cffffffffBosses|r")
    elseif cur == "creatures/rares" then table.insert(trail, "|cffffffffRares|r")
    elseif cur == "creatures/forever" then table.insert(trail, "|cffe6cc80[Forever] NPCs|r")
    elseif cur:find("^creatures/") then table.insert(trail, "|cffffd24d" .. cur:sub(11):gsub("^%l", string.upper) .. "|r")
    end
  elseif cur:find("^dungeons") then
    table.insert(trail, "|cff88aaccDungeons|r")
    if cur == "dungeons/starter" then table.insert(trail, "|cffffffffStarter (15-30)|r")
    elseif cur == "dungeons/mid" then table.insert(trail, "|cffffffffMid-Tier (30-50)|r")
    elseif cur == "dungeons/endgame" then table.insert(trail, "|cffffffffEndgame (50-60)|r")
    elseif cur == "dungeons/raids" then table.insert(trail, "|cffffffffRaids (Lvl 60)|r")
    elseif cur == "dungeons/forever" then table.insert(trail, "|cffe6cc80[Forever] Instances|r")
    end
  elseif cur:find("^vendors") then
    table.insert(trail, "|cff88aaccVendors|r")
    if cur == "vendors/flightpaths" then table.insert(trail, "|cffffffffFlight Masters|r")
    elseif cur == "vendors/pvp" then table.insert(trail, "|cffffffffPvP Vendors|r")
    elseif cur == "vendors/specialty" then table.insert(trail, "|cffffffffSpecialty Goods|r")
    end
  elseif cur:find("^forever") then
    table.insert(trail, "|cffe6cc80[Forever] Content|r")
    if cur == "forever/items" then table.insert(trail, "|cffffffffGear|r")
    elseif cur == "forever/quests" then table.insert(trail, "|cffffffffQuests|r")
    elseif cur == "forever/creatures" then table.insert(trail, "|cffffffffNPCs|r")
    elseif cur == "forever/dungeons" then table.insert(trail, "|cffffffffDungeons|r")
    end
  end

  bText:SetText(table.concat(trail, " |cff666688>|r "))
end

function FG:IsInternalCreature(name, family)
  if not name then return true end
  if family and family == "Internal" then return true end
  local n = name:lower()
  if n:find(" form%f[%A]") or n:find("%(druid") or n:find("%(shapeshift") or n:find("form %(") or
     n:find("dummy") or n:find("trigger") or n:find("credit marker") or n:find("controller") or
     n:find("spawner") or n:find("%[ph%]") or n:find("%[ph%[") or n:find("^placeholder") or
     n:find("invisible") or n:find("%(dnd%)") or n:find("%[dnd%]") or n:find("test mob") or
     n:find("test dude") or n:find("^world [a-z]+ trainer") then
    return true
  end
  return false
end

local function CreatureMatchesFamily(c, targetFam)
  if not c or not targetFam then return false end
  local s = targetFam:lower()
  if s == "bosses" then
    return (c.classification == "Boss" or c.classification == "World Boss")
  elseif s == "rares" then
    return (c.classification == "Rare" or c.classification == "Rare Elite")
  elseif s == "forever" then
    return c.isForever == true
  elseif c.family then
    local fam = c.family:lower()
    return (fam == s or fam .. "s" == s or (s:sub(-1) == "s" and fam == s:sub(1, -2)))
  end
  return false
end

function FG:PopulateCodexResults(query)
  if not FG.CodexWindow or not FG.CodexWindow.Content then return end
  local content = FG.CodexWindow.Content
  local scrollFrame = ForeverGuideScrollFrame

  if content.BlankState then content.BlankState:Hide() end

  local q = (query or ""):lower():trim()
  local cat = FG.activeCategory or "all"
  local cur = FG.currentFolder or "root"
  local cw = FG.CodexWindow

  local matches = {}

  if cur == "nearby" or cat == "nearby" or cur:find("^nearby/") then
    local pZone, pSub = FG:GetPlayerZoneInfo()
    local pZoneLower = pZone:lower()
    local pSubLower = (pSub or ""):lower()

    local isNearbyRoot = (cur == "nearby" or cat == "nearby") and (not cur:find("^nearby/"))

    if isNearbyRoot and q == "" then
      -- Top-level Nearby view: Show 6 KDE Dolphin folders with live counts for current zone!
      local qCount = 0
      if FG.Data.Quests then
        for _, quest in pairs(FG.Data.Quests) do
          local inZone = quest.zone and quest.zone:lower() == pZoneLower
          local inSub = pSubLower ~= "" and ((quest.zone and quest.zone:lower():find(pSubLower, 1, true)) or (quest.npc and quest.npc:lower():find(pSubLower, 1, true)))
          if inZone or inSub then qCount = qCount + 1 end
        end
      end

      local rCount = 0
      local cCount = 0
      if FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) then
            local inZone = c.zone and c.zone:lower() == pZoneLower
            local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
            if inZone or inSub then
              cCount = cCount + 1
              if c.classification == "Boss" or c.classification == "World Boss" or c.classification == "Rare" or c.classification == "Rare Elite" then
                rCount = rCount + 1
              end
            end
          end
        end
      end

      local vCount = 0
      if FG.Data.Vendors then
        for _, v in pairs(FG.Data.Vendors) do
          if v.zone and v.zone:lower() == pZoneLower then vCount = vCount + 1 end
        end
      end
      if FG.Data.Flightpaths then
        for _, fp in pairs(FG.Data.Flightpaths) do
          if fp.zone and fp.zone:lower() == pZoneLower then vCount = vCount + 1 end
        end
      end

      local dCount = 0
      if FG.Data.Dungeons then
        for _, d in pairs(FG.Data.Dungeons) do
          if d.zone and d.zone:lower():find(pZoneLower, 1, true) then dCount = dCount + 1 end
        end
      end

      local lCount = 0
      if FG.Data.Items then
        for _, item in pairs(FG.Data.Items) do
          if item.source and item.source:lower():find(pZoneLower, 1, true) then lCount = lCount + 1 end
        end
      end

      table.insert(matches, {
        type = "folder",
        data = {
          name = "Quests",
          path = "nearby/quests",
          desc = string.format("%d quests in %s", qCount, pZone),
          count = qCount,
          icon = "Interface\\Icons\\INV_Misc_Book_07",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Rares & Bosses",
          path = "nearby/rares",
          desc = string.format("%d rare spawns & bosses in %s", rCount, pZone),
          count = rCount,
          icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Creatures & Mobs",
          path = "nearby/creatures",
          desc = string.format("%d creatures & NPCs in %s", cCount, pZone),
          count = cCount,
          icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Vendors & Flight Masters",
          path = "nearby/vendors",
          desc = string.format("%d vendors & flight masters in %s", vCount, pZone),
          count = vCount,
          icon = "Interface\\Icons\\INV_Misc_Coin_01",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Dungeons & Raids",
          path = "nearby/dungeons",
          desc = string.format("%d dungeons & raids in %s", dCount, pZone),
          count = dCount,
          icon = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Notable Loot & Drops",
          path = "nearby/loot",
          desc = string.format("%d notable items & drops in %s", lCount, pZone),
          count = lCount,
          icon = "Interface\\Icons\\INV_Box_01",
        }
      })

    else
      -- Leaf category folder or searching in nearby
      local showQuests = (cur == "nearby/quests") or (isNearbyRoot and q ~= "")
      local showRares = (cur == "nearby/rares") or (isNearbyRoot and q ~= "")
      local showCreatures = (cur == "nearby/creatures") or (isNearbyRoot and q ~= "")
      local showVendors = (cur == "nearby/vendors") or (isNearbyRoot and q ~= "")
      local showDungeons = (cur == "nearby/dungeons") or (isNearbyRoot and q ~= "")
      local showLoot = (cur == "nearby/loot") or (isNearbyRoot and q ~= "")

      -- 1. Nearby Bosses & Rares
      if showRares and FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) then
            if c.classification == "Boss" or c.classification == "World Boss" or c.classification == "Rare" or c.classification == "Rare Elite" then
              local inZone = c.zone and c.zone:lower() == pZoneLower
              local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
              if inZone or inSub then
                if q == "" or (c.name and c.name:lower():find(q, 1, true)) then
                  table.insert(matches, { type = "creature", data = c, isNearby = true })
                end
              end
            end
          end
        end
      end

      -- 2. Nearby Creatures & Mobs
      if showCreatures and FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) then
            if not showRares or not (c.classification == "Boss" or c.classification == "World Boss" or c.classification == "Rare" or c.classification == "Rare Elite") then
              local inZone = c.zone and c.zone:lower() == pZoneLower
              local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
              if inZone or inSub then
                if q == "" or (c.name and c.name:lower():find(q, 1, true)) then
                  table.insert(matches, { type = "creature", data = c, isNearby = true })
                end
              end
            end
          end
        end
      end

      -- 3. Nearby Quests
      if showQuests and FG.Data.Quests then
        for _, quest in pairs(FG.Data.Quests) do
          local inZone = quest.zone and quest.zone:lower() == pZoneLower
          local inSub = pSubLower ~= "" and ((quest.zone and quest.zone:lower():find(pSubLower, 1, true)) or (quest.npc and quest.npc:lower():find(pSubLower, 1, true)))
          if inZone or inSub then
            if q == "" or (quest.title and quest.title:lower():find(q, 1, true)) then
              table.insert(matches, { type = "quest", data = quest, isNearby = true })
            end
          end
        end
      end

      -- 4. Nearby Vendors & Flight Masters
      if showVendors then
        if FG.Data.Vendors then
          for _, v in pairs(FG.Data.Vendors) do
            local inZone = v.zone and v.zone:lower() == pZoneLower
            if inZone then
              if q == "" or (v.name and v.name:lower():find(q, 1, true)) or (v.item and v.item:lower():find(q, 1, true)) then
                table.insert(matches, { type = "vendor", data = v, isNearby = true })
              end
            end
          end
        end
        if FG.Data.Flightpaths then
          for _, fp in pairs(FG.Data.Flightpaths) do
            local inZone = fp.zone and fp.zone:lower() == pZoneLower
            if inZone then
              local vData = { name = fp.name, zone = fp.zone, coords = fp.coords, item = fp.faction .. " Flight Master", tip = fp.notes or fp.connections }
              if q == "" or (fp.name and fp.name:lower():find(q, 1, true)) then
                table.insert(matches, { type = "vendor", data = vData, isNearby = true })
              end
            end
          end
        end
      end

      -- 5. Nearby Dungeons
      if showDungeons and FG.Data.Dungeons then
        for _, d in pairs(FG.Data.Dungeons) do
          local inZone = d.zone and d.zone:lower():find(pZoneLower, 1, true)
          if inZone then
            if q == "" or (d.name and d.name:lower():find(q, 1, true)) then
              table.insert(matches, { type = "dungeon", data = d, isNearby = true })
            end
          end
        end
      end

      -- 6. Nearby Notable Loot
      if showLoot and FG.Data.Items and #matches < 300 then
        for _, item in pairs(FG.Data.Items) do
          local inSource = item.source and item.source:lower():find(pZoneLower, 1, true)
          if inSource then
            if q == "" or (item.name and item.name:lower():find(q, 1, true)) then
              table.insert(matches, { type = "item", data = item, isNearby = true })
            end
          end
        end
      end
    end

  elseif q == "" then
    -- Browsing current Dolphin folder
    local folderDef = FG.FolderTree[cur]
    if folderDef and folderDef.folders then
      for _, f in ipairs(folderDef.folders) do
        table.insert(matches, { type = "folder", data = f })
      end
    end

    -- Leaf folders: populate matching data items
    if cur:find("^quests/zone/") and FG.Data.Quests then
      local zoneName = cur:sub(13)
      for _, quest in pairs(FG.Data.Quests) do
        if quest.zone == zoneName then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur:find("^quests/class/") and FG.Data.Quests then
      local classZone = cur:sub(14)
      for _, quest in pairs(FG.Data.Quests) do
        if quest.zone == classZone then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur:find("^quests/prof/") and FG.Data.Quests then
      local profZone = cur:sub(13)
      for _, quest in pairs(FG.Data.Quests) do
        if quest.zone == profZone then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur == "quests/dungeons" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if quest.zone and (quest.zone:find("Deadmines") or quest.zone:find("Wailing") or quest.zone:find("Shadowfang") or
                           quest.zone:find("Blackfathom") or quest.zone:find("Gnomeregan") or quest.zone:find("Scarlet") or
                           quest.zone:find("Razorfen") or quest.zone:find("Uldaman") or quest.zone:find("Zul'") or
                           quest.zone:find("Maraudon") or quest.zone:find("Blackrock") or quest.zone:find("Stratholme") or
                           quest.zone:find("Scholomance") or quest.zone:find("Dire Maul") or quest.zone:find("Molten") or
                           quest.zone:find("Ahn'Qiraj") or quest.zone:find("Naxxramas")) then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur == "quests/forever" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if quest.isForever then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur == "items/forever" and FG.Data.Items then
      for _, item in pairs(FG.Data.Items) do
        if item.isForever then
          table.insert(matches, { type = "item", data = item })
        end
      end
    elseif cur:find("^items/armor/([^/]+)/([^/]+)$") and FG.Data.Items then
      local armorType, slotName = cur:match("^items/armor/([^/]+)/([^/]+)$")
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isInternal = name:find("^OLD") or name:find("^zzOLD") or name:find("^Monster %-") or name:find("^TEST") or name:find("%[PH%]")
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not isInternal and not isRecipe and item.itemType and item.itemType:lower():find(armorType) then
          if item.slot and item.slot == slotName then
            table.insert(matches, { type = "item", data = item })
          end
        end
      end
    elseif cur:find("^items/armor/([^/]+)$") and FG.Data.Items then
      local armorType = cur:match("^items/armor/([^/]+)$")
      local armorCap = armorType:gsub("^%l", string.upper)
      local slotCounts = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isInternal = name:find("^OLD") or name:find("^zzOLD") or name:find("^Monster %-") or name:find("^TEST") or name:find("%[PH%]")
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not isInternal and not isRecipe and item.itemType and item.itemType:lower():find(armorType) then
          if item.slot then
            slotCounts[item.slot] = (slotCounts[item.slot] or 0) + 1
          end
        end
      end
      for _, sdef in ipairs(ARMOR_SLOT_DEFS) do
        local count = slotCounts[sdef.slot] or 0
        table.insert(matches, {
          type = "folder",
          data = {
            name = sdef.name,
            path = "items/armor/" .. armorType .. "/" .. sdef.slot,
            desc = string.format("%d %s %s items (iLvl Low to High)", count, armorCap, sdef.name),
            count = count,
            icon = sdef.icon,
          }
        })
      end
    elseif cur:find("^items/sub/") and FG.Data.Items then
      local subName = cur:sub(11)
      local armorKey = subName:match("^(%w+) Armor")
      if armorKey then
        local aType = armorKey:lower()
        local slotCounts = {}
        for _, item in pairs(FG.Data.Items) do
          local name = item.name or ""
          local isInternal = name:find("^OLD") or name:find("^zzOLD") or name:find("^Monster %-") or name:find("^TEST") or name:find("%[PH%]")
          local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
          if not isInternal and not isRecipe and item.itemType and item.itemType:lower():find(aType) and item.slot then
            slotCounts[item.slot] = (slotCounts[item.slot] or 0) + 1
          end
        end
        for _, sdef in ipairs(ARMOR_SLOT_DEFS) do
          local count = slotCounts[sdef.slot] or 0
          table.insert(matches, {
            type = "folder",
            data = {
              name = sdef.name,
              path = "items/armor/" .. aType .. "/" .. sdef.slot,
              desc = string.format("%d %s %s items (iLvl Low to High)", count, armorKey, sdef.name),
              count = count,
              icon = sdef.icon,
            }
          })
        end
      else
        for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isInternal = name:find("^OLD") or name:find("^zzOLD") or name:find("^Monster %-") or name:find("^TEST") or name:find("%[PH%]")
        if not isInternal then
          local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
          local matchesFilter = false
          if subName == "One-Handed Axes" and not isRecipe and item.slot == "One-Hand" and item.itemType and item.itemType:find("Axe") then matchesFilter = true
          elseif subName == "Two-Handed Axes" and not isRecipe and item.slot == "Two-Hand" and item.itemType and item.itemType:find("Axe") then matchesFilter = true
          elseif subName == "One-Handed Swords" and not isRecipe and item.slot == "One-Hand" and item.itemType and item.itemType:find("Sword") then matchesFilter = true
          elseif subName == "Two-Handed Swords" and not isRecipe and item.slot == "Two-Hand" and item.itemType and item.itemType:find("Sword") then matchesFilter = true
          elseif subName == "One-Handed Maces" and not isRecipe and item.slot == "One-Hand" and item.itemType and item.itemType:find("Mace") then matchesFilter = true
          elseif subName == "Two-Handed Maces" and not isRecipe and item.slot == "Two-Hand" and item.itemType and item.itemType:find("Mace") then matchesFilter = true
          elseif subName == "Daggers" and not isRecipe and item.itemType and item.itemType:find("Dagger") then matchesFilter = true
          elseif subName == "Polearms" and not isRecipe and item.itemType and item.itemType:find("Polearm") then matchesFilter = true
          elseif subName == "Staves" and not isRecipe and item.itemType and item.itemType:find("Staff") then matchesFilter = true
          elseif subName == "Bows" and not isRecipe and item.itemType and (item.itemType:find("Bow") or item.itemType:find("Crossbow")) then matchesFilter = true
          elseif subName == "Guns" and not isRecipe and item.itemType and item.itemType:find("Gun") then matchesFilter = true
          elseif subName == "Wands" and not isRecipe and item.itemType and item.itemType:find("Wand") then matchesFilter = true
          elseif subName == "Fist Weapons" and not isRecipe and item.itemType and item.itemType:find("Fist") then matchesFilter = true
          elseif subName == "Cloth Armor" and not isRecipe and item.itemType and item.itemType:find("Cloth") then matchesFilter = true
          elseif subName == "Leather Armor" and not isRecipe and item.itemType and item.itemType:find("Leather") then matchesFilter = true
          elseif subName == "Mail Armor" and not isRecipe and item.itemType and item.itemType:find("Mail") then matchesFilter = true
          elseif subName == "Plate Armor" and not isRecipe and item.itemType and item.itemType:find("Plate") then matchesFilter = true
          elseif subName == "Shields" and not isRecipe and item.slot and item.slot:find("Shield") then matchesFilter = true
          elseif subName == "Amulets" and not isRecipe and item.slot and item.slot:find("Neck") then matchesFilter = true
          elseif subName == "Rings" and not isRecipe and item.slot and item.slot:find("Finger") then matchesFilter = true
          elseif subName == "Trinkets" and not isRecipe and item.slot and item.slot:find("Trinket") then matchesFilter = true
          elseif subName == "Cloaks" and not isRecipe and item.slot and item.slot:find("Back") then matchesFilter = true
          elseif subName == "Potions" and item.itemType and (item.itemType:find("Potion") or item.itemType:find("Elixir") or item.itemType:find("Flask")) then matchesFilter = true
          elseif subName == "Food" and item.itemType and item.itemType:find("Food") then matchesFilter = true
          elseif subName == "Bandages" and item.itemType and item.itemType:find("Bandage") then matchesFilter = true
          elseif subName == "Scrolls" and item.itemType and item.itemType:find("Scroll") then matchesFilter = true
          elseif subName == "Herbs" and item.itemType and item.itemType:find("Herb") then matchesFilter = true
          elseif subName == "Ore" and item.itemType and (item.itemType:find("Metal") or item.itemType:find("Stone")) then matchesFilter = true
          elseif subName == "Parts" and item.itemType and (item.itemType:find("Parts") or item.itemType:find("Device")) then matchesFilter = true
          elseif subName == "Reagents" and item.itemType and item.itemType:find("Reagent") then matchesFilter = true
          elseif subName == "All Recipes" and (isRecipe or (item.itemType and item.itemType:find("Recipe"))) then matchesFilter = true
          end

          if matchesFilter then
            table.insert(matches, { type = "item", data = item })
          end
        end
      end
    end
    elseif cur == "creatures/by_zone_ek" and FG.Data.Creatures then
      local zoneCounts = {}
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and c.zone then
          zoneCounts[c.zone] = (zoneCounts[c.zone] or 0) + 1
        end
      end
      for _, zn in ipairs(EK_ZONE_NAMES) do
        local count = zoneCounts[zn] or 0
        table.insert(matches, {
          type = "folder",
          data = {
            name = zn,
            path = "creatures/zone/" .. zn,
            desc = string.format("%d creatures in %s (A to Z)", count, zn),
            count = count,
            icon = "Interface\\Icons\\INV_Misc_Map02",
          }
        })
      end
    elseif cur == "creatures/by_zone_kalimdor" and FG.Data.Creatures then
      local zoneCounts = {}
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and c.zone then
          zoneCounts[c.zone] = (zoneCounts[c.zone] or 0) + 1
        end
      end
      for _, zn in ipairs(KALIMDOR_ZONE_NAMES) do
        local count = zoneCounts[zn] or 0
        table.insert(matches, {
          type = "folder",
          data = {
            name = zn,
            path = "creatures/zone/" .. zn,
            desc = string.format("%d creatures in %s (A to Z)", count, zn),
            count = count,
            icon = "Interface\\Icons\\INV_Misc_Map02",
          }
        })
      end
    elseif cur:find("^creatures/zone/") and FG.Data.Creatures then
      local zoneName = cur:sub(16)
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and c.zone == zoneName then
          table.insert(matches, { type = "creature", data = c })
        end
      end
    elseif cur:find("^creatures/([^/]+)/ek$") and FG.Data.Creatures then
      local fam = cur:match("^creatures/([^/]+)/ek$")
      local zoneCounts = {}
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and CreatureMatchesFamily(c, fam) and c.zone then
          zoneCounts[c.zone] = (zoneCounts[c.zone] or 0) + 1
        end
      end
      for _, zn in ipairs(EK_ZONE_NAMES) do
        local count = zoneCounts[zn] or 0
        if count > 0 then
          table.insert(matches, {
            type = "folder",
            data = {
              name = zn,
              path = "creatures/" .. fam .. "/zone/" .. zn,
              desc = string.format("%d %s in %s (A to Z)", count, fam:gsub("^%l", string.upper), zn),
              count = count,
              icon = "Interface\\Icons\\INV_Misc_Map02",
            }
          })
        end
      end
    elseif cur:find("^creatures/([^/]+)/kalimdor$") and FG.Data.Creatures then
      local fam = cur:match("^creatures/([^/]+)/kalimdor$")
      local zoneCounts = {}
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and CreatureMatchesFamily(c, fam) and c.zone then
          zoneCounts[c.zone] = (zoneCounts[c.zone] or 0) + 1
        end
      end
      for _, zn in ipairs(KALIMDOR_ZONE_NAMES) do
        local count = zoneCounts[zn] or 0
        if count > 0 then
          table.insert(matches, {
            type = "folder",
            data = {
              name = zn,
              path = "creatures/" .. fam .. "/zone/" .. zn,
              desc = string.format("%d %s in %s (A to Z)", count, fam:gsub("^%l", string.upper), zn),
              count = count,
              icon = "Interface\\Icons\\INV_Misc_Map02",
            }
          })
        end
      end
    elseif cur:find("^creatures/([^/]+)/zone/") and FG.Data.Creatures then
      local fam, zoneName = cur:match("^creatures/([^/]+)/zone/(.+)$")
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and CreatureMatchesFamily(c, fam) and c.zone == zoneName then
          table.insert(matches, { type = "creature", data = c })
        end
      end
    elseif cur:find("^creatures/([^/]+)/all$") and FG.Data.Creatures then
      local fam = cur:match("^creatures/([^/]+)/all$")
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and CreatureMatchesFamily(c, fam) then
          table.insert(matches, { type = "creature", data = c })
        end
      end
    elseif cur:find("^creatures/") and FG.Data.Creatures then
      local sub = cur:sub(11)
      local famCap = sub:gsub("^%l", string.upper)
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Eastern Kingdoms (By Zone)",
          path = "creatures/" .. sub .. "/ek",
          desc = string.format("%s in Eastern Kingdoms zones (A to Z)", famCap),
          icon = "Interface\\Icons\\INV_Misc_Map02",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Kalimdor (By Zone)",
          path = "creatures/" .. sub .. "/kalimdor",
          desc = string.format("%s in Kalimdor zones (A to Z)", famCap),
          icon = "Interface\\Icons\\INV_Misc_Map02",
        }
      })
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) and CreatureMatchesFamily(c, sub) then
          table.insert(matches, { type = "creature", data = c })
        end
      end
    elseif cur:find("^dungeons/") and FG.Data.Dungeons then
      local sub = cur:sub(10)
      for _, d in pairs(FG.Data.Dungeons) do
        local pass = false
        local minLvl = d.minLevel or 0
        local maxLvl = d.maxLevel or 60
        if sub == "starter" and minLvl <= 25 and not d.isForever then pass = true
        elseif sub == "mid" and minLvl > 25 and minLvl <= 45 and not d.isForever then pass = true
        elseif sub == "endgame" and minLvl > 45 and not (minLvl == 60 and maxLvl == 60) and not d.isForever then pass = true
        elseif sub == "raids" and minLvl == 60 and maxLvl == 60 and not d.isForever then pass = true
        elseif sub == "forever" and d.isForever then pass = true
        end
        if pass then
          table.insert(matches, { type = "dungeon", data = d })
        end
      end
    elseif cur == "vendors/flightpaths" and FG.Data.Flightpaths then
      for _, fp in pairs(FG.Data.Flightpaths) do
        table.insert(matches, { type = "vendor", data = { name = fp.name, zone = fp.zone, coords = fp.coords, item = fp.faction .. " Flight Master", tip = fp.notes or fp.connections } })
      end
    elseif cur:find("^vendors/") and FG.Data.Vendors then
      for _, v in pairs(FG.Data.Vendors) do
        table.insert(matches, { type = "vendor", data = v })
      end
    elseif cur:find("^forever/") then
      local sub = cur:sub(9)
      if sub == "items" and FG.Data.Items then
        for _, item in pairs(FG.Data.Items) do
          if item.isForever then table.insert(matches, { type = "item", data = item }) end
        end
      elseif sub == "quests" and FG.Data.Quests then
        for _, quest in pairs(FG.Data.Quests) do
          if quest.isForever then table.insert(matches, { type = "quest", data = quest }) end
        end
      elseif sub == "creatures" and FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if c.isForever then table.insert(matches, { type = "creature", data = c }) end
        end
      elseif sub == "dungeons" and FG.Data.Dungeons then
        for _, d in pairs(FG.Data.Dungeons) do
          if d.isForever then table.insert(matches, { type = "dungeon", data = d }) end
        end
      end
    end

  else
    -- Active search query filtered by category
    if (cat == "all" or cat == "items") and FG.Data.Items then
      for _, item in pairs(FG.Data.Items) do
        if item.name and (item.name:lower():find(q, 1, true) or (item.source and item.source:lower():find(q, 1, true))) then
          table.insert(matches, { type = "item", data = item })
        end
      end
    end

    if (cat == "all" or cat == "quests") and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        local matchTitle = quest.title and quest.title:lower():find(q, 1, true)
        local matchNpc = quest.npc and quest.npc:lower():find(q, 1, true)
        local matchZone = quest.zone and quest.zone:lower():find(q, 1, true)
        local matchObj = quest.objectives and quest.objectives:lower():find(q, 1, true)
        local matchTip = quest.tip and quest.tip:lower():find(q, 1, true)
        if matchTitle or matchNpc or matchZone or matchObj or matchTip then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    end

    if (cat == "all" or cat == "creatures") and FG.Data.Creatures then
      for _, c in pairs(FG.Data.Creatures) do
        if not FG:IsInternalCreature(c.name, c.family) then
          local matchName = c.name and c.name:lower():find(q, 1, true)
          local matchZone = c.zone and c.zone:lower():find(q, 1, true)
          local matchLoc = c.location and c.location:lower():find(q, 1, true)
          if matchName or matchZone or matchLoc then
            table.insert(matches, { type = "creature", data = c })
          end
        end
      end
    end

    if (cat == "all" or cat == "dungeons") and FG.Data.Dungeons then
      for _, d in pairs(FG.Data.Dungeons) do
        if d.name and (d.name:lower():find(q, 1, true) or (d.zone and d.zone:lower():find(q, 1, true))) then
          table.insert(matches, { type = "dungeon", data = d })
        end
      end
    end

    if (cat == "all" or cat == "vendors") and FG.Data.Vendors then
      for _, v in pairs(FG.Data.Vendors) do
        local matchName = v.name and v.name:lower():find(q, 1, true)
        local matchItem = v.item and v.item:lower():find(q, 1, true)
        local matchZone = v.zone and v.zone:lower():find(q, 1, true)
        if matchName or matchItem or matchZone then
          table.insert(matches, { type = "vendor", data = v })
        end
      end
    end
  end

  -- Sorting:
  -- 1. Folders always come first, sorted alphabetically A-Z.
  -- 2. Items & Item Subsets: sorted by item level (iLvl) ascending (lowest at top, highest at bottom).
  --    If iLvl is tied, sort alphabetically A-Z.
  -- 3. All other categories: sorted strictly alphabetically A-Z.
  local isItemView = (cur:find("^items") ~= nil) or (cat == "items") or (cur:find("^forever/items") ~= nil)
  table.sort(matches, function(a, b)
    if a.type == "folder" and b.type ~= "folder" then return true end
    if a.type ~= "folder" and b.type == "folder" then return false end
    if a.type == "folder" and b.type == "folder" then
      local nameA = (a.data and (a.data.title or a.data.name or "")) or ""
      local nameB = (b.data and (b.data.title or b.data.name or "")) or ""
      return nameA:lower() < nameB:lower()
    end

    if isItemView and a.type == "item" and b.type == "item" then
      local ilvlA = tonumber(a.data and a.data.ilvl) or 0
      local ilvlB = tonumber(b.data and b.data.ilvl) or 0
      if ilvlA ~= ilvlB then
        return ilvlA < ilvlB
      end
    end

    local nameA = (a.data and (a.data.title or a.data.name or "")) or ""
    local nameB = (b.data and (b.data.title or b.data.name or "")) or ""
    return nameA:lower() < nameB:lower()
  end)

  FG:UpdateDolphinBreadcrumbs(q, #matches)

  if #matches == 0 then
    if content.NoResultsState then
      content.NoResultsState:Show()
      if content.NoResultsState.Title then
        if cur == "nearby" or cat == "nearby" then
          local pZone = FG:GetPlayerZoneInfo()
          content.NoResultsState.Title:SetText("|cffff8080No nearby intel found in " .. pZone .. "|r")
        else
          content.NoResultsState.Title:SetText("|cffff8080No results found for \"|r|cffffffff" .. (query or "") .. "|r|cffff8080\"|r")
        end
      end
    end
    for _, btn in ipairs(content.RowPool or {}) do btn:Hide() end
    content:SetHeight(420)
    if cw and cw.StatusText then cw.StatusText:SetText("|cffff80800 results found|r") end
    return
  else
    if content.NoResultsState then content.NoResultsState:Hide() end
    local countStr = FG:FormatNumber(#matches)
    if cw and cw.StatusText then
      local folderCount = 0
      local itemCount = 0
      local questCount = 0
      local creatureCount = 0
      local dungeonCount = 0
      for _, m in ipairs(matches) do
        if m.type == "folder" then
          folderCount = folderCount + 1
        elseif m.type == "item" then
          itemCount = itemCount + 1
        elseif m.type == "quest" then
          questCount = questCount + 1
        elseif m.type == "creature" then
          creatureCount = creatureCount + 1
        elseif m.type == "dungeon" then
          dungeonCount = dungeonCount + 1
        end
      end

      if cur == "nearby" or cat == "nearby" then
        cw.StatusText:SetText("|cff20ff20" .. countStr .. " nearby points of interest (" .. (FG.lastKnownZone or "Local Area") .. ")|r")
      elseif folderCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " categories in view (A-Z)|r")
      elseif itemCount == #matches then
        if isItemView or cat == "items" then
          cw.StatusText:SetText("|cffdf80ff" .. countStr .. " items in view (iLvl: Lowest to Highest)|r")
        else
          cw.StatusText:SetText("|cffdf80ff" .. countStr .. " items in view (A-Z)|r")
        end
      elseif questCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " quests in view (A-Z)|r")
      elseif creatureCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " creatures in view (A-Z)|r")
      elseif dungeonCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " dungeons & raids in view (A-Z)|r")
      elseif folderCount > 0 and itemCount > 0 and (folderCount + itemCount == #matches) then
        cw.StatusText:SetText("|cffdf80ff" .. folderCount .. " categories, " .. itemCount .. " items in view|r")
      else
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " results in view (A-Z)|r")
      end
    end
  end

  FG.currentMatches = matches
  local totalHeight = math.max(420, #matches * 54)
  content:SetHeight(totalHeight)
  if scrollFrame then scrollFrame:SetVerticalScroll(0) end
  FG:UpdateVirtualRows()
end

function FG:PopulateDungeons()
  FG:NavigateToFolder("dungeons")
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
EventFrame:RegisterEvent("ZONE_CHANGED")
EventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
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

-- Dynamic Game Interactivity: Player Death, Resurrection & Level Up
EventFrame:RegisterEvent("PLAYER_DEAD")
EventFrame:RegisterEvent("PLAYER_ALIVE")
EventFrame:RegisterEvent("PLAYER_UNGHOST")
EventFrame:RegisterEvent("PLAYER_LEVEL_UP")

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

    print("|cffcf52ffForever Guide|r |cffdf80ff(Sparky)|r |cffff8080[Pre-Alpha v0.1.0]|r loaded! Type |cffdf80ff/sparky|r to open Codex or |cffdf80ff/sparky help|r for commands.")

  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Guarantee any stray cursor dragging state is stopped on world load
    if FG.SparkFrame and FG.SparkFrame.StopMovingOrSizing then
      FG.SparkFrame:StopMovingOrSizing()
      FG.SparkFrame.isMoving = false
      FG.SparkFrame.wasDragged = false
    end
    FG:UpdateSparkMouseState()
    local initZone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
    if initZone ~= "" then FG.lastKnownZone = initZone end

  -- NPC Interaction: Auto-hide Codex window so NPC quest dialogue is 100% visible and accessible
  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_DETAIL" or
         event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "MERCHANT_SHOW" or
         event == "TAXIMAP_OPENED" then
    if FG.CodexWindow and FG.CodexWindow:IsShown() then
      FG.CodexWindow:Hide()
    end

  elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
    local newZone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
    if newZone ~= "" then FG.lastKnownZone = newZone end
    if FG.CodexWindow and FG.CodexWindow:IsShown() and FG.activeCategory == "nearby" then
      FG:PopulateCodexResults(ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or "")
    end
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

  elseif event == "PLAYER_DEAD" then
    -- Interactive death reaction: Sparky dashes to screen edge and bounces!
    if FG.SparkFrame and FG.SparkFrame.TransitionTo then
      FG.SparkFrame:TransitionTo("DEATH_BOUNCE")
    end

  elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    if FG.SparkFrame and FG.SparkFrame.flightState == "DEATH_BOUNCE" and FG.SparkFrame.TransitionTo then
      FG.SparkFrame:TransitionTo("CELEBRATE")
    end

  elseif event == "PLAYER_LEVEL_UP" then
    if FG.SparkFrame and FG.SparkFrame.TransitionTo then
      FG.SparkFrame:TransitionTo("CELEBRATE")
    end
  end
end)

