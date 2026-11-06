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
  f:SetSize(48, 48)
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
  visual:SetSize(34, 34)
  visual:SetPoint("CENTER", f, "CENTER", 0, 0)
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
  aura:SetSize(54, 54)
  aura:SetVertexColor(0.55, 0.12, 0.85, 0.40)
  f.Aura = aura

  -- Layer 2: Billowing Cloud Lobe A (Asymmetric puff, rotates counter-clockwise)
  local cloudA = visual:CreateTexture(nil, "BORDER")
  cloudA:SetTexture(TEX_CLOUD_MAIN)
  cloudA:SetBlendMode("ADD")
  cloudA:SetPoint("CENTER", visual, "CENTER", -1.8, 1.2)
  cloudA:SetSize(44, 44)
  cloudA:SetVertexColor(0.72, 0.20, 0.98, 0.65)
  f.CloudA = cloudA

  local rotAgA = visual:CreateAnimationGroup()
  local rotAnimA = rotAgA:CreateAnimation("Rotation")
  rotAnimA:SetDegrees(360)
  rotAnimA:SetDuration(14.0)
  rotAgA:SetLooping("REPEAT")
  rotAgA:Play()
  f.RotAnimGroupA = rotAgA

  -- Layer 3: Billowing Counter Cloud Lobe B (Opposite rotation constantly morphs silhouette)
  local cloudB = visual:CreateTexture(nil, "ARTWORK")
  cloudB:SetTexture(TEX_CLOUD_MAIN)
  cloudB:SetBlendMode("ADD")
  cloudB:SetPoint("CENTER", visual, "CENTER", 2.0, -1.4)
  cloudB:SetSize(38, 38)
  cloudB:SetVertexColor(0.82, 0.30, 1.00, 0.60)
  f.CloudB = cloudB

  local rotAgB = visual:CreateAnimationGroup()
  local rotAnimB = rotAgB:CreateAnimation("Rotation")
  rotAnimB:SetDegrees(-360)
  rotAnimB:SetDuration(10.0)
  rotAgB:SetLooping("REPEAT")
  rotAgB:Play()
  f.RotAnimGroupB = rotAgB

  -- Layer 4: Twisting Vapor Tendril Wisp (Curling smoke plume wafts through the cloud)
  local wispTendril = visual:CreateTexture(nil, "ARTWORK", nil, 1)
  wispTendril:SetTexture(TEX_CLOUD_WISP)
  wispTendril:SetBlendMode("ADD")
  wispTendril:SetPoint("CENTER", visual, "CENTER", 0, 0)
  wispTendril:SetSize(42, 42)
  wispTendril:SetVertexColor(0.90, 0.45, 1.00, 0.75)
  f.WispTendril = wispTendril

  local rotAgW = visual:CreateAnimationGroup()
  local rotAnimW = rotAgW:CreateAnimation("Rotation")
  rotAnimW:SetDegrees(360)
  rotAnimW:SetDuration(7.0)
  rotAgW:SetLooping("REPEAT")
  rotAgW:Play()
  f.RotAnimGroupW = rotAgW

  -- Layer 5: Nebulous Heart Mist (Soft, uneven spirit smoke center - NOT a geometric shape)
  local cloudCore = visual:CreateTexture(nil, "OVERLAY")
  cloudCore:SetTexture(TEX_CLOUD_CORE)
  cloudCore:SetBlendMode("ADD")
  cloudCore:SetPoint("CENTER", visual, "CENTER", 0, 0)
  cloudCore:SetSize(28, 28)
  cloudCore:SetVertexColor(0.95, 0.65, 1.00, 0.85)
  f.CloudCore = cloudCore

  -- Layer 6: Drifting Satellite Vapor Puffs (Organic smoky eddies trailing around the wisp)
  local puff1 = visual:CreateTexture(nil, "OVERLAY", nil, 1)
  puff1:SetTexture(TEX_CLOUD_PUFF)
  puff1:SetBlendMode("ADD")
  puff1:SetSize(13, 13)
  puff1:SetVertexColor(0.85, 0.35, 1.0, 0.70)
  f.Puff1 = puff1

  local puff2 = visual:CreateTexture(nil, "OVERLAY", nil, 1)
  puff2:SetTexture(TEX_CLOUD_PUFF)
  puff2:SetBlendMode("ADD")
  puff2:SetSize(11, 11)
  puff2:SetVertexColor(0.75, 0.25, 0.95, 0.60)
  f.Puff2 = puff2

  local puff3 = visual:CreateTexture(nil, "OVERLAY", nil, 1)
  puff3:SetTexture(TEX_CLOUD_PUFF)
  puff3:SetBlendMode("ADD")
  puff3:SetSize(9, 9)
  puff3:SetVertexColor(0.95, 0.55, 1.0, 0.65)
  f.Puff3 = puff3

  -- Breathing Alpha Pulse
  local ag = visual:CreateAnimationGroup()
  local alphaAnim = ag:CreateAnimation("Alpha")
  alphaAnim:SetFromAlpha(0.82)
  alphaAnim:SetToAlpha(1.0)
  alphaAnim:SetDuration(1.8)
  alphaAnim:SetSmoothing("IN_OUT")
  ag:SetLooping("BOUNCE")
  ag:Play()
  f.AnimGroup = ag

  -- =========================================================================
  -- SPARKY AUTONOMOUS AI & 120FPS FLUID MOTION ENGINE
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
  local stateDuration = 1.4 + math.random() * 1.8 -- Active 1.4-3.2s rest before next graceful glide

  -- Float & Roam Parameters
  local travelStartX, travelStartY = currentPosX, currentPosY
  local travelTargetX, travelTargetY = currentPosX, currentPosY
  local travelCtrlX, travelCtrlY = currentPosX, currentPosY
  local travelDuration = 1.4
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
    return 55, sw - 55, 55, sh - 55
  end

  local function PickNeighborhoodPoint()
    wanderCycle = wanderCycle + 1
    local minX, maxX, minY, maxY = GetScreenBounds()

    local radius
    if wanderCycle % 4 == 0 then
      -- Venturing out a bit! (80 to 130px away from home)
      radius = 80 + math.random() * 50
    else
      -- Active gentle wander around home anchor (20 to 55px away)
      radius = 20 + math.random() * 35
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

    -- Fluid, organic wisp glide (50 to 90 px/sec) - snappy and lively
    travelDuration = math.max(1.1, math.min(2.1, 0.7 + (dist / 55.0)))

    -- Subtle organic curve
    local midX = (travelStartX + travelTargetX) * 0.5
    local midY = (travelStartY + travelTargetY) * 0.5
    local perpX = -dy / dist
    local perpY = dx / dist
    local curveDist = (math.random() > 0.5 and 1 or -1) * (12 + math.random() * 28)
    travelCtrlX = midX + perpX * curveDist
    travelCtrlY = midY + perpY * curveDist
  end

  function f:TransitionTo(newState)
    flightState = newState
    self.flightState = newState
    stateTimer = 0

    if newState == "RESTING" then
      stateDuration = 1.4 + math.random() * 1.8 -- Rest 1.4 to 3.2 seconds
      if visual then visual:SetSize(34, 34) end

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
      stateDuration = 1.4
      StartGentleFloat(anchorX, anchorY + 35)
    end
  end

  local function OnOrbUpdate(self, elapsed)
    local dt = math.min(elapsed, 0.033) -- Supports high-refresh displays up to 120Hz/144Hz smoothly
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
      -- Multi-harmonic stationary breathing at spawn point
      local waveX = math.sin(t * 0.8) * 3.0 + math.cos(t * 1.6) * 1.0
      local waveY = math.cos(t * 0.65) * 3.0 + math.sin(t * 1.4) * 1.0
      currentPosX = anchorX + waveX
      currentPosY = anchorY + waveY

    elseif flightState == "RESTING" then
      -- Multi-frequency ethereal harmonic hover (120fps fluid feel)
      stateTimer = stateTimer + dt
      local bobX = math.sin(t * 1.5) * 3.5 + math.sin(t * 0.7) * 1.8 + math.cos(t * 2.8) * 0.8
      local bobY = math.cos(t * 1.3) * 3.2 + math.sin(t * 0.55) * 1.6 + math.sin(t * 3.1) * 0.9
      currentPosX = travelTargetX + bobX
      currentPosY = travelTargetY + bobY

      -- Take another lively float around home
      if stateTimer >= stateDuration and ForeverGuideDB.hasInteracted then
        f:TransitionTo("WANDER")
      end

    elseif flightState == "WANDER" then
      travelElapsed = travelElapsed + dt
      local p = math.min(1.0, travelElapsed / travelDuration)

      -- Quintic smootherstep easing (6p^5 - 15p^4 + 10p^3) for butter-smooth acceleration & deceleration
      local u = p * p * p * (p * (p * 6 - 15) + 10)
      local invU = 1.0 - u

      local bX = invU * invU * travelStartX + 2 * invU * u * travelCtrlX + u * u * travelTargetX
      local bY = invU * invU * travelStartY + 2 * invU * u * travelCtrlY + u * u * travelTargetY

      local ripple = math.sin(p * math.pi * 2) * 2.8
      currentPosX = bX
      currentPosY = bY + ripple

      if p >= 1.0 then
        f:TransitionTo("RESTING")
      end

    elseif flightState == "ZIG_ZAG" then
      travelElapsed = travelElapsed + dt
      local p = math.min(1.0, travelElapsed / travelDuration)
      local u = p * p * p * (p * (p * 6 - 15) + 10)
      currentPosX = travelStartX + (travelTargetX - travelStartX) * u + math.sin(p * math.pi * 2) * 10
      currentPosY = travelStartY + (travelTargetY - travelStartY) * u + math.cos(p * math.pi * 2) * 7
      if p >= 1.0 then
        f:TransitionTo("RESTING")
      end

    elseif flightState == "DEATH_BOUNCE" then
      deathBounceTimer = deathBounceTimer + dt
      local minX, maxX, minY, maxY = GetScreenBounds()
      local targetEdgeX = (deathBounceSide == "RIGHT") and (maxX - 18) or (minX + 18)

      -- Smooth glide to screen side
      currentPosX = currentPosX + (targetEdgeX - currentPosX) * math.min(1.0, dt * 7.5)

      local bouncePeriod = 0.46
      local phase = (deathBounceTimer % bouncePeriod) / bouncePeriod
      local bounceHeight = 175 + math.sin(deathBounceTimer * 2.4) * 35
      local groundY = minY + 55
      local arc = 4 * phase * (1 - phase)
      currentPosY = groundY + arc * bounceHeight

      local wallKick = math.sin(phase * math.pi) * 18
      currentPosX = targetEdgeX + ((deathBounceSide == "RIGHT") and -wallKick or wallKick)

      if phase < 0.12 or phase > 0.88 then
        visual:SetSize(42, 24) -- Squashed on impact
        if self.Aura then self.Aura:SetVertexColor(1.0, 0.30, 0.95, 0.90) end
      else
        visual:SetSize(26, 42) -- Stretched tall
        if self.Aura then self.Aura:SetVertexColor(0.78, 0.22, 1.0, 0.70) end
      end

      if not UnitIsDeadOrGhost("player") then
        f:TransitionTo("CELEBRATE")
      end

    elseif flightState == "CELEBRATE" then
      stateTimer = stateTimer + dt
      travelElapsed = travelElapsed + dt
      local p = math.min(1.0, travelElapsed / travelDuration)
      local u = p * p * p * (p * (p * 6 - 15) + 10)
      local invU = 1.0 - u
      currentPosX = invU * travelStartX + u * anchorX + math.sin(p * math.pi * 3) * 22
      currentPosY = invU * travelStartY + u * anchorY + math.cos(p * math.pi * 3) * 18

      if p >= 1.0 or stateTimer >= stateDuration then
        f:TransitionTo("RESTING")
      end
    end

    -- Smooth velocity tracking & subtle wisp tilt / stretch
    currentVelX = (currentPosX - lastPosX) / (dt > 0.0001 and dt or 0.01)
    currentVelY = (currentPosY - lastPosY) / (dt > 0.0001 and dt or 0.01)
    lastPosX, lastPosY = currentPosX, currentPosY
    local speedMag = math.sqrt(currentVelX * currentVelX + currentVelY * currentVelY)

    if flightState ~= "DEATH_BOUNCE" then
      local stretch = math.min(0.24, (speedMag / 350) * 0.24)
      visual:SetSize(34 * (1.0 + stretch), 34 / (1.0 + stretch * 0.45))
    end

    -- Fluid spring-damper trailing for satellite vapor puffs (120fps responsive)
    local lagFactor = math.min(1.0, dt * 18.0)
    local targetLagX = -currentVelX * 0.030
    local targetLagY = -currentVelY * 0.030
    puff1LagX = puff1LagX + (targetLagX - puff1LagX) * lagFactor
    puff1LagY = puff1LagY + (targetLagY - puff1LagY) * lagFactor

    if self.Puff1 then
      local p1R = 15 + math.sin(t * 1.4) * 4.0
      local p1X = math.cos(t * 2.4) * p1R + puff1LagX * 0.6
      local p1Y = math.sin(t * 2.4) * (p1R * 0.75) + puff1LagY * 0.6
      self.Puff1:SetPoint("CENTER", visual, "CENTER", p1X, p1Y)
    end
    if self.Puff2 then
      local p2R = 12 + math.cos(t * 1.6) * 3.2
      local p2X = math.cos(-t * 2.0 + 2.1) * p2R + puff1LagX * 0.8
      local p2Y = math.sin(-t * 2.0 + 2.1) * (p2R * 0.8) + puff1LagY * 0.8
      self.Puff2:SetPoint("CENTER", visual, "CENTER", p2X, p2Y)
    end
    if self.Puff3 then
      local p3R = 9 + math.sin(t * 1.8 + 1.2) * 2.5
      local p3X = math.sin(t * 1.7 + 4.0) * p3R + puff1LagX * 1.0
      local p3Y = math.cos(t * 1.7 + 4.0) * (p3R * 0.65) + puff1LagY * 1.0
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

function FG:GetPlayerCoords()
  local px, py = nil, nil
  if GetPlayerMapPosition then
    px, py = GetPlayerMapPosition("player")
  end
  if (not px or (px == 0 and py == 0)) and C_Map and C_Map.GetPlayerMapPosition and C_Map.GetBestMapForUnit then
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
      local pos = C_Map.GetPlayerMapPosition(mapID, "player")
      if pos then
        px, py = pos:GetXY()
      end
    end
  end
  if px and py and (px > 0 or py > 0) then
    return px * 100, py * 100
  end
  return nil, nil
end

function FG:GetDistanceAndBearing(coordStr)
  if not coordStr or coordStr == "" then return nil, nil, nil end
  local cx, cy = coordStr:match("(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
  if not cx or not cy then return nil, nil, nil end
  cx = tonumber(cx)
  cy = tonumber(cy)
  if not cx or not cy then return nil, nil, nil end

  local px, py = FG:GetPlayerCoords()
  if not px or not py then
    return nil, nil, string.format("[%0.1f, %0.1f]", cx, cy), cx, cy
  end

  local dx = cx - px
  local dy = cy - py
  local distPct = math.sqrt(dx * dx + dy * dy)
  local distYards = math.floor(distPct * 35)

  local bearing = ""
  if dy < -1.0 then bearing = "N" elseif dy > 1.0 then bearing = "S" end
  if dx > 1.0 then bearing = bearing .. "E" elseif dx < -1.0 then bearing = bearing .. "W" end
  if bearing == "" then bearing = "Nearby" end

  local distStr = ""
  if distYards < 60 then
    distStr = "Right here (<60yd)"
  elseif distYards < 1500 then
    distStr = string.format("~%d yd %s", distYards, bearing)
  else
    distStr = string.format("~%0.1f mi %s", distYards / 1760, bearing)
  end

  return distPct, distYards, distStr, cx, cy
end

function FG:TrackEntityCoords(name, zone, coords)
  if not coords or coords == "" then
    print(string.format("|cffdf80ff[Sparky Radar]|r %s location coordinates are not specified.", name or "Target"))
    return
  end
  local cx, cy = coords:match("(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
  if not cx or not cy then return end
  cx = tonumber(cx)
  cy = tonumber(cy)

  local _, _, distStr = FG:GetDistanceAndBearing(coords)
  local distMsg = distStr and (" (" .. distStr .. ")") or ""
  print(string.format("|cffdf80ff[Sparky Radar]|r Tracking |cffffffff%s|r at |cff38bdf8[%0.1f, %0.1f]|r in |cffcf52ff%s|r%s.", name or "Target", cx, cy, zone or (FG.currentZone or "Current Zone"), distMsg))

  if TomTom and TomTom.AddWaypoint then
    local mZone = zone or GetZoneText()
    TomTom:AddWaypoint(mZone, cx, cy, { title = name })
  elseif C_Map and C_Map.SetUserWaypoint and C_Map.GetBestMapForUnit and UiMapPoint then
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
      local pt = UiMapPoint.CreateFromCoordinates(mapID, cx / 100, cy / 100)
      C_Map.SetUserWaypoint(pt)
    end
  end
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
  btn:EnableMouse(true)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
  titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
  titleText:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
  titleText:SetJustifyH("LEFT")
  titleText:SetWordWrap(false)
  SharpenFontString(titleText, 12, "OUTLINE")
  btn.Title = titleText

  local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
  subText:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
  subText:SetHeight(15)
  subText:SetJustifyH("LEFT")
  subText:SetWordWrap(false)
  SharpenFontString(subText, 10.5, "OUTLINE")
  btn.Sub = subText

  local inspectBtn = CreateFrame("Button", nil, btn, "BackdropTemplate")
  inspectBtn:SetSize(68, 26)
  inspectBtn:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
  inspectBtn:EnableMouse(true)
  inspectBtn:RegisterForClicks("LeftButtonUp")
  MakePixelSharp(inspectBtn)
  inspectBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  inspectBtn:SetBackdropColor(0.18, 0.14, 0.28, 0.90)
  inspectBtn:SetBackdropBorderColor(0.45, 0.35, 0.65, 0.90)

  local hint = inspectBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("CENTER", inspectBtn, "CENTER", 0, 0)
  hint:SetText("|cffcf52ffInspect >|r")
  SharpenFontString(hint, 10, "OUTLINE")
  inspectBtn.Text = hint
  btn.InspectBtn = inspectBtn
  btn.Hint = hint

  inspectBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.30, 0.20, 0.50, 0.98)
    self:SetBackdropBorderColor(0.80, 0.50, 1.0, 1.0)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:AddLine("|cffdf80ffInspect Intel|r", 1, 1, 1)
    GameTooltip:AddLine("Click to view full detail, tactics, drops & coordinates.", 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
  end)
  inspectBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.18, 0.14, 0.28, 0.90)
    self:SetBackdropBorderColor(0.45, 0.35, 0.65, 0.90)
    GameTooltip:Hide()
  end)
  inspectBtn:SetScript("OnClick", function(self)
    if self.onClick then
      self.onClick()
    elseif self.entityType and self.entityData then
      FG:ShowDetailPanel(self.entityType, self.entityData)
      FG:PlaySparkSound("shimmer")
    end
  end)

  return btn
end

--------------------------------------------------------------------------------
-- Dynamic Icon Resolvers
--------------------------------------------------------------------------------
local DUNGEON_ICONS = {
  ["ragefire chasm"] = "Interface\\Icons\\Spell_Fire_Immolation",
  ["the deadmines"] = "Interface\\Icons\\INV_Helmet_66",
  ["deadmines"] = "Interface\\Icons\\INV_Helmet_66",
  ["wailing caverns"] = "Interface\\Icons\\Spell_Nature_HealingTouch",
  ["shadowfang keep"] = "Interface\\Icons\\Spell_Shadow_Haunting",
  ["blackfathom deeps"] = "Interface\\Icons\\Spell_Frost_FrostArmor",
  ["the stockade"] = "Interface\\Icons\\INV_Crate_01",
  ["stockade"] = "Interface\\Icons\\INV_Crate_01",
  ["gnomeregan"] = "Interface\\Icons\\INV_Gizmo_02",
  ["scarlet monastery"] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
  ["razorfen kraul"] = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
  ["razorfen downs"] = "Interface\\Icons\\Spell_Shadow_RaiseDead",
  ["uldaman"] = "Interface\\Icons\\INV_Misc_Statue_01",
  ["zul'farrak"] = "Interface\\Icons\\INV_Mask_02",
  ["maraudon"] = "Interface\\Icons\\Spell_Nature_Earthquake",
  ["sunken temple"] = "Interface\\Icons\\INV_Misc_Head_Dragon_Green",
  ["the temple of atal'hakkar"] = "Interface\\Icons\\INV_Misc_Head_Dragon_Green",
  ["blackrock depths"] = "Interface\\Icons\\Spell_Fire_LavaSpawn",
  ["lower blackrock spire"] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  ["upper blackrock spire"] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  ["stratholme"] = "Interface\\Icons\\Spell_Fire_SelfDestruct",
  ["scholomance"] = "Interface\\Icons\\Spell_Shadow_ShadowPact",
  ["dire maul"] = "Interface\\Icons\\Spell_Arcane_PortalDarnassus",
  ["molten core"] = "Interface\\Icons\\Spell_Fire_Incinerate",
  ["onyxia's lair"] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  ["blackwing lair"] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  ["zul'gurub"] = "Interface\\Icons\\INV_ZulGurubTrinket",
  ["ruins of ahn'qiraj"] = "Interface\\Icons\\INV_Misc_AhnQirajTrinket_01",
  ["temple of ahn'qiraj"] = "Interface\\Icons\\INV_Misc_AhnQirajTrinket_01",
  ["naxxramas"] = "Interface\\Icons\\Spell_Shadow_Haunting",
  ["hall of thanes"] = "Interface\\Icons\\INV_Mace_03",
  ["ruins of lordaeron"] = "Interface\\Icons\\Spell_Shadow_Haunting",
}

function FG:GetDungeonIcon(d)
  if not d then return "Interface\\Icons\\Spell_Holy_PrayerOfFortitude" end
  local n = (d.name or ""):lower()
  if DUNGEON_ICONS[n] then return DUNGEON_ICONS[n] end
  for key, icon in pairs(DUNGEON_ICONS) do
    if n:find(key, 1, true) then return icon end
  end
  return "Interface\\Icons\\Spell_Holy_PrayerOfFortitude"
end

function FG:GetVendorIcon(v)
  if not v then return "Interface\\Icons\\INV_Misc_Coin_01" end
  local item = (v.item or ""):lower()
  local name = (v.name or ""):lower()
  local cat = (v.category or ""):lower()
  local desc = item .. " " .. name .. " " .. cat

  if desc:find("flight") or desc:find("gryphon") or desc:find("wind rider") or desc:find("hippogryph") then return "Interface\\Icons\\Spell_Magic_FeatherFall" end
  if desc:find("pvp") or desc:find("honor") or desc:find("arena") then return "Interface\\Icons\\INV_BannerPVP_02" end
  if desc:find("innkeeper") then return "Interface\\Icons\\INV_Drink_05" end
  if desc:find("repair") or desc:find("blacksmith") or desc:find("anvil") or desc:find("armorsmith") or desc:find("weaponsmith") then return "Interface\\Icons\\Trade_BlackSmithing" end
  if desc:find("weapon") or desc:find("blade") or desc:find("sword") or desc:find("bow") or desc:find("gun") or desc:find("axe") or desc:find("mace") or desc:find("dagger") or desc:find("staff") then return "Interface\\Icons\\INV_Sword_04" end
  if desc:find("armor") or desc:find("shield") or desc:find("cloth") or desc:find("leather") or desc:find("plate") or desc:find("mail") then return "Interface\\Icons\\INV_Chest_Cloth_23" end
  if desc:find("food") or desc:find("drink") or desc:find("meat") or desc:find("bread") or desc:find("ale") or desc:find("wine") or desc:find("cheese") or desc:find("fish") or desc:find("ration") then return "Interface\\Icons\\INV_Misc_Food_15" end
  if desc:find("reagent") or desc:find("poison") or desc:find("potion") or desc:find("alchemy") or desc:find("elixir") or desc:find("vial") then return "Interface\\Icons\\INV_Potion_33" end
  if desc:find("recipe") or desc:find("pattern") or desc:find("schematic") or desc:find("formula") or desc:find("plans") or desc:find("manual") or desc:find("tome") or desc:find("book") then return "Interface\\Icons\\INV_Scroll_03" end
  if desc:find("ammo") or desc:find("arrow") or desc:find("bullet") or desc:find("shot") then return "Interface\\Icons\\INV_Weapon_Bow_05" end
  if desc:find("mechanostrider") then return "Interface\\Icons\\Ability_Mount_MechaStrider" end
  if desc:find("mount") or desc:find("ram") or desc:find("horse") or desc:find("kodo") or desc:find("strider") or desc:find("saber") or desc:find("wolf") or desc:find("raptor") or desc:find("steed") then return "Interface\\Icons\\Ability_Mount_MountainRam" end
  if desc:find("engineer") or desc:find("parts") or desc:find("tinkering") or desc:find("gizmo") then return "Interface\\Icons\\Trade_Engineering" end
  if desc:find("tailor") or desc:find("thread") or desc:find("ribbon") then return "Interface\\Icons\\Trade_Tailoring" end
  if desc:find("leather") or desc:find("hide") or desc:find("tanner") then return "Interface\\Icons\\Trade_LeatherWorking" end
  if desc:find("mining") or desc:find("ore") or desc:find("smelt") then return "Interface\\Icons\\Trade_Mining" end
  if desc:find("herbal") or desc:find("herb") then return "Interface\\Icons\\Trade_Herbalism" end
  if desc:find("bag") or desc:find("container") or desc:find("pouch") or desc:find("sack") then return "Interface\\Icons\\INV_Misc_Bag_08" end

  -- Default vendor icon: Authentic Blizzard gold coin commerce icon! NEVER empty brown backpack!
  return "Interface\\Icons\\INV_Misc_Coin_01"
end

function FG:GetVendorTitle(c)
  if not c or not c.location or c.location == "" then return nil end
  local loc = c.location
  local title = loc:match("^%s*<([^>]+)>%s*$") or loc
  local t_lower = title:lower()
  if t_lower == "reuse me" or t_lower == "dwarven mortar team" or t_lower == "the argent dawn" or t_lower == "the night watch" or t_lower == "scarlet crusade" or t_lower == "defias brotherhood" then
    return nil
  end
  if t_lower:find("merchant") or t_lower:find("supplies") or t_lower:find("vendor") or t_lower:find("trader") or t_lower:find("tradesman")
     or t_lower:find("innkeeper") or t_lower:find("stable master") or t_lower:find("blacksmith") or t_lower:find("weaponsmith")
     or t_lower:find("armorsmith") or t_lower:find("armorer") or t_lower:find("gunsmith") or t_lower:find("bowyer")
     or t_lower:find("tailor") or t_lower:find("leatherwork") or t_lower:find("alchemist") or t_lower:find("herbal")
     or t_lower:find("engineer") or t_lower:find("mining") or t_lower:find("smelter") or t_lower:find("cook")
     or t_lower:find("baker") or t_lower:find("butcher") or t_lower:find("fish") or t_lower:find("first aid")
     or t_lower:find("physician") or t_lower:find("healer") or t_lower:find("reagent") or t_lower:find("poison")
     or t_lower:find("potion") or t_lower:find("ale") or t_lower:find("wine") or t_lower:find("drink")
     or t_lower:find("food") or t_lower:find("bartender") or t_lower:find("trainer") or t_lower:find("breeder")
     or t_lower:find("goods") or t_lower:find("quartermaster") or t_lower:find("banker") or t_lower:find("auctioneer")
     or t_lower:find("flight master") or t_lower:find("gryphon master") or t_lower:find("wind rider master") or t_lower:find("bat handler") then
    return title
  end
  return nil
end

function FG:GetQuestIcon(qData)
  if not qData then return "Interface\\Icons\\inv_misc_book_07" end
  if qData.isForever then return "Interface\\Icons\\INV_Misc_Book_09" end
  local zone = (qData.zone or ""):lower()
  local title = (qData.title or ""):lower()
  if zone:find("dungeon") or zone:find("deadmines") or zone:find("wailing") or zone:find("shadowfang") or zone:find("blackfathom") or zone:find("gnomeregan") or zone:find("scarlet") or zone:find("razorfen") or zone:find("uldaman") or zone:find("zul'") or zone:find("maraudon") or zone:find("blackrock") or zone:find("stratholme") or zone:find("scholomance") or zone:find("dire maul") or zone:find("molten") or zone:find("ahn'qiraj") or zone:find("naxxramas") then
    return "Interface\\Icons\\Spell_Holy_PrayerOfFortitude"
  end
  if title:find("wanted") or title:find("slay") or title:find("kill") or title:find("destroy") or title:find("death to") then
    return "Interface\\Icons\\Ability_Hunter_Assassinate"
  end
  if title:find("delivery") or title:find("report to") or title:find("letter") or title:find("message") or title:find("dispatch") then
    return "Interface\\Icons\\INV_Letter_15"
  end
  return "Interface\\Icons\\inv_misc_book_07"
end

function FG:GetQuestStatus(questID, questTitle)
  local id = tonumber(questID)
  local isCompleted = false
  if id and id > 0 then
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
      isCompleted = C_QuestLog.IsQuestFlaggedCompleted(id)
    elseif IsQuestFlaggedCompleted then
      isCompleted = IsQuestFlaggedCompleted(id)
    end
  end

  if isCompleted then
    return "completed"
  end

  -- Check active quest log in client
  if id and id > 0 and C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(id) then
    if C_QuestLog.IsComplete and C_QuestLog.IsComplete(id) then
      return "ready_to_turn_in"
    end
    return "active"
  end

  if GetNumQuestLogEntries then
    local numEntries = GetNumQuestLogEntries()
    for i = 1, numEntries do
      local title, _, _, isHeader, _, isComplete, _, qID = GetQuestLogTitle(i)
      if not isHeader then
        if (id and qID and qID == id) or (questTitle and title and title:lower() == questTitle:lower()) then
          if isComplete and isComplete > 0 then
            return "ready_to_turn_in"
          else
            return "active"
          end
        end
      end
    end
  end

  return "uncompleted"
end

function FG:GetCreatureIcon(c)
  if not c then return "Interface\\Icons\\INV_Misc_Head_Human_01" end

  local cl = (c.classification or ""):lower()
  if cl == "boss" or cl == "world boss" then
    return "Interface\\Icons\\INV_Misc_Head_Dragon_01"
  end
  if cl == "rare" or cl == "rare elite" then
    return "Interface\\Icons\\INV_Misc_Head_Dragon_02"
  end

  local loc = (c.location or ""):lower()
  local name = (c.name or ""):lower()
  local fam = (c.family or ""):lower()
  local zone = (c.zone or ""):lower()
  if zone == "" and FG.currentZone then
    zone = FG.currentZone:lower()
  end

  -- 1. High-priority role & combat specializations (Mortar, Bomb, Rifle, Flight, etc.)
  if loc:find("mortar") or name:find("mortar") or loc:find("bomb") or loc:find("demolition") or loc:find("cannon") or loc:find("artillery") then
    return "Interface\\Icons\\INV_Misc_Bomb_01"
  end
  if name:find("rifleman") or loc:find("rifleman") or loc:find("gunner") or name:find("marksman") or name:find("sniper") then
    return "Interface\\Icons\\INV_Weapon_Rifle_01"
  end
  if loc:find("flight master") or loc:find("gryphon master") or loc:find("wind rider master") or loc:find("bat handler") then
    return "Interface\\Icons\\Spell_Magic_FeatherFall"
  end
  if loc:find("innkeeper") or name:find("innkeeper") then
    return "Interface\\Icons\\INV_Drink_05"
  end
  if loc:find("banker") or loc:find("vault") then
    return "Interface\\Icons\\INV_Box_01"
  end
  if loc:find("auctioneer") then
    return "Interface\\Icons\\INV_Misc_Coin_01"
  end
  if loc:find("stable master") or loc:find("pet trainer") then
    return "Interface\\Icons\\Ability_Hunter_BeastCall"
  end
  if loc:find("mechanostrider merchant") or name:find("mechanostrider merchant") then
    return "Interface\\Icons\\Ability_Mount_MechaStrider"
  end
  if loc:find("riding trainer") or loc:find("ram breeder") or loc:find("horse breeder") or loc:find("mount vendor") or loc:find("mount merchant") then
    return "Interface\\Icons\\Ability_Mount_MountainRam"
  end
  if loc:find("explorer") or name:find("prospector") or loc:find("prospector") or loc:find("archaeolog") or name:find("surveyor") then
    return "Interface\\Icons\\INV_Misc_Spyglass_02"
  end

  -- Class Trainers
  if loc:find("warlock trainer") or loc:find("demonology") then return "Interface\\Icons\\Spell_Shadow_DeathCoil" end
  if loc:find("demon trainer") then return "Interface\\Icons\\Spell_Shadow_SummonImp" end
  if loc:find("mage trainer") or loc:find("portal trainer") or loc:find("arcane") then return "Interface\\Icons\\Spell_Holy_MagicalSentry" end
  if loc:find("priest trainer") then return "Interface\\Icons\\Spell_Holy_Renew" end
  if loc:find("rogue trainer") or loc:find("assassin") then return "Interface\\Icons\\Ability_Backstab" end
  if loc:find("warrior trainer") or loc:find("battlemaster") then return "Interface\\Icons\\Ability_Warrior_OffensiveStance" end
  if loc:find("paladin trainer") then return "Interface\\Icons\\Spell_Holy_HolyBolt" end
  if loc:find("hunter trainer") then return "Interface\\Icons\\Ability_Hunter_RunningShot" end
  if loc:find("druid trainer") then return "Interface\\Icons\\Ability_Druid_TravelForm" end
  if loc:find("shaman trainer") then return "Interface\\Icons\\Spell_Nature_Lightning" end

  -- Profession Trainers & Artisans
  if loc:find("blacksmith") or loc:find("weaponsmith") or loc:find("armorsmith") or loc:find("anvil") or loc:find("repair") then return "Interface\\Icons\\Trade_BlackSmithing" end
  if loc:find("tailor") or loc:find("clothier") then return "Interface\\Icons\\Trade_Tailoring" end
  if loc:find("leatherwork") or loc:find("furrier") or loc:find("tanner") then return "Interface\\Icons\\Trade_LeatherWorking" end
  if loc:find("engineer") or loc:find("tinkerer") or loc:find("machinist") then return "Interface\\Icons\\Trade_Engineering" end
  if loc:find("alchemist") or loc:find("alchemy") or loc:find("apothecary") or loc:find("potions") then return "Interface\\Icons\\Trade_Alchemy" end
  if loc:find("herbal") or loc:find("herbs") then return "Interface\\Icons\\Trade_Herbalism" end
  if loc:find("miner") or loc:find("mining") or loc:find("smelter") or name:find("miner ") or name:find(" miner") then return "Interface\\Icons\\Trade_Mining" end
  if loc:find("enchant") then return "Interface\\Icons\\Trade_Engraving" end
  if loc:find("cook") or loc:find("chef") or loc:find("baker") or loc:find("butcher") then return "Interface\\Icons\\INV_Misc_Food_15" end
  if loc:find("fish") or loc:find("angler") then return "Interface\\Icons\\Trade_Fishing" end
  if loc:find("first aid") or loc:find("nurse") or loc:find("surgeon") or loc:find("medic") or loc:find("doctor") or loc:find("physician") or loc:find("healer") then return "Interface\\Icons\\Spell_Holy_SealOfSacrifice" end

  -- Vendors & Supplies in Creature table (Gold coins, never brown backpacks!)
  if loc:find("ale and wine") or loc:find("drink") or loc:find("bartender") or loc:find("alcohol") or loc:find("wine") then return "Interface\\Icons\\INV_Drink_05" end
  if loc:find("general supplies") or loc:find("trade supplies") or loc:find("goods") or loc:find("merchant") or loc:find("vendor") or loc:find("trader") or loc:find("tradesman") or loc:find("supplies") then return "Interface\\Icons\\INV_Misc_Coin_01" end
  if loc:find("weapons") or loc:find("bowyer") or loc:find("gunsmith") or loc:find("swordsmith") then return "Interface\\Icons\\INV_Sword_04" end
  if loc:find("armor") or loc:find("shield") then return "Interface\\Icons\\INV_Shield_05" end
  if loc:find("reagent") or loc:find("poison") then return "Interface\\Icons\\INV_Potion_33" end
  if loc:find("tabard") or loc:find("guild") then return "Interface\\Icons\\INV_Shirt_GuildTabard_01" end
  if loc:find("commander") or loc:find("captain") or loc:find("marshal") or loc:find("general") or loc:find("sergeant") then return "Interface\\Icons\\INV_BannerPVP_02" end

  -- 2. Mechanical Creatures & Mounts
  if fam == "mechanical" or name:find("mechanostrider") or name:find("shredder") or name:find("harvest golem") or name:find("clockwork") then
    if name:find("mechanostrider") or loc:find("mechanostrider") then return "Interface\\Icons\\Ability_Mount_MechaStrider" end
    if name:find("shredder") then return "Interface\\Icons\\INV_Gizmo_01" end
    if name:find("harvest") or name:find("reaper") then return "Interface\\Icons\\INV_Gizmo_02" end
    return "Interface\\Icons\\INV_Misc_Gear_01"
  end

  -- 3. Critters
  if fam == "critter" then
    if name:find("chicken") then return "Interface\\Icons\\INV_Egg_02" end
    if name:find("toad") or name:find("frog") then return "Interface\\Icons\\Spell_Nature_Polymorph" end
    return "Interface\\Icons\\INV_Misc_MonsterTail_03"
  end

  -- 4. Lepers & Afflicted (Must precede Gnome check!)
  if name:find("leper") or loc:find("leper") then
    return "Interface\\Icons\\Spell_Shadow_Haunting"
  end

  -- 5. Undead & Ghosts
  if fam == "undead" then
    if name:find("skeleton") or name:find("skeletal") or name:find("bone") then return "Interface\\Icons\\Spell_DeathKnight_ArmyOfTheDead" end
    if name:find("ghoul") or name:find("abomination") or name:find("flesh") then return "Interface\\Icons\\Spell_Shadow_AnimateDead" end
    if name:find("ghost") or name:find("wraith") or name:find("specter") or name:find("spirit") or name:find("shade") or name:find("phantom") or name:find("banshee") or name:find("wisp") then return "Interface\\Icons\\Spell_Shadow_AntiShadow" end
    if name:find("zombie") or name:find("corpse") or name:find("rotten") or name:find("decay") then return "Interface\\Icons\\Spell_Shadow_Haunting" end
    if name:find("lich") or name:find("necromancer") then return "Interface\\Icons\\Spell_Shadow_RaiseDead" end
    return "Interface\\Icons\\INV_Misc_Head_Undead_01"
  end

  -- 6. Beasts
  if fam == "beast" then
    -- Giraffe & Long-Necked Savannah Grazers
    if name:find("giraffe") or name:find("strider") or name:find("plainstrider") or name:find("foreststrider") or name:find("stepstrider") or name:find("mazzranache") then
      return "Interface\\Icons\\Ability_Hunter_Pet_TallStrider"
    end
    -- Gazelle, Deer, Stag, Antelope, Courser, Talbuk, Ram, Goat, Sheep
    if name:find("gazelle") or name:find("stag") or name:find("deer") or name:find("doe") or name:find("buck") or name:find("courser") or name:find("antelope") or name:find("talbuk") or name:find("reindeer") or name:find("ram") or name:find("goat") or name:find("sheep") then
      return "Interface\\Icons\\Ability_Mount_MountainRam"
    end
    -- Equines (Zhevra, Horse, Steed, Stallion, Mare, Mule, Donkey, Pony, Charger)
    if name:find("zhevra") or name:find("horse") or name:find("steed") or name:find("stallion") or name:find("mare") or name:find("mule") or name:find("donkey") or name:find("pony") or name:find("charger") or name:find("equine") then
      return "Interface\\Icons\\Ability_Mount_RidingHorse"
    end
    -- Kodo, Thunder Lizard, Lightning Hide, Clefthoof, Rhino, Stegodon
    if name:find("kodo") or name:find("clefthoof") or name:find("rhino") or name:find("thunder lizard") or name:find("lightning hide") or name:find("stegodon") or name:find("thunderhead") or name:find("brontus") or name:find("arra'chea") or name:find("thunderer") then
      return "Interface\\Icons\\Ability_Mount_Kodo_01"
    end
    -- Crocolisks, Alligators, Basilisks, Lizards, Threshadons
    if name:find("croc") or name:find("alligator") or name:find("crocolisk") or name:find("basilisk") or name:find("reaver") or name:find("lashtail") or name:find("snapjaw") or name:find("threshadon") or name:find("scale belly") or name:find("gator") or name:find("reptile") or name:find("slink") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk"
    end
    -- Raptors and Dinosaurs
    if name:find("raptor") or name:find("scythemaw") or name:find("razormaw") or name:find("taillasher") or name:find("scytheclaw") or name:find("screecher") or name:find("tethis") or name:find("sarltooth") or name:find("riptooth") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Raptor"
    end
    -- Cats / Felines
    if name:find("cat") or name:find("lion") or name:find("tiger") or name:find("tigress") or name:find("panther") or name:find("pantheress") or name:find("leopard") or name:find("lynx") or name:find("cougar") or name:find("saber") or name:find("stalker") or name:find("jaguar") or name:find("pridewing") or name:find("pridemother") or name:find("pridelord") or name:find("shadowclaw") or name:find("dishu") or name:find("antilos") or name:find("araga") or name:find("bhag'thera") or name:find("broken tooth") or name:find("humar") or name:find("rak'shiri") or name:find("bangalash") or name:find("clutchmother") or name:find("sirobi") or name:find("feras") or name:find("sin'dall") or name:find("konda") or name:find("claw") or name:find("prowler") or name:find("huntress") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Cat"
    end
    -- Bears / Ursines
    if name:find("bear") or name:find("grizzly") or name:find("polar") or name:find("ursoc") or name:find("mauler") or name:find("ursa") or name:find("barnabus") or name:find("samras") or name:find("bjarn") or name:find("borelgore") or name:find("brumeran") or name:find("cliff jumper") or name:find("mangeclaw") or name:find("sooty") or name:find("grizzled") or name:find("den mother") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Bear"
    end
    -- Boars / Swine
    if name:find("boar") or name:find("pig") or name:find("swine") or name:find("tusk") or name:find("agam'ar") or name:find("agathelos") or name:find("bellygrub") or name:find("thundersnout") or name:find("rotgut") or name:find("goretusk") or name:find("snout") or name:find("princess") or name:find("porcine") or name:find("sow") or name:find("gruntler") or name:find("snort") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Boar"
    end
    -- Spiders / Arachnids
    if name:find("spider") or name:find("tarantula") or name:find("widow") or name:find("creeper") or name:find("weaver") or name:find("spinette") or name:find("web") or name:find("besseleth") or name:find("chatter") or name:find("recluse") or name:find("naraxis") or name:find("spinner") or name:find("lurker") or name:find("shadra") or name:find("fang") or name:find("fangor") or name:find("fangore") or name:find("broodguard") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Spider"
    end
    -- Scorpions / Scorpids / Silithids
    if name:find("scorpid") or name:find("scorpion") or name:find("deathsting") or name:find("sarkoth") or name:find("silithid") or name:find("beetle") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Scorpid"
    end
    -- Turtles / Tortoises
    if name:find("turtle") or name:find("tortoise") or name:find("snapper") or name:find("ironback") or name:find("shell") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Turtle"
    end
    -- Birds / Avians / Winged
    if name:find("bird") or name:find("hawk") or name:find("eagle") or name:find("falcon") or name:find("owl") or name:find("buzzard") or name:find("vulture") or name:find("condor") or name:find("carrion") or name:find("roc") or name:find("fleshripper") or name:find("skyblade") or name:find("soarer") or name:find("gryphon") or name:find("hippogryph") or name:find("wyvern") or name:find("wind rider") or name:find("chimaera") or name:find("chimaerok") or name:find("hydra") or name:find("wind serpent") or name:find("bonepicker") or name:find("arikara") or name:find("vultros") or name:find("corvus") or name:find("feather") or name:find("swoop") or name:find("razorbeak") or name:find("strigid") or name:find("zaricotl") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Owl"
    end
    if name:find("pollo") or name:find("chicken") or name:find("rooster") then
      return "Interface\\Icons\\INV_Egg_02"
    end
    -- Bats
    if name:find("bat") or name:find("blind hunter") or name:find("blood seeker") or name:find("vampire") or name:find("dreadbat") or name:find("ressan") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Bat"
    end
    -- Snakes / Serpents
    if name:find("snake") or name:find("cobra") or name:find("viper") or name:find("serpent") or name:find("adder") or name:find("python") then
      return "Interface\\Icons\\Spell_Nature_GuardianWard"
    end
    -- Gorillas / Apes
    if name:find("gorilla") or name:find("ape") or name:find("groddok") or name:find("mukla") or name:find("kalu") or name:find("mokk") or name:find("silverback") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Gorilla"
    end
    -- Hyenas
    if name:find("hyena") or name:find("snickerfang") or name:find("hazzali") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Hyena"
    end
    -- Crabs / Crustaceans
    if name:find("crab") or name:find("crawler") or name:find("pincer") or name:find("lobster") or name:find("crustacean") or name:find("clack") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Crab"
    end
    -- Wasps / Insects
    if name:find("wasp") or name:find("stinger") or name:find("hornet") or name:find("bee") or name:find("flyer") or name:find("sting") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Wasp"
    end
    -- Fish / Aquatic
    if name:find("fish") or name:find("frenzy") or name:find("shark") or name:find("piranha") or name:find("thresher") or name:find("thrasher") then
      return "Interface\\Icons\\Trade_Fishing"
    end
    -- Wolves, Worgs, Canines
    if name:find("wolf") or name:find("worg") or name:find("coyote") or name:find("fox") or name:find("hound") or name:find("mastiff") or name:find("dog") or name:find("pup") or name:find("whelp") or name:find("ravager") or name:find("snarlmane") or name:find("lupos") or name:find("bloodshot") or name:find("timber") or name:find("scavenger") or name:find("snarl") or name:find("howler") or name:find("barker") or name:find("howl") or name:find("silvermane") then
      return "Interface\\Icons\\Ability_Hunter_Pet_Wolf"
    end
    -- Factual Blizzard Beast fallback: Hunter Beast Tracking paw print (never a wolf!)
    return "Interface\\Icons\\Ability_Tracking"
  end

  -- 7. Elementals
  if fam == "elemental" then
    if name:find("fire") or name:find("ember") or name:find("flame") or name:find("lava") or name:find("magma") or name:find("cinder") or name:find("scorch") or name:find("blaze") then return "Interface\\Icons\\Spell_Fire_Fire" end
    if name:find("water") or name:find("sea") or name:find("aqua") or name:find("ice") or name:find("frost") or name:find("surge") or name:find("wave") or name:find("hydro") then return "Interface\\Icons\\Spell_Frost_Frost" end
    if name:find("earth") or name:find("rock") or name:find("stone") or name:find("clay") or name:find("mud") or name:find("mountain") or name:find("pebble") or name:find("boulder") then return "Interface\\Icons\\Spell_Nature_Earthquake" end
    if name:find("air") or name:find("wind") or name:find("storm") or name:find("tempest") or name:find("dust") or name:find("tornado") or name:find("cyclone") or name:find("zephyr") then return "Interface\\Icons\\Spell_Nature_Cyclone" end
    return "Interface\\Icons\\Spell_Nature_WispSplode"
  end

  -- 8. Demons
  if fam == "demon" then
    if name:find("imp") then return "Interface\\Icons\\Spell_Shadow_SummonImp" end
    if name:find("felhunter") or name:find("hound") or name:find("stalker") then return "Interface\\Icons\\Spell_Shadow_SummonFelHunter" end
    if name:find("voidwalker") or name:find("void") then return "Interface\\Icons\\Spell_Shadow_SummonVoidWalker" end
    if name:find("succubus") or name:find("siren") then return "Interface\\Icons\\Spell_Shadow_SummonSuccubus" end
    if name:find("infernal") or name:find("abyssal") then return "Interface\\Icons\\Spell_Shadow_SummonInfernal" end
    if name:find("doomguard") or name:find("dreadlord") or name:find("felguard") then return "Interface\\Icons\\Spell_Shadow_SummonDoomGuard" end
    if name:find("satyr") then return "Interface\\Icons\\Ability_Racial_ShadowMeld" end
    return "Interface\\Icons\\Spell_Shadow_Metamorphosis"
  end

  -- 9. Dragonkin
  if fam == "dragonkin" then
    if name:find("black") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Black" end
    if name:find("red") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Red" end
    if name:find("green") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Green" end
    if name:find("blue") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Blue" end
    if name:find("bronze") or name:find("time") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze" end
    return "Interface\\Icons\\INV_Misc_Head_Dragon_01"
  end

  -- 10. Giants & Ogres
  if fam == "giant" or name:find("ogre") or name:find("boulderfist") or name:find("bloodmaul") or name:find("dunemaul") or name:find("gordok") or name:find("mo'grosh") or name:find("spirestone") or name:find("crushridge") then
    if name:find("ogre") or name:find("boulderfist") or name:find("bloodmaul") or name:find("dunemaul") or name:find("gordok") or name:find("mo'grosh") or name:find("spirestone") or name:find("crushridge") then
      return "Interface\\Icons\\INV_Misc_MonsterHead_03"
    end
    return "Interface\\Icons\\Ability_Racial_Avatar"
  end

  -- 11. Specific Humanoid Species & Tribes
  if name:find("wendigo") or name:find("yeti") or name:find("vagash") or name:find("icebeard") or name:find("ferocitas") then
    return "Interface\\Icons\\Ability_Racial_BearForm"
  end
  if name:find("trogg") or name:find("rockjaw") or name:find("stonevault") or name:find("grik'nir") then
    return "Interface\\Icons\\INV_Misc_MonsterClaw_02"
  end
  if name:find("troll") or name:find("frostmane") or name:find("darkspear") or name:find("bloodscalp") or name:find("vilebranch") or name:find("witherbark") or name:find("sandfury") or name:find("atal'ai") or name:find("gurubashi") then
    return "Interface\\Icons\\INV_Misc_Head_Troll_01"
  end
  if name:find("kobold") or name:find("tunnel rat") or name:find("drywhisker") or name:find("snobold") then
    return "Interface\\Icons\\INV_Misc_Head_Kobold_01"
  end
  if name:find("gnoll") or name:find("riverpaw") or name:find("mudsnout") or name:find("mosshide") then
    return "Interface\\Icons\\INV_Misc_Head_Gnoll_01"
  end
  if name:find("murloc") or name:find("greymurloc") or name:find("bluegill") or name:find("muckdweller") then
    return "Interface\\Icons\\INV_Misc_Head_Murloc_01"
  end
  if name:find("centaur") or name:find("kolkar") or name:find("galak") or name:find("magram") or name:find("gelkis") then
    return "Interface\\Icons\\INV_Misc_Head_Centaur_01"
  end
  if name:find("quillboar") or name:find("bristleback") or name:find("razormane") or name:find("death's head") or name:find("kraul") then
    return "Interface\\Icons\\INV_Misc_Head_Quillboar_01"
  end
  if name:find("furbolg") or name:find("timbermaw") or name:find("deadwood") or name:find("bristlelimb") or name:find("blackwood") then
    return "Interface\\Icons\\INV_Misc_MonsterClaw_04"
  end
  if name:find("naga") or name:find("hatecrest") or name:find("spitefin") then
    return "Interface\\Icons\\INV_Sword_26"
  end
  if name:find("harpy") or name:find("witchwing") then
    return "Interface\\Icons\\Ability_Hunter_Pet_Owl"
  end
  if name:find("pirate") or name:find("swashbuckler") or name:find("deckhand") or name:find("buccaneer") or name:find("corsair") or name:find("southsea") or name:find("bloodsail") then
    return "Interface\\Icons\\INV_Helmet_66"
  end
  if name:find("bandit") or name:find("defias") or name:find("thief") or name:find("cutpurse") or name:find("brigand") or name:find("outlaw") then
    return "Interface\\Icons\\INV_Helmet_41"
  end
  if name:find("cultist") or name:find("shadow council") or name:find("twilight") or name:find("dark strand") then
    return "Interface\\Icons\\Spell_Shadow_ShadowPact"
  end

  -- Playable Races / Named Races (Authentic Blizzard Race Head Icons)
  if name:find("gnome") or name:find("gnomish") or name:find("tinkerer") or name:find("fizzlebang") or name:find("sprysprocket") or name:find("springsprocket") or name:find("rustsprocket") or name:find("togglevolt") or name:find("whindlebolt") or name:find("fizzwizzle") or name:find("featherwhistle") then
    return "Interface\\Icons\\INV_Misc_Head_Gnome_01"
  end
  if name:find("dwarf") or name:find("dwarven") or name:find("dark iron") or name:find("ironforge") or name:find("bronzebeard") or name:find("wildhammer") or name:find("stormpike") or name:find("mountaineer") or name:find("thunderbrew") or name:find("forgestone") or name:find("stonehallow") or name:find("barleybrew") or name:find("amberstill") or name:find("frosthammer") or name:find("steelgrill") or name:find("whitebeard") or name:find("stoneflint") or name:find("flintfire") or name:find("stoutarm") or name:find("grimand") then
    return "Interface\\Icons\\INV_Misc_Head_Dwarf_01"
  end
  if name:find("orc") or name:find("grunt") or name:find("peon") or name:find("warsong") or name:find("kor'kron") or name:find("blackrock") or name:find("dragonmaw") then
    return "Interface\\Icons\\INV_Misc_Head_Orc_01"
  end
  if name:find("tauren") or name:find("bloodhoof") or name:find("grimtotem") or name:find("thunderhorn") or name:find("ragetotem") or name:find("wildmane") or name:find("runetotem") then
    return "Interface\\Icons\\INV_Misc_Bone_TaurenSkull_01"
  end
  if name:find("elf") or name:find("sentinel") or name:find("kaldorei") or name:find("feathermoon") or name:find("starsong") then
    return "Interface\\Icons\\INV_Misc_Head_Elf_01"
  end
  if name:find("undead") or name:find("forsaken") or name:find("scourge") or name:find("deathguard") then
    return "Interface\\Icons\\INV_Misc_Head_Undead_01"
  end
  if name:find("human") or name:find("stormwind") or name:find("guard") or name:find("footman") or name:find("knight") then
    return "Interface\\Icons\\INV_Misc_Head_Human_01"
  end

  -- Zone-aware racial humanoid fallback
  if zone:find("dun morogh") or zone:find("ironforge") or zone:find("loch modan") then
    return "Interface\\Icons\\INV_Misc_Head_Dwarf_01"
  end
  if zone:find("elwynn forest") or zone:find("stormwind") or zone:find("westfall") or zone:find("redridge") then
    return "Interface\\Icons\\INV_Misc_Head_Human_01"
  end
  if zone:find("teldrassil") or zone:find("darnassus") or zone:find("darkshore") or zone:find("ashenvale") then
    return "Interface\\Icons\\INV_Misc_Head_Elf_01"
  end
  if zone:find("durotar") or zone:find("orgrimmar") or zone:find("barrens") then
    return "Interface\\Icons\\INV_Misc_Head_Orc_01"
  end
  if zone:find("mulgore") or zone:find("thunder bluff") then
    return "Interface\\Icons\\INV_Misc_Bone_TaurenSkull_01"
  end
  if zone:find("tirisfal") or zone:find("undercity") or zone:find("silverpine") then
    return "Interface\\Icons\\INV_Misc_Head_Undead_01"
  end

  return "Interface\\Icons\\INV_Misc_Head_Human_01"
end

--------------------------------------------------------------------------------
-- Item Dropper Cross-Referencing & Entity Resolution Engine
--------------------------------------------------------------------------------
FG.ItemDroppersIndex = nil
FG.CreaturesByNameIndex = nil
FG.VendorsByNameIndex = nil

function FG:BuildItemDroppersIndex()
  if FG.ItemDroppersIndex then return end
  FG.ItemDroppersIndex = {}
  if not FG.Data or not FG.Data.Creatures then return end
  for cid, c in pairs(FG.Data.Creatures) do
    if c.loot and not FG:IsInternalCreature(c.name, c.family) then
      for _, drop in ipairs(c.loot) do
        if drop.id then
          local list = FG.ItemDroppersIndex[drop.id]
          if not list then
            list = {}
            FG.ItemDroppersIndex[drop.id] = list
          end
          local numPct = tonumber((drop.pct or ""):match("(%d+%.?%d*)") or 0) or 0
          table.insert(list, {
            creature = c,
            pct = drop.pct or "0.01%",
            numPct = numPct,
          })
        end
      end
    end
  end
  for itemId, list in pairs(FG.ItemDroppersIndex) do
    table.sort(list, function(a, b)
      if a.numPct ~= b.numPct then
        return a.numPct > b.numPct
      end
      return (a.creature.name or "") < (b.creature.name or "")
    end)
  end
end

function FG:GetItemDroppers(itemId)
  if not itemId then return nil end
  if not FG.ItemDroppersIndex then
    FG:BuildItemDroppersIndex()
  end
  return FG.ItemDroppersIndex and FG.ItemDroppersIndex[itemId]
end

function FG:FindCreatureByName(name)
  if not name or not FG.Data or not FG.Data.Creatures then return nil end
  if not FG.CreaturesByNameIndex then
    FG.CreaturesByNameIndex = {}
    for cid, c in pairs(FG.Data.Creatures) do
      if c.name and not FG:IsInternalCreature(c.name, c.family) then
        FG.CreaturesByNameIndex[c.name:lower()] = c
      end
    end
  end
  return FG.CreaturesByNameIndex[name:lower()]
end

function FG:FindVendorByName(name)
  if not name or not FG.Data or not FG.Data.Vendors then return nil end
  if not FG.VendorsByNameIndex then
    FG.VendorsByNameIndex = {}
    for vid, v in pairs(FG.Data.Vendors) do
      if v.name then
        FG.VendorsByNameIndex[v.name:lower()] = v
      end
    end
  end
  return FG.VendorsByNameIndex[name:lower()]
end

function FG:GetItemRowSourceText(item)
  if not item then return "World Drop" end
  local droppers = FG:GetItemDroppers(item.id)
  if droppers and #droppers > 0 then
    local top = droppers[1]
    local c = top.creature
    local coordStr = (c.coords and c.coords ~= "") and (" " .. c.coords) or ""
    local zoneStr = (c.zone and c.zone ~= "") and (c.zone .. coordStr) or "Azeroth"
    local pctStr = top.pct and (" (" .. top.pct .. ")") or ""
    if #droppers > 1 then
      return "Dropped by: " .. c.name .. " (" .. zoneStr .. ")" .. pctStr .. " +" .. (#droppers - 1) .. " more"
    else
      return "Dropped by: " .. c.name .. " (" .. zoneStr .. ")" .. pctStr
    end
  end
  if item.source and item.source ~= "" then
    local mobName = item.source:match("Dropped by:%s*([^(]+)")
    if mobName then
      local trimmed = mobName:gsub("%s+$", "")
      local c = FG:FindCreatureByName(trimmed)
      if c and c.coords and c.coords ~= "" then
        local zoneStr = c.zone or "Azeroth"
        local pct = item.source:match("%((%d+%.?%d*%%)%)") or ""
        local pctStr = pct ~= "" and (" (" .. pct .. ")") or ""
        return "Dropped by: " .. c.name .. " (" .. zoneStr .. " " .. c.coords .. ")" .. pctStr
      end
    end
    return item.source:gsub("^Quest:%s*", "")
  end
  return "World Drop"
end

function FG:GetFolderIcon(folder)
  if not folder then return "Interface\\Icons\\INV_Misc_Bag_08" end
  if folder.icon and folder.icon ~= "" and folder.icon ~= "Interface\\Icons\\inv_misc_bag_08" and folder.icon ~= "Interface\\Icons\\INV_Misc_Bag_08" then
    return folder.icon
  end

  local path = (folder.path or ""):lower()
  local name = (folder.name or ""):lower()

  -- 1. Armor Slots & Types
  if path:find("cloth") or name:find("cloth") then
    if path:find("head") or name:find("head") then return "Interface\\Icons\\INV_Helmet_08" end
    if path:find("shoulder") or name:find("shoulder") then return "Interface\\Icons\\INV_Shoulder_02" end
    if path:find("chest") or name:find("chest") then return "Interface\\Icons\\INV_Chest_Cloth_23" end
    if path:find("wrist") or name:find("wrist") or name:find("bracer") then return "Interface\\Icons\\INV_Bracer_07" end
    if path:find("hand") or name:find("hand") or name:find("glove") then return "Interface\\Icons\\INV_Gauntlets_14" end
    if path:find("waist") or name:find("waist") or name:find("belt") then return "Interface\\Icons\\INV_Belt_03" end
    if path:find("leg") or name:find("leg") or name:find("pant") then return "Interface\\Icons\\INV_Pants_08" end
    if path:find("feet") or name:find("feet") or name:find("boot") then return "Interface\\Icons\\INV_Boots_05" end
    return "Interface\\Icons\\INV_Chest_Cloth_23"
  end

  if path:find("leather") or name:find("leather") then
    if path:find("head") or name:find("head") then return "Interface\\Icons\\INV_Helmet_04" end
    if path:find("shoulder") or name:find("shoulder") then return "Interface\\Icons\\INV_Shoulder_01" end
    if path:find("chest") or name:find("chest") then return "Interface\\Icons\\INV_Chest_Leather_08" end
    if path:find("wrist") or name:find("wrist") or name:find("bracer") then return "Interface\\Icons\\INV_Bracer_06" end
    if path:find("hand") or name:find("hand") or name:find("glove") then return "Interface\\Icons\\INV_Gauntlets_04" end
    if path:find("waist") or name:find("waist") or name:find("belt") then return "Interface\\Icons\\INV_Belt_02" end
    if path:find("leg") or name:find("leg") or name:find("pant") then return "Interface\\Icons\\INV_Pants_06" end
    if path:find("feet") or name:find("feet") or name:find("boot") then return "Interface\\Icons\\INV_Boots_08" end
    return "Interface\\Icons\\INV_Chest_Leather_08"
  end

  if path:find("mail") or name:find("mail") then
    if path:find("head") or name:find("head") then return "Interface\\Icons\\INV_Helmet_03" end
    if path:find("shoulder") or name:find("shoulder") then return "Interface\\Icons\\INV_Shoulder_10" end
    if path:find("chest") or name:find("chest") then return "Interface\\Icons\\INV_Chest_Chain_15" end
    if path:find("wrist") or name:find("wrist") or name:find("bracer") then return "Interface\\Icons\\INV_Bracer_16" end
    if path:find("hand") or name:find("hand") or name:find("gauntlet") then return "Interface\\Icons\\INV_Gauntlets_17" end
    if path:find("waist") or name:find("waist") or name:find("belt") then return "Interface\\Icons\\INV_Belt_12" end
    if path:find("leg") or name:find("leg") or name:find("legguard") then return "Interface\\Icons\\INV_Pants_03" end
    if path:find("feet") or name:find("feet") or name:find("boot") then return "Interface\\Icons\\INV_Boots_Plate_01" end
    return "Interface\\Icons\\INV_Chest_Chain_15"
  end

  if path:find("plate") or name:find("plate") then
    if path:find("head") or name:find("head") then return "Interface\\Icons\\INV_Helmet_01" end
    if path:find("shoulder") or name:find("shoulder") then return "Interface\\Icons\\INV_Shoulder_19" end
    if path:find("chest") or name:find("chest") then return "Interface\\Icons\\INV_Chest_Plate03" end
    if path:find("wrist") or name:find("wrist") or name:find("bracer") then return "Interface\\Icons\\INV_Bracer_19" end
    if path:find("hand") or name:find("hand") or name:find("gauntlet") then return "Interface\\Icons\\INV_Gauntlets_10" end
    if path:find("waist") or name:find("waist") or name:find("belt") then return "Interface\\Icons\\INV_Belt_15" end
    if path:find("leg") or name:find("leg") or name:find("legplate") then return "Interface\\Icons\\INV_Pants_04" end
    if path:find("feet") or name:find("feet") or name:find("boot") then return "Interface\\Icons\\INV_Boots_Plate_01" end
    return "Interface\\Icons\\INV_Chest_Plate03"
  end

  if path:find("shield") or name:find("shield") then return "Interface\\Icons\\INV_Shield_04" end
  if path:find("cloak") or name:find("cloak") or name:find("cape") then return "Interface\\Icons\\INV_Misc_Cape_19" end

  -- Generic Slot matching
  if path:find("/head") or name == "head" then return "Interface\\Icons\\INV_Helmet_08" end
  if path:find("/shoulder") or name:find("shoulder") then return "Interface\\Icons\\INV_Shoulder_02" end
  if path:find("/chest") or name == "chest" then return "Interface\\Icons\\INV_Chest_Plate08" end
  if path:find("/wrist") or name:find("wrist") or name:find("bracer") then return "Interface\\Icons\\INV_Bracer_07" end
  if path:find("/hands") or name:find("hands") or name:find("gloves") or name:find("gauntlets") then return "Interface\\Icons\\INV_Gauntlets_10" end
  if path:find("/waist") or name:find("waist") or name:find("belt") then return "Interface\\Icons\\INV_Belt_03" end
  if path:find("/legs") or name:find("legs") or name:find("pants") then return "Interface\\Icons\\INV_Pants_06" end
  if path:find("/feet") or name:find("feet") or name:find("boots") then return "Interface\\Icons\\INV_Boots_Plate_01" end

  -- 2. Weapons
  if name:find("two%-handed axe") or name:find("2h axe") then return "Interface\\Icons\\INV_Axe_09" end
  if name:find("one%-handed axe") or name:find("1h axe") or name:find("axe") then return "Interface\\Icons\\INV_Axe_01" end
  if name:find("bow") or name:find("crossbow") then return "Interface\\Icons\\INV_Weapon_Bow_05" end
  if name:find("dagger") then return "Interface\\Icons\\INV_Weapon_ShortBlade_01" end
  if name:find("gun") or name:find("rifle") or name:find("ranged") then return "Interface\\Icons\\INV_Weapon_Rifle_01" end
  if name:find("two%-handed mace") or name:find("2h mace") then return "Interface\\Icons\\INV_Hammer_04" end
  if name:find("one%-handed mace") or name:find("1h mace") or name:find("mace") then return "Interface\\Icons\\INV_Mace_01" end
  if name:find("polearm") or name:find("spear") then return "Interface\\Icons\\INV_Spear_05" end
  if name:find("staff") or name:find("staves") then return "Interface\\Icons\\INV_Staff_08" end
  if name:find("two%-handed sword") or name:find("2h sword") then return "Interface\\Icons\\INV_Sword_18" end
  if name:find("one%-handed sword") or name:find("1h sword") or name:find("sword") then return "Interface\\Icons\\INV_Sword_04" end
  if name:find("wand") then return "Interface\\Icons\\INV_Wand_01" end
  if name:find("fist weapon") then return "Interface\\Icons\\INV_Gauntlets_04" end
  if path:find("weapons") or name:find("weapon") then return "Interface\\Icons\\INV_Sword_04" end

  -- 3. Jewelry & Accessories
  if name:find("amulet") or name:find("necklace") or path:find("amulet") then return "Interface\\Icons\\INV_Jewelry_Necklace_07" end
  if name:find("ring") or path:find("ring") then return "Interface\\Icons\\INV_Jewelry_Ring_03" end
  if name:find("trinket") or path:find("trinket") then return "Interface\\Icons\\INV_Jewelry_Talisman_07" end
  if path:find("accessories") or name:find("accessories") or name:find("jewelry") then return "Interface\\Icons\\INV_Jewelry_Necklace_07" end

  -- 4. Consumables & Trade Goods
  if name:find("potion") or name:find("elixir") or path:find("potion") then return "Interface\\Icons\\INV_Potion_51" end
  if name:find("food") or name:find("drink") or path:find("food") then return "Interface\\Icons\\INV_Misc_Food_14" end
  if name:find("bandage") or path:find("bandage") then return "Interface\\Icons\\INV_Misc_Bandage_08" end
  if name:find("scroll") or path:find("scroll") then return "Interface\\Icons\\INV_Scroll_02" end
  if path:find("consumables") or name:find("consumables") then return "Interface\\Icons\\INV_Potion_51" end

  if name:find("herb") or path:find("herb") then return "Interface\\Icons\\INV_Misc_Herb_07" end
  if name:find("metal") or name:find("stone") or name:find("ore") or path:find("ore") then return "Interface\\Icons\\INV_Ore_Iron_01" end
  if name:find("part") or name:find("device") or path:find("parts") then return "Interface\\Icons\\INV_Misc_Gear_01" end
  if name:find("reagent") or name:find("material") or path:find("reagent") then return "Interface\\Icons\\INV_Misc_Dust_01" end
  if path:find("trade_goods") or name:find("trade goods") then return "Interface\\Icons\\INV_Ore_Iron_01" end

  if path:find("recipe") or name:find("recipe") or name:find("plan") then return "Interface\\Icons\\INV_Scroll_03" end

  -- 5. Quests & Continents
  if path:find("quests/available") or name:find("available quest") then return "Interface\\Icons\\Spell_Holy_ElunesGrace" end
  if path:find("quests/recommended") or name:find("recommended quest") then return "Interface\\Icons\\Spell_Holy_MindVision" end
  if path:find("eastern_kingdoms") or name:find("eastern kingdom") then return "Interface\\Icons\\Spell_Frost_WindWalkOn" end
  if path:find("kalimdor") or name:find("kalimdor") then return "Interface\\Icons\\Spell_Nature_NatureTouchGrow" end
  if path:find("quests/dungeon") then return "Interface\\Icons\\Spell_Shadow_Teleport" end
  if path:find("quests/class") or name:find("class quest") then return "Interface\\Icons\\INV_Helmet_08" end
  if path:find("quests/prof") or name:find("profession quest") then return "Interface\\Icons\\Trade_Engineering" end
  if path:find("quest") or name:find("quest") then return "Interface\\Icons\\INV_Misc_Book_07" end

  -- 6. Creatures & Bosses
  if path:find("boss") or name:find("boss") then return "Interface\\Icons\\Spell_Shadow_SummonDoomGuard" end
  if path:find("rare") or name:find("rare") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze" end
  if path:find("beast") or name:find("beast") then return "Interface\\Icons\\Ability_Hunter_Pet_Wolf" end
  if path:find("humanoid") or name:find("humanoid") then return "Interface\\Icons\\Ability_Racial_ShadowMeld" end
  if path:find("undead") or name:find("undead") then return "Interface\\Icons\\Spell_DeathKnight_ArmyOfTheDead" end
  if path:find("demon") or name:find("demon") then return "Interface\\Icons\\Spell_Shadow_SummonFelHunter" end
  if path:find("dragonkin") or name:find("dragon") then return "Interface\\Icons\\INV_Misc_Head_Dragon_Red" end
  if path:find("elemental") or name:find("elemental") then return "Interface\\Icons\\Spell_Fire_Fire" end
  if path:find("giant") or name:find("giant") or name:find("ogre") then return "Interface\\Icons\\Ability_Racial_Avatar" end
  if path:find("creature") or name:find("creature") or name:find("mob") then return "Interface\\Icons\\Ability_Hunter_Pet_Wolf" end

  -- 7. Dungeons & Raids
  if name:find("starter") then return "Interface\\Icons\\Spell_Nature_Strength" end
  if name:find("mid") then return "Interface\\Icons\\Spell_Fire_Fireball02" end
  if name:find("endgame") then return "Interface\\Icons\\Spell_Shadow_ShadowBolt" end
  if name:find("raid") then return "Interface\\Icons\\Spell_Fire_Fire" end
  if path:find("dungeon") or name:find("dungeon") then return "Interface\\Icons\\Spell_Shadow_Teleport" end

  -- 8. Vendors & Flight Paths
  if name:find("flight") or path:find("flight") then return "Interface\\Icons\\Ability_Hunter_EagleEye" end
  if name:find("pvp") or path:find("pvp") then return "Interface\\Icons\\INV_BannerPVP_02" end
  if name:find("repair") or name:find("blacksmith") then return "Interface\\Icons\\Trade_BlackSmithing" end
  if path:find("vendor") or name:find("vendor") then return "Interface\\Icons\\INV_Misc_Bag_07" end

  -- 9. Warcraft Forever Exclusives
  if path:find("forever") or name:find("forever") then return "Interface\\Icons\\Spell_Holy_MagicalSentry" end

  -- 10. Nearby Area Intel
  if path:find("nearby/loot") or name:find("loot") then return "Interface\\Icons\\INV_Misc_Coin_02" end
  if path:find("nearby") or name:find("nearby") then return "Interface\\Icons\\Ability_Tracking" end

  -- 11. Top Level Armor / Items
  if path == "items/armor" or name == "armor" then return "Interface\\Icons\\INV_Chest_Plate03" end
  if path == "items" or name:find("item") then return "Interface\\Icons\\INV_Sword_04" end

  return "Interface\\Icons\\INV_Misc_Bag_08"
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
      local fTex = FG:GetFolderIcon(folder)
      btn.Icon:SetTexture(fTex)
      btn.IconFrame:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
    btn.Title:SetPoint("RIGHT", btn, "RIGHT", -68, 0)
    btn.Title:SetJustifyH("LEFT")
    btn.Title:SetWordWrap(false)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -2)
    btn.Sub:SetPoint("RIGHT", btn, "RIGHT", -68, 0)
    btn.Sub:SetHeight(15)
    btn.Sub:SetJustifyH("LEFT")
    btn.Sub:SetWordWrap(false)

    btn.Title:SetText("|cff66ccff" .. folder.name .. "|r")
    btn.Sub:SetText("|cff8899aa" .. (folder.desc or folder.count or "Folder") .. "|r")
    btn.Hint:SetText("|cff38bdf8Open >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = function()
        FG:NavigateToFolder(folder.path)
        FG:PlaySparkSound("shimmer")
      end
      btn.InspectBtn.entityType = nil
      btn.InspectBtn.entityData = nil
    end

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
    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "item"
      btn.InspectBtn.entityData = item
    end

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
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
    btn.Title:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Title:SetJustifyH("LEFT")
    btn.Title:SetWordWrap(false)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -2)
    btn.Sub:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Sub:SetHeight(15)
    btn.Sub:SetJustifyH("LEFT")
    btn.Sub:SetWordWrap(false)

    local qColor = FG.QualityColors[item.quality] or "ffffffff"
    local foreverTag = item.isForever and " |cffe6cc80[Forever]|r" or ""
    local ilvlStr = (item.ilvl and item.ilvl > 0) and (" |cff7e8c9e(iLvl " .. item.ilvl .. ")|r") or ""
    btn.Title:SetText("|c" .. qColor .. item.name .. "|r" .. foreverTag .. ilvlStr)

    local parts = {}
    if item.slot and item.slot ~= "" and item.slot ~= "Non-equippable" then
      table.insert(parts, "|cff8ba5cc" .. item.slot .. "|r")
    elseif item.itemType and item.itemType ~= "" then
      table.insert(parts, "|cff8ba5cc" .. item.itemType .. "|r")
    end

    local srcText = FG:GetItemRowSourceText(item)
    if srcText and srcText ~= "" and srcText ~= "World Drop" then
      table.insert(parts, "|cff94a3b8" .. srcText .. "|r")
    elseif item.bonding and item.bonding ~= "" then
      table.insert(parts, "|cff7e8c9e" .. item.bonding .. "|r")
    else
      table.insert(parts, "|cff7e8c9eWorld Drop|r")
    end

    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

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
      GameTooltip:AddLine("|cffdf80ff<Inspect Button>|r View full item stats & sources", 0.85, 0.85, 0.85)
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
        FG:PlaySparkSound("shimmer")
      end
    end)

  elseif match.type == "quest" then
    local qData = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "quest"
      btn.InspectBtn.entityData = qData
    end

    local st = FG:GetQuestStatus(qData.id, qData.title)
    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture(FG:GetQuestIcon(qData))
      if st == "completed" then
        btn.IconFrame:SetBackdropBorderColor(0.20, 0.90, 0.35, 0.95)
      elseif st == "ready_to_turn_in" then
        btn.IconFrame:SetBackdropBorderColor(0.25, 0.80, 1.0, 0.95)
      elseif st == "active" then
        btn.IconFrame:SetBackdropBorderColor(1.0, 0.85, 0.15, 0.95)
      else
        btn.IconFrame:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.9)
      end
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
    btn.Title:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Title:SetJustifyH("LEFT")
    btn.Title:SetWordWrap(false)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -2)
    btn.Sub:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Sub:SetHeight(15)
    btn.Sub:SetJustifyH("LEFT")
    btn.Sub:SetWordWrap(false)

    local statusBadge = ""
    local titleColor = "|cffffd24d"
    if st == "completed" then
      statusBadge = " |cff22c55e[Completed]|r"
      titleColor = "|cff86efac"
    elseif st == "ready_to_turn_in" then
      statusBadge = " |cff38bdf8[Ready to Turn In]|r"
      titleColor = "|cff7dd3fc"
    elseif st == "active" then
      statusBadge = " |cffffd100[Active]|r"
      titleColor = "|cfffef08a"
    else
      statusBadge = " |cff94a3b8[Available]|r"
    end

    local foreverTag = qData.isForever and " |cffe6cc80[Forever]|r" or ""
    btn.Title:SetText(titleColor .. qData.title .. "|r" .. foreverTag .. statusBadge)

    local parts = {}
    local startNpc = qData.npc
    local cObj = startNpc and FG:FindCreatureByName(startNpc)
    local qCoords = (cObj and cObj.coords) or qData.coords
    if qCoords and qCoords ~= "" then
      local distPct, distYards, distStr = FG:GetDistanceAndBearing(qCoords)
      if distStr then
        table.insert(parts, "|cff38bdf8[" .. qCoords .. "]|r |cff22c55e" .. distStr .. "|r")
      else
        table.insert(parts, "|cff38bdf8[" .. qCoords .. "]|r")
      end
    end

    local reqLvl = tonumber(qData.reqLevel) or 1
    local qLvl = tonumber(qData.questLevel) or 0
    if reqLvl > 1 then
      table.insert(parts, "|cff38bdf8Lvl " .. reqLvl .. "+|r")
    end
    if not match.isNearby and qData.zone and qData.zone ~= "" then
      table.insert(parts, "|cff8ba5cc" .. qData.zone .. "|r")
    end
    if qData.npc and qData.npc ~= "" then
      table.insert(parts, "|cff94a3b8Starts: " .. qData.npc .. "|r")
    end
    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.10, 0.18, 0.14, 0.95)
      self:SetBackdropBorderColor(0.45, 0.25, 0.85, 0.90)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(qData.title, 1, 0.85, 0.2)
      if st == "completed" then
        GameTooltip:AddLine("Status: Completed & Turned In", 0.13, 0.77, 0.37)
      elseif st == "ready_to_turn_in" then
        GameTooltip:AddLine("Status: Ready to Turn In (Objectives Done)", 0.22, 0.74, 0.97)
      elseif st == "active" then
        GameTooltip:AddLine("Status: In Progress (Active in Quest Log)", 1.0, 0.82, 0.0)
      else
        GameTooltip:AddLine("Status: Available (Not Completed)", 0.60, 0.65, 0.75)
      end
      GameTooltip:AddLine("Available: Level " .. (qData.reqLevel or "1") .. "+", 0.4, 0.8, 1.0)
      GameTooltip:AddLine("Recommended: Level " .. (qData.questLevel or "?"), 0.2, 1.0, 0.4)
      if qData.npc and qData.npc ~= "" then
        GameTooltip:AddLine("Questgiver: " .. qData.npc .. (qCoords and (" (" .. qCoords .. ")") or ""), 0.3, 0.8, 1.0)
      end
      if qData.objectives and qData.objectives ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Objectives: " .. qData.objectives, 0.8, 0.8, 0.8, true)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("|cffdf80ff<Click Row>|r Track quest coordinates", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("|cffdf80ff<Inspect Button>|r View full quest details & rewards", 0.85, 0.85, 0.85)
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
        if qCoords and qCoords ~= "" then
          local targetName = (qData.npc and qData.npc ~= "") and (qData.npc .. " (" .. qData.title .. ")") or qData.title
          FG:TrackEntityCoords(targetName, qData.zone, qCoords)
        else
          print(string.format("|cffdf80ff[Sparky Quest]|r %s in %s. Starts from: %s", qData.title, qData.zone or "Azeroth", qData.npc or "Unknown"))
        end
        FG:PlaySparkSound("shimmer")
      end
    end)

  elseif match.type == "creature" then
    local c = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "creature"
      btn.InspectBtn.entityData = c
    end

    if btn.IconFrame then
      btn.IconFrame:Show()
      local cTex = FG:GetCreatureIcon(c)
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
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
    btn.Title:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Title:SetJustifyH("LEFT")
    btn.Title:SetWordWrap(false)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -2)
    btn.Sub:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Sub:SetHeight(15)
    btn.Sub:SetJustifyH("LEFT")
    btn.Sub:SetWordWrap(false)

    local foreverTag = c.isForever and " |cffe6cc80[Forever]|r" or ""
    local classColor = (c.classification == "Boss" or c.classification == "Rare Elite" or c.classification == "World Boss") and "ffff4040" or (c.classification == "Elite" and "ffffd24d" or "ff52b8ff")
    local lvlStr = (c.minLevel and c.maxLevel and c.minLevel ~= c.maxLevel) and (c.minLevel .. "-" .. c.maxLevel) or (c.maxLevel or c.minLevel or "?")
    local classTag = (c.classification and c.classification ~= "Normal") and (" " .. c.classification) or ""
    btn.Title:SetText("|c" .. classColor .. c.name .. "|r" .. foreverTag .. " |cff7e8c9e(Lvl " .. lvlStr .. classTag .. ")|r")

    local parts = {}
    if c.coords and c.coords ~= "" then
      local distPct, distYards, distStr = FG:GetDistanceAndBearing(c.coords)
      if distStr then
        table.insert(parts, "|cff38bdf8[" .. c.coords .. "]|r |cff22c55e" .. distStr .. "|r")
      else
        table.insert(parts, "|cff38bdf8[" .. c.coords .. "]|r")
      end
    end
    if not match.isNearby and c.zone and c.zone ~= "" then
      table.insert(parts, "|cff8ba5cc" .. c.zone .. "|r")
    end
    if c.location and c.location ~= "" then
      table.insert(parts, "|cff94a3b8" .. c.location .. "|r")
    end
    if #parts == 0 then
      table.insert(parts, "|cff7e8c9e" .. (c.family or "Creature") .. "|r")
    end
    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.18, 0.14, 0.10, 0.95)
      self:SetBackdropBorderColor(0.85, 0.55, 0.20, 0.90)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(c.name, 1, 0.85, 0.2)
      GameTooltip:AddLine("Level: " .. lvlStr .. " (" .. (c.classification or "Normal") .. ")", 1, 1, 1)
      if c.zone and c.zone ~= "" then GameTooltip:AddLine("Zone: " .. c.zone, 0.3, 0.8, 1.0) end
      if c.location and c.location ~= "" then GameTooltip:AddLine("Location: " .. c.location, 0.2, 1, 0.2) end
      if c.coords and c.coords ~= "" then
        local _, _, distStr = FG:GetDistanceAndBearing(c.coords)
        GameTooltip:AddLine("Coordinates: " .. c.coords .. (distStr and (" (" .. distStr .. ")") or ""), 0.2, 1, 0.2)
      end
      if c.health and c.health > 0 then GameTooltip:AddLine("Health: " .. c.health, 1, 0.3, 0.3) end
      if c.strategy and c.strategy ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Notes: " .. c.strategy, 0.8, 0.8, 0.8, true)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("|cffdf80ff<Click Row>|r Set map pin & track coordinates", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("|cffdf80ff<Inspect Button>|r View full NPC intel, drops & tactics", 0.85, 0.85, 0.85)
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
        FG:TrackEntityCoords(c.name, c.zone, c.coords)
        FG:PlaySparkSound("shimmer")
      end
    end)

  elseif match.type == "dungeon" then
    local d = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "dungeon"
      btn.InspectBtn.entityData = d
    end

    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture(FG:GetDungeonIcon(d))
      btn.IconFrame:SetBackdropBorderColor(0.7, 0.4, 0.9, 0.9)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
    btn.Title:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Title:SetJustifyH("LEFT")
    btn.Title:SetWordWrap(false)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -2)
    btn.Sub:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Sub:SetHeight(15)
    btn.Sub:SetJustifyH("LEFT")
    btn.Sub:SetWordWrap(false)

    local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
    btn.Title:SetText("|cffffd24d" .. d.name .. "|r" .. foreverTag)

    local parts = {}
    local minLvl = tonumber(d.minLevel) or 0
    local recLvl = d.recLevel or "?"
    if minLvl > 0 then
      table.insert(parts, "|cff38bdf8Avail: Lvl " .. minLvl .. "+|r")
    else
      table.insert(parts, "|cff38bdf8Avail: Any|r")
    end
    table.insert(parts, "|cff22c55eRec: Lvl " .. recLvl .. "|r")
    if d.zone and d.zone ~= "" then table.insert(parts, "|cff8ba5cc" .. d.zone .. "|r") end
    if d.coords and d.coords ~= "" then
      local distPct, distYards, distStr = FG:GetDistanceAndBearing(d.coords)
      if distStr then
        table.insert(parts, "|cff94a3b8Entrance: " .. d.coords .. " (" .. distStr .. ")|r")
      else
        table.insert(parts, "|cff94a3b8Entrance: " .. d.coords .. "|r")
      end
    end
    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.15, 0.12, 0.22, 0.95)
      self:SetBackdropBorderColor(0.55, 0.38, 0.78, 0.90)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(d.name, 1, 0.85, 0.2)
      GameTooltip:AddLine("Available: Level " .. (d.minLevel or "1") .. "+", 0.4, 0.8, 1.0)
      GameTooltip:AddLine("Recommended: Level " .. (d.recLevel or "?"), 0.2, 1.0, 0.4)
      GameTooltip:AddLine("Zone: " .. (d.zone or "Various"), 0.8, 0.8, 0.9)
      if d.coords and d.coords ~= "" then
        local _, _, distStr = FG:GetDistanceAndBearing(d.coords)
        GameTooltip:AddLine("Entrance: " .. d.coords .. (distStr and (" (" .. distStr .. ")") or ""), 0.2, 1, 0.2)
      end
      if d.strategy and d.strategy ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tactics: " .. d.strategy, 0.8, 0.8, 0.8, true)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("|cffdf80ff<Click Row>|r Track entrance coordinates", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("|cffdf80ff<Inspect Button>|r View tactics, bosses & loot", 0.85, 0.85, 0.85)
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
        FG:TrackEntityCoords(d.name .. " Entrance", d.zone, d.coords)
        FG:PlaySparkSound("shimmer")
      end
    end)

  elseif match.type == "vendor" then
    local v = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "vendor"
      btn.InspectBtn.entityData = v
    end

    if btn.IconFrame then
      btn.IconFrame:Show()
      btn.Icon:SetTexture(FG:GetVendorIcon(v))
      btn.IconFrame:SetBackdropBorderColor(0.4, 0.8, 0.5, 0.9)
    end
    btn.Title:ClearAllPoints()
    btn.Title:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)
    btn.Title:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Title:SetJustifyH("LEFT")
    btn.Title:SetWordWrap(false)
    btn.Sub:ClearAllPoints()
    btn.Sub:SetPoint("TOPLEFT", btn.Title, "BOTTOMLEFT", 0, -2)
    btn.Sub:SetPoint("RIGHT", btn, "RIGHT", -78, 0)
    btn.Sub:SetHeight(15)
    btn.Sub:SetJustifyH("LEFT")
    btn.Sub:SetWordWrap(false)

    btn.Title:SetText("|cffffd24d" .. v.name .. "|r |cff7e8c9e(Vendor)|r")
    local parts = {}
    if v.coords and v.coords ~= "" then
      local distPct, distYards, distStr = FG:GetDistanceAndBearing(v.coords)
      if distStr then
        table.insert(parts, "|cff38bdf8[" .. v.coords .. "]|r |cff22c55e" .. distStr .. "|r")
      else
        table.insert(parts, "|cff38bdf8[" .. v.coords .. "]|r")
      end
    end
    if not match.isNearby and v.zone and v.zone ~= "" then
      table.insert(parts, "|cff8ba5cc" .. v.zone .. "|r")
    end
    if v.item and v.item ~= "" then
      table.insert(parts, "|cff94a3b8Sells: " .. v.item .. "|r")
    end
    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.12, 0.18, 0.16, 0.95)
      self:SetBackdropBorderColor(0.30, 0.75, 0.55, 0.90)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(v.name, 1, 0.85, 0.2)
      GameTooltip:AddLine("Sells: " .. (v.item or "Goods"), 1, 1, 1)
      if v.zone and v.zone ~= "" then GameTooltip:AddLine("Zone: " .. v.zone, 0.3, 0.8, 1.0) end
      if v.coords and v.coords ~= "" then
        local _, _, distStr = FG:GetDistanceAndBearing(v.coords)
        GameTooltip:AddLine("Coordinates: " .. v.coords .. (distStr and (" (" .. distStr .. ")") or ""), 0.2, 1, 0.2)
      end
      if v.tip and v.tip ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Note: " .. v.tip, 0.8, 0.8, 0.8, true)
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("|cffdf80ff<Click Row>|r Set map pin & track coordinates", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("|cffdf80ff<Inspect Button>|r View vendor wares & inventory", 0.85, 0.85, 0.85)
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
        FG:TrackEntityCoords(v.name, v.zone, v.coords)
        FG:PlaySparkSound("shimmer")
      end
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
-- Mission Control Home Dashboard
--------------------------------------------------------------------------------
function FG:CreateHomeDashboard(parent)
  local db = CreateFrame("Frame", "ForeverGuideHomeDashboard", parent)
  db:SetSize(554, 340)
  db:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  db:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  MakePixelSharp(db)

  -- 1. Location Bar Card
  local radar = CreateFrame("Frame", nil, db, "BackdropTemplate")
  radar:SetSize(550, 114)
  radar:SetPoint("TOPLEFT", db, "TOPLEFT", 2, -2)
  radar:SetPoint("TOPRIGHT", db, "TOPRIGHT", -2, -2)
  MakePixelSharp(radar)
  radar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 12,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  radar:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
  radar:SetBackdropBorderColor(0.20, 0.28, 0.42, 0.85)

  local zoneTitle = radar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  zoneTitle:SetPoint("TOPLEFT", radar, "TOPLEFT", 12, -12)
  zoneTitle:SetPoint("RIGHT", radar, "RIGHT", -12, 0)
  zoneTitle:SetJustifyH("LEFT")
  zoneTitle:SetWordWrap(false)
  zoneTitle:SetHeight(20)
  zoneTitle:SetText("|cff64748bCurrent Location: |r|cffffffffLocal Area|r")
  SharpenFontString(zoneTitle, 15, "OUTLINE")
  db.ZoneTitle = zoneTitle

  local zoneSub = radar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  zoneSub:SetPoint("TOPLEFT", zoneTitle, "BOTTOMLEFT", 0, -5)
  zoneSub:SetPoint("RIGHT", radar, "RIGHT", -12, 0)
  zoneSub:SetJustifyH("LEFT")
  zoneSub:SetWordWrap(false)
  zoneSub:SetHeight(15)
  zoneSub:SetText("|cff94a3b8Local area quests, rares & encounters|r")
  SharpenFontString(zoneSub, 11, "OUTLINE")
  db.ZoneSub = zoneSub

  local function CreateStatBadge(parentFrame, xOff, label, targetFolder)
    local badge = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
    badge:SetSize(76, 24)
    badge:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", xOff, 10)
    MakePixelSharp(badge)
    badge:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false,
      tileSize = 8,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    badge:SetBackdropColor(0.12, 0.14, 0.20, 0.85)
    badge:SetBackdropBorderColor(0.24, 0.28, 0.38, 0.70)

    local txt = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("CENTER", badge, "CENTER", 0, 0)
    txt:SetWordWrap(false)
    SharpenFontString(txt, 10, "OUTLINE")
    badge.Text = txt

    badge:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.20, 0.24, 0.35, 0.95)
      self:SetBackdropBorderColor(0.55, 0.70, 0.95, 0.95)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:AddLine("Open " .. label, 1, 1, 1)
      GameTooltip:AddLine("Jump to nearby " .. label:lower() .. " in this zone.", 0.7, 0.7, 0.8)
      GameTooltip:Show()
    end)
    badge:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.12, 0.14, 0.20, 0.85)
      self:SetBackdropBorderColor(0.24, 0.28, 0.38, 0.70)
      GameTooltip:Hide()
    end)
    badge:SetScript("OnClick", function()
      FG:NavigateToFolder(targetFolder)
    end)
    return badge
  end

  db.QuestBadge = CreateStatBadge(radar, 12, "Quests", "nearby/quests")
  db.RareBadge = CreateStatBadge(radar, 94, "Rares", "nearby/rares")
  db.MobBadge = CreateStatBadge(radar, 176, "Mobs", "nearby/creatures")
  db.DungeonBadge = CreateStatBadge(radar, 258, "Dungeons", "nearby/dungeons")

  local radarBtn = CreateFrame("Button", nil, radar, "BackdropTemplate")
  radarBtn:SetSize(184, 26)
  radarBtn:SetPoint("BOTTOMRIGHT", radar, "BOTTOMRIGHT", -12, 10)
  MakePixelSharp(radarBtn)
  radarBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  radarBtn:SetBackdropColor(0.12, 0.16, 0.24, 0.95)
  radarBtn:SetBackdropBorderColor(0.28, 0.40, 0.65, 0.85)

  local rTxt = radarBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  rTxt:SetPoint("CENTER", radarBtn, "CENTER", 0, 0)
  rTxt:SetWordWrap(false)
  rTxt:SetText("|cff38bdf8🧭 View Local Area Intel →|r")
  SharpenFontString(rTxt, 11, "OUTLINE")
  radarBtn.Text = rTxt

  radarBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.18, 0.24, 0.36, 1.0)
    self:SetBackdropBorderColor(0.40, 0.65, 0.95, 1.0)
  end)
  radarBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.16, 0.24, 0.95)
    self:SetBackdropBorderColor(0.28, 0.40, 0.65, 0.85)
  end)
  radarBtn:SetScript("OnClick", function()
    FG:SetActiveCategory("nearby")
  end)
  db.RadarBtn = radarBtn

  -- 2. Featured Codex Hubs (2x2 Grid)
  local function CreateHubCard(x, y, iconPath, titleText, descText, targetFolder)
    local card = CreateFrame("Button", nil, db, "BackdropTemplate")
    card:SetSize(270, 58)
    card:SetPoint("TOPLEFT", db, "TOPLEFT", x, y)
    MakePixelSharp(card)
    card:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false,
      tileSize = 8,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    card:SetBackdropColor(0.09, 0.10, 0.14, 0.90)
    card:SetBackdropBorderColor(0.24, 0.28, 0.38, 0.70)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", card, "LEFT", 10, 0)
    icon:SetTexture(iconPath)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    MakePixelSharp(icon)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)
    title:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetHeight(15)
    title:SetText(titleText)
    SharpenFontString(title, 11, "OUTLINE")

    local desc = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(false)
    desc:SetHeight(13)
    desc:SetText(descText)
    SharpenFontString(desc, 9, "OUTLINE")

    card:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.18, 0.14, 0.28, 0.95)
      self:SetBackdropBorderColor(0.70, 0.35, 0.95, 0.95)
    end)
    card:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.09, 0.10, 0.14, 0.90)
      self:SetBackdropBorderColor(0.24, 0.28, 0.38, 0.70)
    end)
    card:SetScript("OnClick", function()
      FG:NavigateToFolder(targetFolder)
    end)
    return card
  end

  db.HubForever = CreateHubCard(2, -124, "Interface\\Icons\\INV_Misc_Book_09",
    "|cffffd700Warcraft Forever Exclusives|r",
    "|cff94a3b8Server gear, exclusive quests & endgame additions|r",
    "forever")

  db.HubArmor = CreateHubCard(278, -124, "Interface\\Icons\\INV_Chest_Cloth_23",
    "|cff38bdf8Armor by Equipment Slot|r",
    "|cff94a3b8Head, Chest, Boots sorted iLvl Low to High|r",
    "items/armor")

  db.HubQuests = CreateHubCard(2, -188, "Interface\\Icons\\INV_Misc_Map02",
    "|cff4ade80Zone Questlines & Stories|r",
    "|cff94a3b844 zones across EK & Kalimdor|r",
    "quests/eastern_kingdoms")

  db.HubRares = CreateHubCard(278, -188, "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    "|cfffb923cRare Spawns & Bosses|r",
    "|cff94a3b8Silver-dragons, world encounters & loot|r",
    "creatures/rares")

  -- 3. Field Notes & Controls Card
  local notes = CreateFrame("Frame", nil, db, "BackdropTemplate")
  notes:SetSize(550, 74)
  notes:SetPoint("TOPLEFT", db, "TOPLEFT", 2, -252)
  notes:SetPoint("TOPRIGHT", db, "TOPRIGHT", -2, -252)
  MakePixelSharp(notes)
  notes:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  notes:SetBackdropColor(0.07, 0.08, 0.11, 0.90)
  notes:SetBackdropBorderColor(0.30, 0.20, 0.45, 0.60)

  local notesTag = notes:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  notesTag:SetPoint("TOPLEFT", notes, "TOPLEFT", 12, -8)
  notesTag:SetText("|cffdf80ff⚡ SPARKY'S FIELD NOTES & CONTROLS|r")
  SharpenFontString(notesTag, 10, "OUTLINE")

  local function CreateTipCol(parentFrame, xOff, title, sub)
    local tf = CreateFrame("Frame", nil, parentFrame)
    tf:SetSize(170, 36)
    tf:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOff, -26)

    local t1 = tf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t1:SetPoint("TOPLEFT", tf, "TOPLEFT", 0, 0)
    t1:SetPoint("RIGHT", tf, "RIGHT", 0, 0)
    t1:SetJustifyH("LEFT")
    t1:SetWordWrap(false)
    t1:SetText(title)
    SharpenFontString(t1, 10, "OUTLINE")

    local t2 = tf:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    t2:SetPoint("TOPLEFT", t1, "BOTTOMLEFT", 0, -2)
    t2:SetPoint("RIGHT", tf, "RIGHT", 0, 0)
    t2:SetJustifyH("LEFT")
    t2:SetWordWrap(false)
    t2:SetText(sub)
    SharpenFontString(t2, 9, "OUTLINE")
    return tf
  end

  CreateTipCol(notes, 12, "|cffffffffShift + Left-Click|r", "|cff94a3b8Link item or quest to chat|r")
  CreateTipCol(notes, 188, "|cffffffffRight-Click Row|r", "|cff94a3b8Inspect 3D model & map coords|r")
  CreateTipCol(notes, 364, "|cffffffff/fg or /forever|r", "|cff94a3b8Toggle codex anytime · Esc closes|r")

  db:Hide()
  parent.HomeDashboard = db
  FG.HomeDashboard = db
  return db
end

function FG:UpdateHomeDashboard()
  local db = FG.HomeDashboard
  if not db then return end

  local pZone, pSub = FG:GetPlayerZoneInfo()
  local subZone = pSub or (GetSubZoneText and GetSubZoneText()) or ""
  local zoneDisplay = pZone ~= "" and pZone or "Azeroth"
  if db.ZoneTitle then
    db.ZoneTitle:SetText("|cff64748bCurrent Location: |r|cffffffff" .. zoneDisplay .. "|r")
  end
  if db.ZoneSub then
    if subZone ~= "" and subZone ~= zoneDisplay then
      db.ZoneSub:SetText("|cff94a3b8Subzone: |r|cff38bdf8" .. subZone .. "|r |cff64748b·|r |cff94a3b8Local area quests, rares & encounters|r")
    else
      db.ZoneSub:SetText("|cff94a3b8Local area quests, rares & encounters in " .. zoneDisplay .. "|r")
    end
  end

  local pZoneLower = (pZone ~= "" and pZone:lower()) or "azeroth"
  local qCount, rCount, mCount, dCount = 0, 0, 0, 0

  if FG.Data.Quests then
    for _, q in pairs(FG.Data.Quests) do
      if q.zone and q.zone:lower():find(pZoneLower, 1, true) then
        qCount = qCount + 1
      end
    end
  end

  if FG.Data.Creatures then
    for _, c in pairs(FG.Data.Creatures) do
      if c.zone and c.zone:lower():find(pZoneLower, 1, true) and not FG:IsInternalCreature(c.name, c.family) then
        mCount = mCount + 1
        local cl = (c.classification or ""):lower()
        if cl:find("rare") or cl:find("boss") or (c.name and c.name:find("%(Rare%)")) then
          rCount = rCount + 1
        end
      end
    end
  end

  if FG.Data.Dungeons then
    for _, d in pairs(FG.Data.Dungeons) do
      if d.zone and d.zone:lower():find(pZoneLower, 1, true) then
        dCount = dCount + 1
      end
    end
  end

  if db.QuestBadge and db.QuestBadge.Text then
    db.QuestBadge.Text:SetText(string.format("|cffffffff%d|r |cffcbd5e1Quests|r", qCount))
  end
  if db.RareBadge and db.RareBadge.Text then
    db.RareBadge.Text:SetText(string.format("|cffffffff%d|r |cfffb923cRares|r", rCount))
  end
  if db.MobBadge and db.MobBadge.Text then
    db.MobBadge.Text:SetText(string.format("|cffffffff%d|r |cff38bdf8Mobs|r", mCount))
  end
  if db.DungeonBadge and db.DungeonBadge.Text then
    db.DungeonBadge.Text:SetText(string.format("|cffffffff%d|r |cffc084fcDungeon%s|r", dCount, dCount == 1 and "" or "s"))
  end
  if db.RadarBtn and db.RadarBtn.Text then
    db.RadarBtn.Text:SetText("|cff38bdf8🧭 View " .. (pZone ~= "" and pZone or "Area") .. " Intel →|r")
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
    searchBox.scopedSearchLock = nil
    searchBox:SetText("")
    searchBox:ClearFocus()
    clearBtn:Hide()
    placeholder:Show()
    FG:SetActiveCategory("all")
  end)

  searchBox:SetScript("OnTextChanged", function(self)
    local query = self:GetText():trim()
    if query == "" then
      self.scopedSearchLock = nil
      placeholder:Show()
      clearBtn:Hide()
      FG:PopulateCodexResults("")
    else
      placeholder:Hide()
      clearBtn:Show()
      if FG.activeCategory ~= "all" and FG.activeCategory ~= "nearby" and not self.scopedSearchLock then
        FG:SetActiveCategory("all")
      else
        FG:PopulateCodexResults(query)
      end
    end
  end)

  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  -- Category Filter Pills
  f.FilterButtons = {}
  local function CreateCategoryPill(name, label, width, xOffset, relativeTo)
    local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
    btn:SetSize(width, 22)
    btn:SetPoint("LEFT", relativeTo, "RIGHT", xOffset, 0)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetFrameLevel((f:GetFrameLevel() or 1) + 12)
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

    btn:SetScript("OnEnter", function(self)
      if FG.activeCategory ~= name then
        self:SetBackdropColor(0.22, 0.16, 0.36, 0.95)
        self:SetBackdropBorderColor(0.75, 0.40, 1.0, 0.95)
        if self.Text then self.Text:SetTextColor(1.0, 1.0, 1.0) end
      end
    end)

    btn:SetScript("OnLeave", function(self)
      if FG.activeCategory ~= name then
        self:SetBackdropColor(0.10, 0.12, 0.16, 0.85)
        self:SetBackdropBorderColor(0.24, 0.28, 0.36, 0.70)
        if self.Text then self.Text:SetTextColor(0.75, 0.75, 0.80) end
      end
    end)

    btn:SetScript("OnClick", function()
      if searchBox and searchBox:GetText():trim() ~= "" then
        searchBox.scopedSearchLock = true
      end
      FG:SetActiveCategory(name)
      FG:PlaySparkSound("shimmer")
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
  lockBtn:EnableMouse(true)
  lockBtn:RegisterForClicks("LeftButtonUp")
  lockBtn:SetFrameLevel((f:GetFrameLevel() or 1) + 12)
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
  dolphinBar:SetFrameLevel((f:GetFrameLevel() or 1) + 5)
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
  upBtn:EnableMouse(true)
  upBtn:RegisterForClicks("LeftButtonUp")
  upBtn:SetFrameLevel((dolphinBar:GetFrameLevel() or 1) + 8)
  upBtn:SetText("< Up")
  MakePixelSharp(upBtn)
  local upFs = upBtn:GetFontString()
  if upFs then SharpenFontString(upFs, 10, "OUTLINE") end
  upBtn:SetScript("OnClick", function()
    FG:NavigateUpFolder()
    FG:PlaySparkSound("shimmer")
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
  scrollFrame:SetFrameLevel((f:GetFrameLevel() or 1) + 2)
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
    content.RowPool[i]:SetFrameLevel((scrollFrame:GetFrameLevel() or 1) + 4)
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
      if btn.Title then SharpenFontString(btn.Title, 12, "OUTLINE") end
      if btn.Sub then SharpenFontString(btn.Sub, 10.5, "OUTLINE") end
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
  sf:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -26, 12)
  MakePixelSharp(sf)

  local body = CreateFrame("Frame", nil, sf)
  body:SetSize(296, 600)
  sf:SetScrollChild(body)
  p.Body = body

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

  local function CreateOrGetLootButton(index)
    local btn = p.Body.LootButtons[index]
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
      titleText:SetWidth(200)
      titleText:SetJustifyH("LEFT")
      titleText:SetWordWrap(false)
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
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if self.kind == "loot" and self.dropData then
          local drop = self.dropData
          local fullItem = (drop.id and FG.Data.Items and FG.Data.Items[drop.id])
          if not fullItem and drop.name and FG.Data.ItemsByName then
            fullItem = FG.Data.ItemsByName[drop.name:lower()]
          end

          local nativeWorked = false
          if drop.id and GameTooltip.SetItemByID then
            nativeWorked = pcall(GameTooltip.SetItemByID, GameTooltip, drop.id)
          end
          if (not nativeWorked) and drop.id and GameTooltip.SetHyperlink then
            nativeWorked = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. drop.id .. ":0:0:0:0:0:0:0:0")
          end

          if not nativeWorked or GameTooltip:NumLines() == 0 then
            GameTooltip:ClearLines()
            local qColor = FG.QualityColors[drop.quality or (fullItem and fullItem.quality)] or "ffffffff"
            GameTooltip:AddLine("|c" .. qColor .. (drop.name or (fullItem and fullItem.name) or "Item") .. "|r", 1, 1, 1)
            if fullItem then
              if fullItem.itemLevel and fullItem.itemLevel > 0 then
                GameTooltip:AddLine("Item Level " .. fullItem.itemLevel, 1, 0.85, 0.2)
              end
              if fullItem.slot and fullItem.slot ~= "" and fullItem.slot ~= "Non-equippable" then
                local typeStr = (fullItem.subType and fullItem.subType ~= "") and (fullItem.slot .. "   " .. fullItem.subType) or fullItem.slot
                GameTooltip:AddLine(typeStr, 1, 1, 1)
              elseif fullItem.type and fullItem.type ~= "" then
                GameTooltip:AddLine(fullItem.type, 1, 1, 1)
              end
              if fullItem.armor and fullItem.armor > 0 then
                GameTooltip:AddLine(fullItem.armor .. " Armor", 1, 1, 1)
              end
              if fullItem.stats and fullItem.stats ~= "" then
                GameTooltip:AddLine(fullItem.stats, 0.1, 1.0, 0.1)
              end
              if fullItem.reqLevel and fullItem.reqLevel > 0 then
                GameTooltip:AddLine("Requires Level " .. fullItem.reqLevel, 1, 1, 1)
              end
              if fullItem.description and fullItem.description ~= "" then
                GameTooltip:AddLine("\"" .. fullItem.description .. "\"", 1, 0.85, 0.2)
              end
            else
              if drop.slot and drop.slot ~= "" and drop.slot ~= "Non-equippable" then
                GameTooltip:AddLine(drop.slot, 1, 1, 1)
              end
              if drop.reqLvl and drop.reqLvl > 0 then
                GameTooltip:AddLine("Requires Level " .. drop.reqLvl, 1, 1, 1)
              end
            end
          end

          if drop.pct and drop.pct ~= "" then
            GameTooltip:AddLine("Drop Chance: |cff38bdf8" .. drop.pct .. "|r")
          end
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("|cffdf80ff<Click>|r Inspect item in Codex", 0.85, 0.85, 0.85)
          GameTooltip:Show()

        elseif self.kind == "dropper_creature" and self.creatureData then
          local c = self.creatureData
          GameTooltip:AddLine(c.name, 1, 0.85, 0.2)
          local lvlStr = (c.minLevel and c.maxLevel and c.minLevel ~= c.maxLevel) and (c.minLevel .. "-" .. c.maxLevel) or (c.maxLevel or c.minLevel or "?")
          GameTooltip:AddLine("Level: " .. lvlStr .. " (" .. (c.classification or "Normal") .. ")", 1, 1, 1)
          if c.zone and c.zone ~= "" then GameTooltip:AddLine("Zone: " .. c.zone, 0.3, 0.8, 1.0) end
          if c.location and c.location ~= "" then GameTooltip:AddLine("Location: " .. c.location, 0.2, 1, 0.2) end
          if c.coords and c.coords ~= "" then GameTooltip:AddLine("Coordinates: " .. c.coords, 0.2, 1, 0.2) end
          if self.pct then GameTooltip:AddLine("Drop Chance: |cff38bdf8" .. self.pct .. "|r") end
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("|cffdf80ff<Click>|r Open NPC intel & spawn location", 0.85, 0.85, 0.85)
          GameTooltip:Show()

        elseif self.kind == "dropper_vendor" and self.vendorData then
          local v = self.vendorData
          GameTooltip:AddLine(v.name, 1, 0.85, 0.2)
          GameTooltip:AddLine("Vendor", 0.2, 1.0, 0.4)
          if v.zone and v.zone ~= "" then GameTooltip:AddLine("Zone: " .. v.zone, 0.3, 0.8, 1.0) end
          if v.coords and v.coords ~= "" then GameTooltip:AddLine("Coordinates: " .. v.coords, 0.2, 1, 0.2) end
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("|cffdf80ff<Click>|r Open vendor intel & wares", 0.85, 0.85, 0.85)
          GameTooltip:Show()
        end
      end)

      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.12, 0.17, 0.90)
        self:SetBackdropBorderColor(0.25, 0.28, 0.38, 0.80)
        GameTooltip:Hide()
      end)

      btn:SetScript("OnClick", function(self)
        if self.kind == "loot" and self.dropData then
          local drop = self.dropData
          local fullItem = (drop.id and FG.Data.Items and FG.Data.Items[drop.id])
          if not fullItem and drop.name and FG.Data.ItemsByName then
            fullItem = FG.Data.ItemsByName[drop.name:lower()]
          end
          if fullItem then
            FG:ShowDetailPanel("item", fullItem)
            FG:PlaySparkSound("shimmer")
          elseif ForeverGuideSearchBox then
            ForeverGuideSearchBox:SetText(drop.name or "")
          end
        elseif self.kind == "dropper_creature" and self.creatureData then
          FG:ShowDetailPanel("creature", self.creatureData)
          FG:PlaySparkSound("shimmer")
        elseif self.kind == "dropper_vendor" and self.vendorData then
          FG:ShowDetailPanel("vendor", self.vendorData)
          FG:PlaySparkSound("shimmer")
        end
      end)

      p.Body.LootButtons[index] = btn
    end
    return btn
  end

  local function AddLootButton(drop)
    lootBtnIndex = lootBtnIndex + 1
    local btn = CreateOrGetLootButton(lootBtnIndex)

    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", p.Body, "TOPLEFT", 6, yOffset)
    btn.kind = "loot"
    btn.dropData = drop
    btn.creatureData = nil
    btn.vendorData = nil
    btn.pct = drop.pct

    local qColor = FG.QualityColors[drop.quality] or "ffffffff"
    btn.Title:SetText("|c" .. qColor .. (drop.name or "Item") .. "|r")
    btn.Rate:SetText("|cff71d5ff" .. (drop.pct or "") .. "|r")
    btn:Show()

    yOffset = yOffset - 28
  end

  local function AddDropperButton(dropper)
    lootBtnIndex = lootBtnIndex + 1
    local btn = CreateOrGetLootButton(lootBtnIndex)

    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", p.Body, "TOPLEFT", 6, yOffset)
    btn.dropData = nil

    if dropper.creature then
      local c = dropper.creature
      btn.kind = "dropper_creature"
      btn.creatureData = c
      btn.vendorData = nil
      btn.pct = dropper.pct

      local classColor = (c.classification == "Boss" or c.classification == "Rare Elite" or c.classification == "World Boss") and "ffff4040" or (c.classification == "Elite" and "ffffd24d" or "ff52b8ff")
      local coordStr = (c.coords and c.coords ~= "") and (" " .. c.coords) or ""
      local zoneStr = (c.zone and c.zone ~= "") and (c.zone .. coordStr) or "Azeroth"
      btn.Title:SetText("|c" .. classColor .. c.name .. "|r |cff7e8c9e(" .. zoneStr .. ")|r")
      btn.Rate:SetText("|cff38bdf8" .. (dropper.pct or "") .. "|r")

    elseif dropper.vendor then
      local v = dropper.vendor
      btn.kind = "dropper_vendor"
      btn.creatureData = nil
      btn.vendorData = v
      btn.pct = dropper.pct

      local coordStr = (v.coords and v.coords ~= "") and (" " .. v.coords) or ""
      local zoneStr = (v.zone and v.zone ~= "") and (v.zone .. coordStr) or "Azeroth"
      btn.Title:SetText("|cffffd24d" .. v.name .. "|r |cff7e8c9e(" .. zoneStr .. ")|r")
      btn.Rate:SetText("|cff20ff20Vendor|r")
    end

    btn:Show()
    yOffset = yOffset - 28
  end

  if entityType == "quest" then
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture(FG:GetQuestIcon(data))
      p.HeaderIconFrame:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.9)
    end
    p.Title:SetText("|cffcf52ffQuest Intel|r")
    AddLine("|cffffd24d" .. (data.title or "Quest") .. "|r", 15, nil, nil, nil, 6)

    local qStatus = FG:GetQuestStatus(data.id, data.title)
    if qStatus == "completed" then
      AddLine("Status: |cff22c55eCompleted (Turned In)|r", 12)
    elseif qStatus == "ready_to_turn_in" then
      AddLine("Status: |cff38bdf8Ready to Turn In (Objectives Done)|r", 12)
    elseif qStatus == "active" then
      AddLine("Status: |cffffd100Active in Quest Log (In Progress)|r", 12)
    else
      AddLine("Status: |cff94a3b8Not Completed (Available)|r", 12)
    end

    local reqLvl = data.reqLevel or "1"
    local qLvl = data.questLevel or "?"
    AddLine("Available: |cff38bdf8Level " .. reqLvl .. "+|r  ·  Recommended: |cff20ff20Level " .. qLvl .. "|r", 12)
    if data.faction and data.faction ~= "" then
      AddLine("Faction: |cff52b8ff" .. data.faction .. "|r", 11)
    end
    if data.isForever then
      AddLine("|cffe6cc80[Forever] Warcraft Forever Exclusive Content|r", 11, nil, nil, nil, 4)
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

    local droppers = FG:GetItemDroppers(data.id)
    if droppers and #droppers > 0 then
      AddSection("CONFIRMED DROPPERS & SOURCES")
      local maxDisplay = math.min(#droppers, 8)
      for i = 1, maxDisplay do
        AddDropperButton(droppers[i])
      end
      if #droppers > maxDisplay then
        AddLine("|cff8899aa...and " .. (#droppers - maxDisplay) .. " other creatures across Azeroth (World Drop)|r", 11, 0.6, 0.7, 0.8, 4)
      end
    elseif data.source and data.source ~= "" then
      AddSection("SOURCE & LOCATION")
      local mobName = data.source:match("Dropped by:%s*([^(]+)")
      local vName = data.source:match("Sold by:%s*([^(]+)")
      local matchedEntity = nil
      if mobName then
        local c = FG:FindCreatureByName(mobName:gsub("%s+$", ""))
        if c then
          local pct = data.source:match("%((%d+%.?%d*%%)%)") or "Drop"
          AddDropperButton({ creature = c, pct = pct })
          matchedEntity = true
        end
      elseif vName then
        local v = FG:FindVendorByName(vName:gsub("%s+$", ""))
        if v then
          AddDropperButton({ vendor = v })
          matchedEntity = true
        end
      end
      if not matchedEntity then
        AddLine(data.source, 12, 0.85, 0.90, 0.95, 6)
      end
    else
      AddSection("SOURCE & LOCATION")
      AddLine("World Drop / Various", 12, 0.85, 0.90, 0.95, 6)
    end

    if data.sellPrice and data.sellPrice ~= "" then
      AddLine("Vendor Price: |cffffffff" .. data.sellPrice .. "|r", 11, 0.9, 0.9, 0.9, 4)
    end

    if data.tip and data.tip ~= "" then
      AddSection("SPARK INTEL & NOTES")
      AddLine(data.tip, 11, 0.75, 0.88, 1.0, 6)
    end

  elseif entityType == "creature" then
    if p.HeaderIcon then
      local cTex = FG:GetCreatureIcon(data)
      p.HeaderIcon:SetTexture(cTex)
      if data.classification == "Boss" or data.classification == "World Boss" then
        p.HeaderIconFrame:SetBackdropBorderColor(1.0, 0.2, 0.2, 1.0)
      elseif data.classification == "Elite" or data.classification == "Rare Elite" then
        p.HeaderIconFrame:SetBackdropBorderColor(1.0, 0.8, 0.2, 1.0)
      else
        p.HeaderIconFrame:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
      end
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

  elseif entityType == "dungeon" then
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture(FG:GetDungeonIcon(data))
      p.HeaderIconFrame:SetBackdropBorderColor(0.7, 0.4, 0.9, 0.9)
    end
    p.Title:SetText("|cffcf52ffDungeon Intel|r")
    AddLine("|cffffd24d" .. (data.name or "Dungeon") .. "|r", 15, nil, nil, nil, 6)
    local minLvl = tonumber(data.minLevel) or 0
    local maxLvl = tonumber(data.maxLevel) or 60
    local availStr = (minLvl > 0) and (minLvl .. "+") or "All Levels"
    if minLvl > 0 and maxLvl < 60 and maxLvl > minLvl then
      availStr = minLvl .. " - " .. maxLvl
    end
    AddLine("Available: |cff38bdf8Level " .. availStr .. "|r  ·  Recommended: |cff20ff20Level " .. (data.recLevel or "?") .. "|r", 12)
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

  elseif entityType == "vendor" then
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture(FG:GetVendorIcon(data))
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
      { path = "creatures", name = "Creatures & Bosses", desc = "Dungeon/Raid Bosses, Rares & NPC Families", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
      { path = "dungeons", name = "Dungeons & Raids", desc = "Starter, Mid, Endgame, Raids & Forever Instances", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
      { path = "items", name = "Items & Equipment", desc = "Weapons, Armor, Reagents, Recipes & Server Gear", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "nearby", name = "Nearby Area Intel (Zone Radar)", desc = "Live radar: local mobs, quests, vendors & loot in current zone", icon = "Interface\\Icons\\Ability_Tracking" },
      { path = "quests", name = "Quests", desc = "By Continent, Zone, Class, & Dungeon", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "vendors", name = "Vendors & Flight Paths", desc = "Flight Masters, PvP Quartermasters & Reagents", icon = "Interface\\Icons\\Ability_Hunter_EagleEye" },
      { path = "forever", name = "[Forever] Warcraft Forever Exclusives", desc = "Exclusive items, quests, NPCs & dungeons", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    },
  },

  -- NEARBY LIVE RADAR KDE DOLPHIN HIERARCHY
  ["nearby"] = {
    title = "Nearby Area Intel (Zone Radar)",
    parent = "root",
    folders = {
      { path = "nearby/closest", name = "Closest Nearby (Distance Radar)", desc = "All entities sorted by live proximity to your coordinates", icon = "Interface\\Icons\\Ability_Hunter_EagleEye" },
      { path = "nearby/creatures", name = "Creatures & Mobs", desc = "Local beasts, humanoids, and monsters in immediate area", icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider" },
      { path = "nearby/quests", name = "Quests", desc = "Active quests and storyline objectives in this zone", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "nearby/rares", name = "Rares & Bosses", desc = "Silver-dragon rare spawns and world encounters", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze" },
      { path = "nearby/vendors", name = "Vendors & Flight Masters", desc = "Flight paths, repairs, reagents, and local trade", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
      { path = "nearby/dungeons", name = "Dungeons & Raids", desc = "Instance entrances, meeting stones, and portals", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
      { path = "nearby/loot", name = "Notable Loot & Drops", desc = "Valuable BoE items, world recipes, and prized drops", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    },
  },

  ["nearby/creatures"] = {
    title = "Nearby Creatures & Mobs",
    parent = "nearby",
    folders = {
      { path = "nearby/creatures/beasts", name = "Beasts & Wildlife", desc = "Giraffes, Kodos, Plainstriders, Hyenas, Raptors & Animals", icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider" },
      { path = "nearby/creatures/humanoids", name = "Humanoids & NPCs", desc = "Centaurs, Quilboars, Pirates, Guards & Townsfolk", icon = "Interface\\Icons\\INV_Misc_Head_Centaur_01" },
      { path = "nearby/creatures/rares", name = "Rares & Named Spawns", desc = "Rare elites and named monsters in the zone", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_02" },
      { path = "nearby/creatures/all", name = "[All Creatures (Full Zone List)]", desc = "Complete list of all creatures in the zone", icon = "Interface\\Icons\\Ability_Tracking", isAll = true },
    },
  },

  ["nearby/vendors"] = {
    title = "Nearby Vendors & Flight Masters",
    parent = "nearby",
    folders = {
      { path = "nearby/vendors/flight", name = "Flight Masters", desc = "Flight points and wind rider / gryphon masters", icon = "Interface\\Icons\\Spell_Magic_FeatherFall" },
      { path = "nearby/vendors/repairs", name = "Repairs & Armorers", desc = "Blacksmiths and equipment repairers", icon = "Interface\\Icons\\Trade_BlackSmithing" },
      { path = "nearby/vendors/reagents", name = "Reagents & Trade Supplies", desc = "Herbs, potions, poisons and crafting goods", icon = "Interface\\Icons\\INV_Potion_33" },
      { path = "nearby/vendors/all", name = "[All Vendors & Services]", desc = "All merchants and service providers in this zone", icon = "Interface\\Icons\\INV_Misc_Coin_01", isAll = true },
    },
  },

  -- QUESTS HIERARCHY
  ["quests"] = {
    title = "Quests",
    parent = "root",
    folders = {
      { path = "quests/active", name = "Active in Log", desc = "Quests currently in your quest log", icon = "Interface\\Icons\\INV_Misc_Book_08" },
      { path = "quests/available", name = "Available Quests", desc = "All quests unlocked for your level (grouped by zone)", icon = "Interface\\Icons\\Spell_Holy_ElunesGrace" },
      { path = "quests/class", name = "Class Quests", desc = "Quests for each of the 9 classes", icon = "Interface\\Icons\\INV_Helmet_08" },
      { path = "quests/completed", name = "Completed Quests", desc = "Quests your character has finished", icon = "Interface\\Icons\\Spell_Holy_BlessingOfProtection" },
      { path = "quests/dungeons", name = "Dungeons & Raids", desc = "Instance questlines across Azeroth", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
      { path = "quests/eastern_kingdoms", name = "Eastern Kingdoms (By Zone)", desc = "24 zones across Eastern Kingdoms", icon = "Interface\\Icons\\Spell_Frost_WindWalkOn" },
      { path = "quests/kalimdor", name = "Kalimdor (By Zone)", desc = "20 zones across Kalimdor", icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow" },
      { path = "quests/professions", name = "Profession Quests", desc = "Trade skill quests & masteries", icon = "Interface\\Icons\\Trade_Engineering" },
      { path = "quests/recommended", name = "Recommended Quests", desc = "Quests matching your character's current level (grouped by zone)", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
      { path = "quests/uncompleted", name = "Uncompleted Quests", desc = "Quests you have not yet finished", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
      { path = "quests/forever", name = "[Forever] Forever Quests", desc = "Exclusive server questlines", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
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
      { path = "items/armor", name = "Armor", desc = "Cloth, Leather, Mail, Plate, Shields", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "items/consumables", name = "Consumables", desc = "Potions, Food, Bandages, Scrolls", icon = "Interface\\Icons\\INV_Potion_51" },
      { path = "items/accessories", name = "Jewelry & Accessories", desc = "Rings, Trinkets, Necklaces, Cloaks", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07" },
      { path = "items/recipes", name = "Recipes & Plans", desc = "Crafting Recipes & Manuals", icon = "Interface\\Icons\\INV_Scroll_03" },
      { path = "items/trade_goods", name = "Trade Goods", desc = "Herbs, Ore, Leather, Cloth, Reagents", icon = "Interface\\Icons\\INV_Ore_Iron_01" },
      { path = "items/weapons", name = "Weapons", desc = "Swords, Axes, Maces, Staves, Bows...", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "items/forever", name = "[Forever] Forever Exclusive Gear", desc = "Exclusive Warcraft Forever items", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    },
  },

  ["items/weapons"] = {
    title = "Weapons",
    parent = "items",
    folders = {
      { path = "items/sub/Bows", name = "Bows & Crossbows", desc = "Bows and crossbows", icon = "Interface\\Icons\\INV_Weapon_Bow_05", filter = { itemType = "Bow" } },
      { path = "items/sub/Daggers", name = "Daggers", desc = "Daggers & dirks", icon = "Interface\\Icons\\INV_Weapon_ShortBlade_01", filter = { itemType = "Dagger" } },
      { path = "items/sub/Fist Weapons", name = "Fist Weapons", desc = "Fist weapons and claws", icon = "Interface\\Icons\\INV_Gauntlets_04", filter = { itemType = "Fist Weapon" } },
      { path = "items/sub/Guns", name = "Guns & Ranged", desc = "Guns and rifles", icon = "Interface\\Icons\\INV_Weapon_Rifle_01", filter = { itemType = "Gun" } },
      { path = "items/sub/One-Handed Axes", name = "One-Handed Axes", desc = "One-handed axes", icon = "Interface\\Icons\\INV_Axe_01", filter = { slot = "One-Hand", itemType = "Axe" } },
      { path = "items/sub/One-Handed Maces", name = "One-Handed Maces", desc = "One-handed maces", icon = "Interface\\Icons\\INV_Mace_01", filter = { slot = "One-Hand", itemType = "Mace" } },
      { path = "items/sub/One-Handed Swords", name = "One-Handed Swords", desc = "One-handed swords", icon = "Interface\\Icons\\INV_Sword_04", filter = { slot = "One-Hand", itemType = "Sword" } },
      { path = "items/sub/Polearms", name = "Polearms", desc = "Polearms and halberds", icon = "Interface\\Icons\\INV_Spear_05", filter = { itemType = "Polearm" } },
      { path = "items/sub/Staves", name = "Staves", desc = "Staves and walking sticks", icon = "Interface\\Icons\\INV_Staff_08", filter = { itemType = "Staff" } },
      { path = "items/sub/Two-Handed Axes", name = "Two-Handed Axes", desc = "Two-handed axes", icon = "Interface\\Icons\\INV_Axe_09", filter = { slot = "Two-Hand", itemType = "Axe" } },
      { path = "items/sub/Two-Handed Maces", name = "Two-Handed Maces", desc = "Two-handed maces & warhammers", icon = "Interface\\Icons\\INV_Hammer_04", filter = { slot = "Two-Hand", itemType = "Mace" } },
      { path = "items/sub/Two-Handed Swords", name = "Two-Handed Swords", desc = "Two-handed broadswords & claymores", icon = "Interface\\Icons\\INV_Sword_18", filter = { slot = "Two-Hand", itemType = "Sword" } },
      { path = "items/sub/Wands", name = "Wands", desc = "Wands & magical batons", icon = "Interface\\Icons\\INV_Wand_01", filter = { itemType = "Wand" } },
    },
  },

  ["items/armor"] = {
    title = "Armor",
    parent = "items",
    folders = {
      { path = "items/sub/Cloaks", name = "Cloaks & Capes", desc = "Back slot cloaks (iLvl Low to High)", icon = "Interface\\Icons\\INV_Misc_Cape_19" },
      { path = "items/armor/cloth", name = "Cloth Armor", desc = "Head, Chest, Belt, Boots, etc.", icon = "Interface\\Icons\\INV_Chest_Cloth_23" },
      { path = "items/armor/leather", name = "Leather Armor", desc = "Head, Chest, Belt, Boots, etc.", icon = "Interface\\Icons\\INV_Chest_Leather_08" },
      { path = "items/armor/mail", name = "Mail Armor", desc = "Head, Chest, Belt, Boots, etc.", icon = "Interface\\Icons\\INV_Chest_Chain_15" },
      { path = "items/armor/plate", name = "Plate Armor", desc = "Head, Chest, Belt, Boots, etc.", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "items/sub/Shields", name = "Shields", desc = "Off-Hand Shields (iLvl Low to High)", icon = "Interface\\Icons\\INV_Shield_04" },
    },
  },

  ["items/armor/cloth"] = {
    title = "Cloth Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/cloth/Chest", name = "Chest", desc = "Cloth robes, vests & tunics", icon = "Interface\\Icons\\INV_Chest_Cloth_23" },
      { path = "items/armor/cloth/Feet", name = "Feet (Boots)", desc = "Cloth boots & slippers", icon = "Interface\\Icons\\INV_Boots_05" },
      { path = "items/armor/cloth/Hands", name = "Hands (Gloves)", desc = "Cloth gloves & mitts", icon = "Interface\\Icons\\INV_Gauntlets_14" },
      { path = "items/armor/cloth/Head", name = "Head", desc = "Cloth helms, hoods & circlets", icon = "Interface\\Icons\\INV_Helmet_08" },
      { path = "items/armor/cloth/Legs", name = "Legs (Pants)", desc = "Cloth pants & leggings", icon = "Interface\\Icons\\INV_Pants_08" },
      { path = "items/armor/cloth/Shoulder", name = "Shoulders", desc = "Cloth mantles & shoulderpads", icon = "Interface\\Icons\\INV_Shoulder_02" },
      { path = "items/armor/cloth/Waist", name = "Waist (Belts)", desc = "Cloth belts & sashes", icon = "Interface\\Icons\\INV_Belt_03" },
      { path = "items/armor/cloth/Wrist", name = "Wrist (Bracers)", desc = "Cloth bracers & cuffs", icon = "Interface\\Icons\\INV_Bracer_07" },
    },
  },

  ["items/armor/leather"] = {
    title = "Leather Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/leather/Chest", name = "Chest", desc = "Leather vests, jerkins & armor", icon = "Interface\\Icons\\INV_Chest_Leather_08" },
      { path = "items/armor/leather/Feet", name = "Feet (Boots)", desc = "Leather boots & footwear", icon = "Interface\\Icons\\INV_Boots_08" },
      { path = "items/armor/leather/Hands", name = "Hands (Gloves)", desc = "Leather gloves & gauntlets", icon = "Interface\\Icons\\INV_Gauntlets_04" },
      { path = "items/armor/leather/Head", name = "Head", desc = "Leather helms, caps & headbands", icon = "Interface\\Icons\\INV_Helmet_04" },
      { path = "items/armor/leather/Legs", name = "Legs (Pants)", desc = "Leather pants & breeches", icon = "Interface\\Icons\\INV_Pants_06" },
      { path = "items/armor/leather/Shoulder", name = "Shoulders", desc = "Leather spaulders & shoulderpads", icon = "Interface\\Icons\\INV_Shoulder_01" },
      { path = "items/armor/leather/Waist", name = "Waist (Belts)", desc = "Leather belts & girdles", icon = "Interface\\Icons\\INV_Belt_02" },
      { path = "items/armor/leather/Wrist", name = "Wrist (Bracers)", desc = "Leather bracers & wristguards", icon = "Interface\\Icons\\INV_Bracer_06" },
    },
  },

  ["items/armor/mail"] = {
    title = "Mail Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/mail/Chest", name = "Chest", desc = "Mail hauberks, mail & armor", icon = "Interface\\Icons\\INV_Chest_Chain_15" },
      { path = "items/armor/mail/Feet", name = "Feet (Boots)", desc = "Mail boots & sabatons", icon = "Interface\\Icons\\INV_Boots_Plate_01" },
      { path = "items/armor/mail/Hands", name = "Hands (Gauntlets)", desc = "Mail gauntlets & grips", icon = "Interface\\Icons\\INV_Gauntlets_17" },
      { path = "items/armor/mail/Head", name = "Head", desc = "Mail helms & coifs", icon = "Interface\\Icons\\INV_Helmet_03" },
      { path = "items/armor/mail/Legs", name = "Legs (Legguards)", desc = "Mail legplates & greaves", icon = "Interface\\Icons\\INV_Pants_03" },
      { path = "items/armor/mail/Shoulder", name = "Shoulders", desc = "Mail pauldrons & epaulets", icon = "Interface\\Icons\\INV_Shoulder_10" },
      { path = "items/armor/mail/Waist", name = "Waist (Belts)", desc = "Mail belts & girdles", icon = "Interface\\Icons\\INV_Belt_12" },
      { path = "items/armor/mail/Wrist", name = "Wrist (Bracers)", desc = "Mail bracers & armsplints", icon = "Interface\\Icons\\INV_Bracer_16" },
    },
  },

  ["items/armor/plate"] = {
    title = "Plate Armor",
    parent = "items/armor",
    folders = {
      { path = "items/armor/plate/Chest", name = "Chest", desc = "Plate breastplates & chestguards", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "items/armor/plate/Feet", name = "Feet (Boots)", desc = "Plate boots & sabatons", icon = "Interface\\Icons\\INV_Boots_Plate_01" },
      { path = "items/armor/plate/Hands", name = "Hands (Gauntlets)", desc = "Plate gauntlets & gloves", icon = "Interface\\Icons\\INV_Gauntlets_10" },
      { path = "items/armor/plate/Head", name = "Head", desc = "Plate helms & visors", icon = "Interface\\Icons\\INV_Helmet_01" },
      { path = "items/armor/plate/Legs", name = "Legs (Legplates)", desc = "Plate legplates & leggings", icon = "Interface\\Icons\\INV_Pants_04" },
      { path = "items/armor/plate/Shoulder", name = "Shoulders", desc = "Plate pauldrons & spaulders", icon = "Interface\\Icons\\INV_Shoulder_19" },
      { path = "items/armor/plate/Waist", name = "Waist (Belts)", desc = "Plate belts & girdles", icon = "Interface\\Icons\\INV_Belt_15" },
      { path = "items/armor/plate/Wrist", name = "Wrist (Bracers)", desc = "Plate bracers & vambraces", icon = "Interface\\Icons\\INV_Bracer_19" },
    },
  },

  ["items/accessories"] = {
    title = "Jewelry & Accessories",
    parent = "items",
    folders = {
      { path = "items/sub/Amulets", name = "Amulets & Necklaces", desc = "Necklaces and pendants", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07", filter = { slot = "Neck" } },
      { path = "items/sub/Cloaks", name = "Cloaks & Capes", desc = "Back slot cloaks", icon = "Interface\\Icons\\INV_Misc_Cape_19", filter = { slot = "Back" } },
      { path = "items/sub/Rings", name = "Rings & Bands", desc = "Rings and bands", icon = "Interface\\Icons\\INV_Jewelry_Ring_03", filter = { slot = "Finger" } },
      { path = "items/sub/Trinkets", name = "Trinkets", desc = "Trinkets and charms", icon = "Interface\\Icons\\INV_Jewelry_Talisman_07", filter = { slot = "Trinket" } },
    },
  },

  ["items/consumables"] = {
    title = "Consumables",
    parent = "items",
    folders = {
      { path = "items/sub/Bandages", name = "Bandages", desc = "First aid bandages", icon = "Interface\\Icons\\INV_Misc_Bandage_08", filter = { itemType = "Bandage" } },
      { path = "items/sub/Food", name = "Food & Drink", desc = "Food, drinks & provisions", icon = "Interface\\Icons\\INV_Misc_Food_14", filter = { itemType = "Food & Drink" } },
      { path = "items/sub/Potions", name = "Potions & Elixirs", desc = "Potions, elixirs & flasks", icon = "Interface\\Icons\\INV_Potion_51", filter = { itemType = "Potion" } },
      { path = "items/sub/Scrolls", name = "Scrolls", desc = "Buff scrolls & enchant scrolls", icon = "Interface\\Icons\\INV_Scroll_02", filter = { itemType = "Scroll" } },
    },
  },

  ["items/trade_goods"] = {
    title = "Trade Goods",
    parent = "items",
    folders = {
      { path = "items/sub/Herbs", name = "Herbs", desc = "Gathered herbs & plants", icon = "Interface\\Icons\\INV_Misc_Herb_07", filter = { itemType = "Herb" } },
      { path = "items/sub/Ore", name = "Metal & Stone", desc = "Ores, bars & stones", icon = "Interface\\Icons\\INV_Ore_Iron_01", filter = { itemType = "Metal & Stone" } },
      { path = "items/sub/Parts", name = "Parts & Devices", desc = "Engineering parts & tools", icon = "Interface\\Icons\\INV_Misc_Gear_01", filter = { itemType = "Parts" } },
      { path = "items/sub/Reagents", name = "Reagents & Materials", desc = "Class & crafting reagents", icon = "Interface\\Icons\\INV_Misc_Dust_01", filter = { itemType = "Reagent" } },
    },
  },

  ["items/recipes"] = {
    title = "Recipes & Plans",
    parent = "items",
    folders = {
      { path = "items/sub/All Recipes", name = "All Recipes & Plans", desc = "Crafting Recipes & Manuals", icon = "Interface\\Icons\\INV_Scroll_03", filter = { itemType = "Recipe" } },
    },
  },

  -- CREATURES HIERARCHY
  ["creatures"] = {
    title = "Creatures & Bosses",
    parent = "root",
    folders = {
      { path = "creatures/beasts", name = "Beasts", desc = "Bears, Wolves, Cats, Raptors & more", icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf" },
      { path = "creatures/demons", name = "Demons", desc = "Burning Legion demons & warlocks", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
      { path = "creatures/dragonkin", name = "Dragonkin", desc = "Black, Red, Green & Blue dragonflights", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Red" },
      { path = "creatures/by_zone_ek", name = "Eastern Kingdoms (By Zone)", desc = "24 zones across Eastern Kingdoms", icon = "Interface\\Icons\\Spell_Frost_WindWalkOn" },
      { path = "creatures/elementals", name = "Elementals", desc = "Fire, Water, Earth & Air elementals", icon = "Interface\\Icons\\Spell_Fire_Fire" },
      { path = "creatures/giants", name = "Giants", desc = "Giants, Ogres & Mountain Colossi", icon = "Interface\\Icons\\Ability_Racial_Avatar" },
      { path = "creatures/humanoids", name = "Humanoids", desc = "Bandits, Pirates, Cultists & more", icon = "Interface\\Icons\\Ability_Racial_ShadowMeld" },
      { path = "creatures/by_zone_kalimdor", name = "Kalimdor (By Zone)", desc = "20 zones across Kalimdor", icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow" },
      { path = "creatures/rares", name = "Rare & Rare Elite Encounters", desc = "Silver-dragon rare spawns", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze" },
      { path = "creatures/undead", name = "Undead", desc = "Scourge, Skeletons, Ghosts & Ghouls", icon = "Interface\\Icons\\Spell_DeathKnight_ArmyOfTheDead" },
      { path = "creatures/bosses", name = "World & Dungeon Bosses", desc = "Major encounter bosses", icon = "Interface\\Icons\\Spell_Shadow_SummonDoomGuard" },
      { path = "creatures/forever", name = "[Forever] Forever Exclusive NPCs", desc = "Exclusive server encounters & bosses", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    },
  },

  -- DUNGEONS HIERARCHY
  ["dungeons"] = {
    title = "Dungeons & Raids",
    parent = "root",
    folders = {
      { path = "dungeons/available", name = "Available Dungeons", desc = "Dungeons unlocked for your character's level", icon = "Interface\\Icons\\Spell_Holy_ElunesGrace" },
      { path = "dungeons/endgame", name = "Endgame Dungeons (Lvl 50-60)", desc = "BRD, LBRS, UBRS, Strath, Scholo, DM, ST", icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" },
      { path = "dungeons/mid", name = "Mid-Tier Dungeons (Lvl 30-50)", desc = "Gnomeregan, SM, RFK, RFD, Uldaman, ZF, Mara", icon = "Interface\\Icons\\Spell_Fire_Fireball02" },
      { path = "dungeons/raids", name = "Raid Dungeons (Lvl 60)", desc = "MC, Onyxia, BWL, ZG, AQ20, AQ40, Naxx", icon = "Interface\\Icons\\Spell_Fire_Fire" },
      { path = "dungeons/recommended", name = "Recommended Dungeons", desc = "Level-appropriate dungeons recommended for you", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
      { path = "dungeons/starter", name = "Starter Dungeons (Lvl 15-30)", desc = "Deadmines, WC, SFK, BFD, Stockade", icon = "Interface\\Icons\\Spell_Nature_Strength" },
      { path = "dungeons/forever", name = "[Forever] Forever Exclusive Dungeons", desc = "Crypts, Thanes, Roots, Hateforge, Rift...", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    },
  },

  -- VENDORS HIERARCHY
  ["vendors"] = {
    title = "Vendors & Flight Paths",
    parent = "root",
    folders = {
      { path = "vendors/all", name = "All World Vendors", desc = "Complete alphabetical catalog of all merchants", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
      { path = "vendors/flightpaths", name = "Flight Masters", desc = "Alliance & Horde Flight Masters", icon = "Interface\\Icons\\Ability_Hunter_EagleEye" },
      { path = "vendors/pvp", name = "PvP Quartermasters", desc = "Battlegrounds & Honor Vendors", icon = "Interface\\Icons\\INV_BannerPVP_02" },
      { path = "vendors/specialty", name = "Specialty & Rare Goods", desc = "Limited Recipes, Pets & Unique items", icon = "Interface\\Icons\\INV_Misc_Bag_07" },
    },
  },

  -- FOREVER EXCLUSIVE CONTENT
  ["forever"] = {
    title = "[Forever] Warcraft Forever Exclusives",
    parent = "root",
    folders = {
      { path = "forever/items", name = "Forever Gear & Items", desc = "Exclusive itemization & set pieces", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "forever/quests", name = "Forever Quests & Storylines", desc = "Exclusive narrative and story quests", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "forever/creatures", name = "Forever NPCs & Bosses", desc = "Exclusive encounters and rare mobs", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
      { path = "forever/dungeons", name = "Forever Dungeons & Raids", desc = "Exclusive instances & progressive raids", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
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
    if cur == "quests/available" then
      table.insert(trail, "|cff38bdf8Available (By Zone)|r")
    elseif cur == "quests/available/all" then
      table.insert(trail, "|cff38bdf8Available|r")
      table.insert(trail, "|cffffd24dAll Quests|r")
    elseif cur:find("^quests/available/(.+)$") then
      local zn = cur:match("^quests/available/(.+)$")
      table.insert(trail, "|cff38bdf8Available|r")
      table.insert(trail, "|cffffd24d" .. zn .. "|r")
    elseif cur == "quests/recommended" then
      table.insert(trail, "|cff20ff20Recommended (By Zone)|r")
    elseif cur == "quests/recommended/all" then
      table.insert(trail, "|cff20ff20Recommended|r")
      table.insert(trail, "|cffffd24dAll Quests|r")
    elseif cur:find("^quests/recommended/(.+)$") then
      local zn = cur:match("^quests/recommended/(.+)$")
      table.insert(trail, "|cff20ff20Recommended|r")
      table.insert(trail, "|cffffd24d" .. zn .. "|r")
    elseif cur == "quests/eastern_kingdoms" then
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
      table.insert(trail, "|cffffd24dAll Entries|r")
    elseif cur == "creatures/bosses" then table.insert(trail, "|cffffffffBosses|r")
    elseif cur == "creatures/rares" then table.insert(trail, "|cffffffffRares|r")
    elseif cur == "creatures/forever" then table.insert(trail, "|cffe6cc80[Forever] NPCs|r")
    elseif cur:find("^creatures/") then table.insert(trail, "|cffffd24d" .. cur:sub(11):gsub("^%l", string.upper) .. "|r")
    end
  elseif cur:find("^dungeons") then
    table.insert(trail, "|cff88aaccDungeons|r")
    if cur == "dungeons/available" then table.insert(trail, "|cff38bdf8Available|r")
    elseif cur == "dungeons/recommended" then table.insert(trail, "|cff20ff20Recommended|r")
    elseif cur == "dungeons/starter" then table.insert(trail, "|cffffffffStarter (15-30)|r")
    elseif cur == "dungeons/mid" then table.insert(trail, "|cffffffffMid-Tier (30-50)|r")
    elseif cur == "dungeons/endgame" then table.insert(trail, "|cffffffffEndgame (50-60)|r")
    elseif cur == "dungeons/raids" then table.insert(trail, "|cffffffffRaids (Lvl 60)|r")
    elseif cur == "dungeons/forever" then table.insert(trail, "|cffe6cc80[Forever] Instances|r")
    end
  elseif cur:find("^vendors") then
    table.insert(trail, "|cff88aaccVendors|r")
    if cur == "vendors/all" then table.insert(trail, "|cffffffffAll Vendors|r")
    elseif cur == "vendors/flightpaths" then table.insert(trail, "|cffffffffFlight Masters|r")
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
  if n:find("not used") or n:find("unused") or n:find("deprecated") or
     n:find("%[test%]") or n:find("%(test%)") or n:find("^test ") or n:find(" test$") or
     n:find("placeholder") or n:find("%[ph%]") or n:find("%[ph%[") or n:find("%(ph%)") or
     n:find("%(old%)") or n:find("%[old%]") or n:find("%(dnd%)") or n:find("%[dnd%]") or
     n:find("^dnd") or n:find("^monster %-") or n:find("^visual %-") or
     n:find("dummy") or n:find("trigger") or n:find("credit marker") or n:find("controller") or
     n:find("spawner") or n:find("qa %-") or n:find("invisible") or
     n:find("test mob") or n:find("test dude") or n:find("^world [a-z]+ trainer") or
     n:find(" form%f[%A]") or n:find("%(druid") or n:find("%(shapeshift") or n:find("form %(") then
    return true
  end
  return false
end

function FG:IsInternalItem(name)
  if not name then return true end
  local n = name:lower()
  if n:find("not used") or n:find("unused") or n:find("deprecated") or
     n:find("%[test%]") or n:find("%(test%)") or n:find("^test ") or n:find(" test$") or
     n:find("placeholder") or n:find("%[ph%]") or n:find("%(old%)") or n:find("%[old%]") or
     n:find("^monster %-") or n:find("^visual %-") or n:find("^qa %-") or
     n:find("^old") or n:find("^zzold") then
    return true
  end
  return false
end

function FG:IsInternalQuest(title)
  if not title then return true end
  local n = title:lower()
  if n:find("^dnd") or n:find("%(test%)") or n:find("%[test%]") or n:find("not used") or n:find("unused") then
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

  if content.HomeDashboard then
    content.HomeDashboard:Hide()
  end

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
      local countedVendors = {}
      if FG.Data.Vendors then
        for _, v in pairs(FG.Data.Vendors) do
          local vZone = v.zone
          if (vZone == "Azeroth" or vZone == "Eastern Kingdoms" or vZone == "Kalimdor" or not vZone) and v.name then
            local cObj = FG:FindCreatureByName(v.name)
            if cObj and cObj.zone then vZone = cObj.zone end
          end
          if vZone and vZone:lower() == pZoneLower then
            vCount = vCount + 1
            if v.name then countedVendors[v.name:lower()] = true end
          end
        end
      end
      if FG.Data.Flightpaths then
        for _, fp in pairs(FG.Data.Flightpaths) do
          if fp.zone and fp.zone:lower() == pZoneLower then
            vCount = vCount + 1
            if fp.name then countedVendors[fp.name:lower()] = true end
          end
        end
      end
      if FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          local inZone = c.zone and c.zone:lower() == pZoneLower
          local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
          if (inZone or inSub) and not FG:IsInternalCreature(c.name, c.family) then
            local vTitle = FG:GetVendorTitle(c)
            if vTitle and c.name and not countedVendors[c.name:lower()] then
              countedVendors[c.name:lower()] = true
              vCount = vCount + 1
            end
          end
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
      local isClosest = (cur == "nearby/closest")
      local showQuests = (cur == "nearby/quests") or isClosest or (isNearbyRoot and q ~= "")
      local showRares = (cur == "nearby/rares") or (cur == "nearby/creatures/rares") or isClosest or (isNearbyRoot and q ~= "")
      local showBeasts = (cur == "nearby/creatures/beasts")
      local showHumanoids = (cur == "nearby/creatures/humanoids")
      local showAllCreatures = (cur == "nearby/creatures/all") or (cur == "nearby/creatures" and q ~= "") or isClosest or (isNearbyRoot and q ~= "")
      local showCreatures = showAllCreatures or showBeasts or showHumanoids or showRares
      local showVendors = (cur:find("^nearby/vendors") ~= nil) or isClosest or (isNearbyRoot and q ~= "")
      local showDungeons = (cur == "nearby/dungeons") or isClosest or (isNearbyRoot and q ~= "")
      local showLoot = (cur == "nearby/loot") or (isNearbyRoot and q ~= "")
      local vendorSub = cur:match("^nearby/vendors/(.+)$")

      -- 1. Nearby Creatures & Mobs (with sub-grouping)
      if showCreatures and FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) then
            local isRare = (c.classification == "Boss" or c.classification == "World Boss" or c.classification == "Rare" or c.classification == "Rare Elite")
            local isBeast = (c.family and c.family:lower() == "beast")
            local isHumanoid = (c.family and c.family:lower() == "humanoid")
            
            local passesSubFilter = true
            if cur == "nearby/rares" or cur == "nearby/creatures/rares" then
              passesSubFilter = isRare
            elseif showBeasts then
              passesSubFilter = isBeast and not isRare
            elseif showHumanoids then
              passesSubFilter = isHumanoid and not isRare
            elseif isClosest then
              passesSubFilter = (c.coords and c.coords ~= "")
            end

            if passesSubFilter then
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

      -- 2. Nearby Quests
      if showQuests and FG.Data.Quests then
        for _, quest in pairs(FG.Data.Quests) do
          if not FG:IsInternalQuest(quest.title) then
            local inZone = quest.zone and quest.zone:lower() == pZoneLower
            local inSub = pSubLower ~= "" and ((quest.zone and quest.zone:lower():find(pSubLower, 1, true)) or (quest.npc and quest.npc:lower():find(pSubLower, 1, true)))
            if inZone or inSub then
              if q == "" or (quest.title and quest.title:lower():find(q, 1, true)) then
                table.insert(matches, { type = "quest", data = quest, isNearby = true })
              end
            end
          end
        end
      end

      -- 3. Nearby Vendors & Flight Masters
      if showVendors then
        local addedVendors = {}
        local wantFlight = (vendorSub == "flight")
        local wantRepairs = (vendorSub == "repairs")
        local wantReagents = (vendorSub == "reagents")

        if (not wantRepairs and not wantReagents) and FG.Data.Flightpaths then
          for _, fp in pairs(FG.Data.Flightpaths) do
            local inZone = fp.zone and fp.zone:lower() == pZoneLower
            if inZone then
              local vData = { name = fp.name, zone = fp.zone, coords = fp.coords, item = fp.faction .. " Flight Master", tip = fp.notes or fp.connections }
              if q == "" or (fp.name and fp.name:lower():find(q, 1, true)) then
                table.insert(matches, { type = "vendor", data = vData, isNearby = true })
                if fp.name then addedVendors[fp.name:lower()] = true end
              end
            end
          end
        end

        if not wantFlight and FG.Data.Vendors then
          for _, v in pairs(FG.Data.Vendors) do
            local vZone = v.zone
            if (vZone == "Azeroth" or vZone == "Eastern Kingdoms" or vZone == "Kalimdor" or not vZone) and v.name then
              local cObj = FG:FindCreatureByName(v.name)
              if cObj and cObj.zone then vZone = cObj.zone end
            end
            local inZone = vZone and vZone:lower() == pZoneLower
            if inZone then
              local itemLower = (v.item or ""):lower()
              local passSub = true
              if wantRepairs then
                passSub = itemLower:find("repair") or itemLower:find("blacksmith") or itemLower:find("weaponsmith") or itemLower:find("armorsmith")
              elseif wantReagents then
                passSub = itemLower:find("reagent") or itemLower:find("poison") or itemLower:find("potion") or itemLower:find("herb") or itemLower:find("alchemy")
              end
              if passSub and (q == "" or (v.name and v.name:lower():find(q, 1, true)) or (v.item and v.item:lower():find(q, 1, true))) then
                table.insert(matches, { type = "vendor", data = v, isNearby = true })
                if v.name then addedVendors[v.name:lower()] = true end
              end
            end
          end
        end

        if FG.Data.Creatures then
          for _, c in pairs(FG.Data.Creatures) do
            local inZone = c.zone and c.zone:lower() == pZoneLower
            local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
            if (inZone or inSub) and not FG:IsInternalCreature(c.name, c.family) then
              local vTitle = FG:GetVendorTitle(c)
              if vTitle and c.name and not addedVendors[c.name:lower()] then
                local vLower = vTitle:lower()
                local passSub = true
                if wantFlight then
                  passSub = vLower:find("flight") or vLower:find("wind rider") or vLower:find("gryphon") or vLower:find("bat")
                elseif wantRepairs then
                  passSub = vLower:find("repair") or vLower:find("blacksmith") or vLower:find("weaponsmith") or vLower:find("armorsmith")
                elseif wantReagents then
                  passSub = vLower:find("reagent") or vLower:find("poison") or vLower:find("potion") or vLower:find("herb") or vLower:find("alchemy")
                end
                if passSub and (q == "" or c.name:lower():find(q, 1, true) or vTitle:lower():find(q, 1, true)) then
                  local vData = {
                    name = c.name,
                    zone = c.zone or pZone,
                    coords = c.coords,
                    item = vTitle,
                    tip = "<" .. vTitle .. ">" .. ((c.minLevel and c.minLevel > 0) and (" • Level " .. c.minLevel) or ""),
                  }
                  table.insert(matches, { type = "vendor", data = vData, isNearby = true })
                  addedVendors[c.name:lower()] = true
                end
              end
            end
          end
        end
      end

      -- 4. Nearby Dungeons
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
          if not FG:IsInternalItem(item.name) then
            local inSource = item.source and item.source:lower():find(pZoneLower, 1, true)
            if inSource then
              if q == "" or (item.name and item.name:lower():find(q, 1, true)) then
                table.insert(matches, { type = "item", data = item, isNearby = true })
              end
            end
          end
        end
      end
    end

  elseif q == "" then
    -- Browsing current Dolphin folder
    local folderDef = FG.FolderTree[cur]
    if folderDef and folderDef.folders then
      local slotCounts = nil
      local armorType = cur:match("^items/armor/([^/]+)$")
      if armorType and FG.Data.Items then
        slotCounts = {}
        for _, item in pairs(FG.Data.Items) do
          local name = item.name or ""
          local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
          if not FG:IsInternalItem(name) and not isRecipe and item.itemType and item.itemType:lower():find(armorType) then
            if item.slot then
              slotCounts[item.slot] = (slotCounts[item.slot] or 0) + 1
            end
          end
        end
      end

      for _, f in ipairs(folderDef.folders) do
        local fCopy = f
        if slotCounts and f.path then
          local slot = f.path:match("^items/armor/[^/]+/([^/]+)$")
          if slot and slotCounts[slot] then
            local count = slotCounts[slot]
            local armorCap = armorType:gsub("^%l", string.upper)
            fCopy = {
              name = f.name,
              path = f.path,
              desc = string.format("%d %s %s items (iLvl Low to High)", count, armorCap, f.name or slot),
              count = count,
              icon = f.icon,
            }
          end
        end
        table.insert(matches, { type = "folder", data = fCopy })
      end
    end

    -- Leaf folders: populate matching data items
    if cur == "quests/available" and FG.Data.Quests then
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      local zoneCounts = {}
      local totalCount = 0
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local req = quest.reqLevel or 1
          if pLevel == 0 or pLevel >= req then
            totalCount = totalCount + 1
            local z = quest.zone or "Other"
            zoneCounts[z] = (zoneCounts[z] or 0) + 1
          end
        end
      end

      table.insert(matches, {
        type = "folder",
        data = {
          name = "[All Available Quests (Full List)]",
          path = "quests/available/all",
          desc = string.format("%d total available quests across Azeroth", totalCount),
          count = totalCount,
          isAll = true,
          icon = "Interface\\Icons\\Spell_Holy_ElunesGrace",
        }
      })

      local sortedZones = {}
      for z in pairs(zoneCounts) do
        table.insert(sortedZones, z)
      end
      table.sort(sortedZones, function(a, b) return a:lower() < b:lower() end)

      for _, zn in ipairs(sortedZones) do
        local count = zoneCounts[zn] or 0
        table.insert(matches, {
          type = "folder",
          data = {
            name = zn,
            path = "quests/available/" .. zn,
            desc = string.format("%d available quests in %s", count, zn),
            count = count,
            icon = "Interface\\Icons\\INV_Misc_Map02",
          }
        })
      end
    elseif cur == "quests/available/all" and FG.Data.Quests then
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      local seen = {}
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local req = quest.reqLevel or 1
          if pLevel == 0 or pLevel >= req then
            local qKey = quest.id or quest.title
            if not seen[qKey] then
              seen[qKey] = true
              table.insert(matches, { type = "quest", data = quest })
            end
          end
        end
      end
    elseif cur:find("^quests/available/(.+)$") and FG.Data.Quests then
      local targetZone = cur:match("^quests/available/(.+)$")
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      local seen = {}
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone == targetZone then
          local req = quest.reqLevel or 1
          if pLevel == 0 or pLevel >= req then
            local qKey = quest.id or quest.title
            if not seen[qKey] then
              seen[qKey] = true
              table.insert(matches, { type = "quest", data = quest })
            end
          end
        end
      end
    elseif cur == "quests/recommended" and FG.Data.Quests then
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      local zoneCounts = {}
      local totalCount = 0
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local qLvl = quest.questLevel or quest.reqLevel or 1
          local req = quest.reqLevel or 1
          if pLevel == 0 or (pLevel >= req and math.abs(pLevel - qLvl) <= 4) then
            totalCount = totalCount + 1
            local z = quest.zone or "Other"
            zoneCounts[z] = (zoneCounts[z] or 0) + 1
          end
        end
      end

      table.insert(matches, {
        type = "folder",
        data = {
          name = "[All Recommended Quests (Full List)]",
          path = "quests/recommended/all",
          desc = string.format("%d recommended quests matching your level", totalCount),
          count = totalCount,
          isAll = true,
          icon = "Interface\\Icons\\Spell_Holy_MindVision",
        }
      })

      local sortedZones = {}
      for z in pairs(zoneCounts) do
        table.insert(sortedZones, z)
      end
      table.sort(sortedZones, function(a, b) return a:lower() < b:lower() end)

      for _, zn in ipairs(sortedZones) do
        local count = zoneCounts[zn] or 0
        table.insert(matches, {
          type = "folder",
          data = {
            name = zn,
            path = "quests/recommended/" .. zn,
            desc = string.format("%d recommended quests in %s", count, zn),
            count = count,
            icon = "Interface\\Icons\\INV_Misc_Map02",
          }
        })
      end
    elseif cur == "quests/recommended/all" and FG.Data.Quests then
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      local seen = {}
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local qLvl = quest.questLevel or quest.reqLevel or 1
          local req = quest.reqLevel or 1
          if pLevel == 0 or (pLevel >= req and math.abs(pLevel - qLvl) <= 4) then
            local qKey = quest.id or quest.title
            if not seen[qKey] then
              seen[qKey] = true
              table.insert(matches, { type = "quest", data = quest })
            end
          end
        end
      end
    elseif cur:find("^quests/recommended/(.+)$") and FG.Data.Quests then
      local targetZone = cur:match("^quests/recommended/(.+)$")
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      local seen = {}
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone == targetZone then
          local qLvl = quest.questLevel or quest.reqLevel or 1
          local req = quest.reqLevel or 1
          if pLevel == 0 or (pLevel >= req and math.abs(pLevel - qLvl) <= 4) then
            local qKey = quest.id or quest.title
            if not seen[qKey] then
              seen[qKey] = true
              table.insert(matches, { type = "quest", data = quest })
            end
          end
        end
      end
    elseif cur == "quests/active" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local st = FG:GetQuestStatus(quest.id, quest.title)
          if st == "active" or st == "ready_to_turn_in" then
            table.insert(matches, { type = "quest", data = quest })
          end
        end
      end
    elseif cur == "quests/uncompleted" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local st = FG:GetQuestStatus(quest.id, quest.title)
          if st == "uncompleted" then
            table.insert(matches, { type = "quest", data = quest })
          end
        end
      end
    elseif cur == "quests/completed" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local st = FG:GetQuestStatus(quest.id, quest.title)
          if st == "completed" then
            table.insert(matches, { type = "quest", data = quest })
          end
        end
      end
    elseif cur:find("^quests/zone/") and FG.Data.Quests then
      local zoneName = cur:sub(13)
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone == zoneName then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur:find("^quests/class/") and FG.Data.Quests then
      local classZone = cur:sub(14)
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone == classZone then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur:find("^quests/prof/") and FG.Data.Quests then
      local profZone = cur:sub(13)
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone == profZone then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur == "quests/dungeons" and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone and (quest.zone:find("Deadmines") or quest.zone:find("Wailing") or quest.zone:find("Shadowfang") or
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
        if not FG:IsInternalQuest(quest.title) and quest.isForever then
          table.insert(matches, { type = "quest", data = quest })
        end
      end
    elseif cur == "items/forever" and FG.Data.Items then
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        if not FG:IsInternalItem(item.name) and item.isForever then
          local key = item.id or item.name
          if not seen[key] then
            seen[key] = true
            table.insert(matches, { type = "item", data = item })
          end
        end
      end
    elseif cur:find("^items/armor/([^/]+)/([^/]+)$") and FG.Data.Items then
      local armorType, slotName = cur:match("^items/armor/([^/]+)/([^/]+)$")
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe and item.itemType and item.itemType:lower():find(armorType) then
          if item.slot and item.slot == slotName then
            local key = item.id or (name .. ":" .. (item.ilvl or 0))
            if not seen[key] then
              seen[key] = true
              table.insert(matches, { type = "item", data = item })
            end
          end
        end
      end
    elseif (not (folderDef and folderDef.folders)) and cur:find("^items/armor/([^/]+)$") and FG.Data.Items then
      local armorType = cur:match("^items/armor/([^/]+)$")
      local armorCap = armorType:gsub("^%l", string.upper)
      local slotCounts = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe and item.itemType and item.itemType:lower():find(armorType) then
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
          local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
          if not FG:IsInternalItem(name) and not isRecipe and item.itemType and item.itemType:lower():find(aType) and item.slot then
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
        local seen = {}
        for _, item in pairs(FG.Data.Items) do
          local name = item.name or ""
          if not FG:IsInternalItem(name) then
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
              local key = item.id or (name .. ":" .. (item.ilvl or 0))
              if not seen[key] then
                seen[key] = true
                table.insert(matches, { type = "item", data = item })
              end
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
            desc = string.format("%d creatures in %s", count, zn),
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
            desc = string.format("%d creatures in %s", count, zn),
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
              desc = string.format("%d %s in %s", count, fam:gsub("^%l", string.upper), zn),
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
              desc = string.format("%d %s in %s", count, fam:gsub("^%l", string.upper), zn),
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
          desc = string.format("%s in Eastern Kingdoms zones", famCap),
          icon = "Interface\\Icons\\INV_Misc_Map02",
        }
      })
      table.insert(matches, {
        type = "folder",
        data = {
          name = "Kalimdor (By Zone)",
          path = "creatures/" .. sub .. "/kalimdor",
          desc = string.format("%s in Kalimdor zones", famCap),
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
      local pLevel = (UnitLevel and UnitLevel("player")) or 0
      for _, d in pairs(FG.Data.Dungeons) do
        local pass = false
        local minLvl = d.minLevel or 0
        local maxLvl = d.maxLevel or 60
        if sub == "available" then
          pass = (pLevel == 0 or pLevel >= minLvl)
        elseif sub == "recommended" then
          pass = (pLevel == 0 or (pLevel >= minLvl and pLevel <= maxLvl))
        elseif sub == "starter" and minLvl <= 25 and not d.isForever then pass = true
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
          if item.isForever and not FG:IsInternalItem(item.name) then table.insert(matches, { type = "item", data = item }) end
        end
      elseif sub == "quests" and FG.Data.Quests then
        for _, quest in pairs(FG.Data.Quests) do
          if quest.isForever and not FG:IsInternalQuest(quest.title) then table.insert(matches, { type = "quest", data = quest }) end
        end
      elseif sub == "creatures" and FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if c.isForever and not FG:IsInternalCreature(c.name, c.family) then table.insert(matches, { type = "creature", data = c }) end
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
        if not FG:IsInternalItem(item.name) and item.name and (item.name:lower():find(q, 1, true) or (item.source and item.source:lower():find(q, 1, true))) then
          table.insert(matches, { type = "item", data = item })
        end
      end
    end

    if (cat == "all" or cat == "quests") and FG.Data.Quests then
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) then
          local matchTitle = quest.title and quest.title:lower():find(q, 1, true)
          local matchNpc = quest.npc and quest.npc:lower():find(q, 1, true)
          local matchZone = quest.zone and quest.zone:lower():find(q, 1, true)
          local matchObj = quest.objectives and quest.objectives:lower():find(q, 1, true)
          local matchTip = quest.tip and quest.tip:lower():find(q, 1, true)
          local matchStatus = false
          if q == "completed" or q == "done" then
            matchStatus = (FG:GetQuestStatus(quest.id, quest.title) == "completed")
          elseif q == "uncompleted" or q == "incomplete" then
            matchStatus = (FG:GetQuestStatus(quest.id, quest.title) == "uncompleted")
          elseif q == "active" or q == "in progress" then
            local st = FG:GetQuestStatus(quest.id, quest.title)
            matchStatus = (st == "active" or st == "ready_to_turn_in")
          end
          if matchTitle or matchNpc or matchZone or matchObj or matchTip or matchStatus then
            table.insert(matches, { type = "quest", data = quest })
          end
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

    if (cat == "all" or cat == "vendors") then
      local addedGlobalVendors = {}
      if FG.Data.Vendors then
        for _, v in pairs(FG.Data.Vendors) do
          local vZone = v.zone
          if (vZone == "Azeroth" or vZone == "Eastern Kingdoms" or vZone == "Kalimdor" or not vZone) and v.name then
            local cObj = FG:FindCreatureByName(v.name)
            if cObj and cObj.zone then vZone = cObj.zone end
          end
          local matchName = v.name and v.name:lower():find(q, 1, true)
          local matchItem = v.item and v.item:lower():find(q, 1, true)
          local matchZone = vZone and vZone:lower():find(q, 1, true)
          if matchName or matchItem or matchZone then
            table.insert(matches, { type = "vendor", data = v })
            if v.name then addedGlobalVendors[v.name:lower()] = true end
          end
        end
      end
      if FG.Data.Flightpaths then
        for _, fp in pairs(FG.Data.Flightpaths) do
          local matchName = fp.name and fp.name:lower():find(q, 1, true)
          local matchZone = fp.zone and fp.zone:lower():find(q, 1, true)
          if matchName or matchZone then
            local vData = { name = fp.name, zone = fp.zone, coords = fp.coords, item = fp.faction .. " Flight Master", tip = fp.notes or fp.connections }
            table.insert(matches, { type = "vendor", data = vData })
            if fp.name then addedGlobalVendors[fp.name:lower()] = true end
          end
        end
      end
      if FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) then
            local vTitle = FG:GetVendorTitle(c)
            if vTitle and c.name and not addedGlobalVendors[c.name:lower()] then
              local matchName = c.name and c.name:lower():find(q, 1, true)
              local matchTitle = vTitle and vTitle:lower():find(q, 1, true)
              local matchZone = c.zone and c.zone:lower():find(q, 1, true)
              if matchName or matchTitle or matchZone then
                local vData = {
                  name = c.name,
                  zone = c.zone,
                  coords = c.coords,
                  item = vTitle,
                  tip = "<" .. vTitle .. ">" .. ((c.minLevel and c.minLevel > 0) and (" • Level " .. c.minLevel) or ""),
                }
                table.insert(matches, { type = "vendor", data = vData })
                addedGlobalVendors[c.name:lower()] = true
              end
            end
          end
        end
      end
    end
  end

  -- Search match relevance scorer
  local function GetSearchMatchScore(match, query)
    local name = (match.data and (match.data.name or match.data.title or "")) or ""
    local nl = name:lower()
    if nl == query then return 1 end -- Exact match
    if nl:sub(1, #query) == query then return 2 end -- Prefix match
    local pos = nl:find(query, 1, true)
    if pos then
      local prevChar = (pos > 1) and nl:sub(pos - 1, pos - 1) or " "
      if prevChar:match("%s") or prevChar:match("[^%a%d]") then
        return 3 -- Word boundary in name
      end
      return 4 -- Substring in name
    end
    return 5 -- Secondary match (source, reagents, objectives, tooltip)
  end

  -- Sorting:
  -- 1. Folders always come first, sorted alphabetically A-Z.
  -- 2. When searching: All items matched first at the top, ranked by match quality!
  --    Followed by quests, creatures, dungeons, vendors.
  -- 3. When browsing: Items sorted by iLvl ascending; all other categories sorted strictly A-Z.
  local isItemView = (cur:find("^items") ~= nil) or (cat == "items") or (cur:find("^forever/items") ~= nil)
  table.sort(matches, function(a, b)
    if a.type == "folder" and b.type ~= "folder" then return true end
    if a.type ~= "folder" and b.type == "folder" then return false end
    if a.type == "folder" and b.type == "folder" then
      if a.data and a.data.isAll and not (b.data and b.data.isAll) then return true end
      if b.data and b.data.isAll and not (a.data and a.data.isAll) then return false end
      local nameA = (a.data and (a.data.title or a.data.name or "")) or ""
      local nameB = (b.data and (b.data.title or b.data.name or "")) or ""
      return nameA:lower() < nameB:lower()
    end

    if q ~= "" then
      -- User mandate: All items should be matched first at top!
      local typeRankA = (a.type == "item" and 1) or (a.type == "quest" and 2) or (a.type == "creature" and 3) or (a.type == "dungeon" and 4) or 5
      local typeRankB = (b.type == "item" and 1) or (b.type == "quest" and 2) or (b.type == "creature" and 3) or (b.type == "dungeon" and 4) or 5
      if typeRankA ~= typeRankB then
        return typeRankA < typeRankB
      end

      -- Within the same type, best match relevance tier comes first
      local scoreA = GetSearchMatchScore(a, q)
      local scoreB = GetSearchMatchScore(b, q)
      if scoreA ~= scoreB then
        return scoreA < scoreB
      end

      -- Within same type & score tier:
      if a.type == "item" and b.type == "item" then
        local nameA = (a.data and (a.data.name or a.data.title or "")) or ""
        local nameB = (b.data and (b.data.name or b.data.title or "")) or ""
        if nameA:lower() ~= nameB:lower() then
          return nameA:lower() < nameB:lower()
        end
        local ilvlA = tonumber(a.data and a.data.ilvl) or 0
        local ilvlB = tonumber(b.data and b.data.ilvl) or 0
        if ilvlA ~= ilvlB then return ilvlA < ilvlB end
      end

      local nameA = (a.data and (a.data.title or a.data.name or "")) or ""
      local nameB = (b.data and (b.data.title or b.data.name or "")) or ""
      return nameA:lower() < nameB:lower()
    end

    -- Folder browsing (q == ""):
    if isItemView and a.type == "item" and b.type == "item" then
      local ilvlA = tonumber(a.data and a.data.ilvl) or 0
      local ilvlB = tonumber(b.data and b.data.ilvl) or 0
      if ilvlA ~= ilvlB then
        return ilvlA < ilvlB
      end
    end

    local isNearbyView = (cur:find("^nearby") ~= nil) or (cat == "nearby") or a.isNearby or b.isNearby
    if isNearbyView then
      local coordsA = (a.data and a.data.coords) or (a.type == "quest" and a.data and a.data.npc and FG:FindCreatureByName(a.data.npc) and FG:FindCreatureByName(a.data.npc).coords) or nil
      local coordsB = (b.data and b.data.coords) or (b.type == "quest" and b.data and b.data.npc and FG:FindCreatureByName(b.data.npc) and FG:FindCreatureByName(b.data.npc).coords) or nil
      local distA = coordsA and select(1, FG:GetDistanceAndBearing(coordsA)) or nil
      local distB = coordsB and select(1, FG:GetDistanceAndBearing(coordsB)) or nil
      if distA and distB and math.abs(distA - distB) > 0.05 then
        return distA < distB
      elseif distA and not distB then
        return true
      elseif distB and not distA then
        return false
      end
    end

    local nameA = (a.data and (a.data.title or a.data.name or "")) or ""
    local nameB = (b.data and (b.data.title or b.data.name or "")) or ""
    return nameA:lower() < nameB:lower()
  end)

  -- Smart cross-category fallback:
  -- If searching within a specific category yielded 0 results (e.g. user searched "thunderfury" while on Vendors),
  -- automatically switch to "All" so the player gets the exact item or quest they were looking for!
  if #matches == 0 and cat ~= "all" and q ~= "" then
    FG:SetActiveCategory("all")
    return
  end

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
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " categories in view|r")
      elseif itemCount == #matches then
        if isItemView or cat == "items" then
          cw.StatusText:SetText("|cffdf80ff" .. countStr .. " items in view (iLvl: Lowest to Highest)|r")
        else
          cw.StatusText:SetText("|cffdf80ff" .. countStr .. " items in view|r")
        end
      elseif questCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " quests in view|r")
      elseif creatureCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " creatures in view|r")
      elseif dungeonCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " dungeons & raids in view|r")
      elseif folderCount > 0 and itemCount > 0 and (folderCount + itemCount == #matches) then
        cw.StatusText:SetText("|cffdf80ff" .. folderCount .. " categories, " .. itemCount .. " items in view|r")
      else
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " results in view|r")
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

-- Quest Progress & Turn-In Events: live sync of quest completion status
EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
EventFrame:RegisterEvent("QUEST_TURNED_IN")
EventFrame:RegisterEvent("QUEST_FINISHED")
EventFrame:RegisterEvent("QUEST_WATCH_UPDATE")

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

    print("|cffcf52ffForever Guide|r |cffdf80ff(Sparky)|r |cff00ff00[Alpha v0.1.0]|r loaded! Type |cffdf80ff/sparky|r to open Codex or |cffdf80ff/sparky help|r for commands.")

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
    if FG.CodexWindow and FG.CodexWindow:IsShown() then
      if FG.activeCategory == "nearby" or (FG.currentFolder == "root" and (not ForeverGuideSearchBox or ForeverGuideSearchBox:GetText():trim() == "")) then
        FG:PopulateCodexResults(ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or "")
      end
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

  elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" or event == "QUEST_FINISHED" or event == "QUEST_WATCH_UPDATE" then
    if FG.CodexWindow and FG.CodexWindow:IsShown() then
      local cat = FG.activeCategory
      local cur = FG.currentFolder
      if cat == "quests" or cat == "nearby" or (cur and (cur:find("^quests") or cur:find("^nearby"))) then
        FG:PopulateCodexResults(ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or "")
      end
    end
  end
end)

