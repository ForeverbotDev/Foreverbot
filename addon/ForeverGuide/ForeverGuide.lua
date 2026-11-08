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
  showMapPins = true,
  showMinimapPins = true,
  mapPinScale = 1.0,
  minimap = {
    hide = false,
    minimapPos = 215,
    radius = 80,
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

  -- Minimap Button Placement & Visibility (/spark minimap [outside|reset|hide|show])
  elseif cmd == "minimap" or cmd == "mapbtn" or cmd == "icon" then
    local subCmd = rest:lower()
    if subCmd == "reset" or subCmd == "outside" or subCmd == "rim" or subCmd == "fix" or subCmd == "inline" then
      ForeverGuideDB.minimap = ForeverGuideDB.minimap or {}
      ForeverGuideDB.minimap.radius = 80
      if FG.MinimapButton and FG.MinimapButton.UpdatePosition then
        FG.MinimapButton.UpdatePosition(ForeverGuideDB.minimap.minimapPos or 215)
      end
      print("|cffdf80ff[Sparky]|r Minimap button snapped inline with minimap border (radius 80).")
    elseif subCmd == "hide" or subCmd == "off" then
      if FG.MinimapButton then FG.MinimapButton:Hide() end
      ForeverGuideDB.minimap.hide = true
      print("|cffdf80ff[Sparky]|r Minimap button hidden. Type |cffcf52ff/spark minimap show|r to restore.")
    elseif subCmd == "show" or subCmd == "on" then
      if FG.MinimapButton then FG.MinimapButton:Show() end
      ForeverGuideDB.minimap.hide = false
      print("|cffdf80ff[Sparky]|r Minimap button shown.")
    else
      print("|cffdf80ff[Sparky]|r Minimap usage: |cffcf52ff/spark minimap [outside|reset|show|hide]|r")
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

  -- Armor Upgrades (/spark upgrade <query> or /spark upgrades or /spark gear or /spark armor)
  elseif cmd == "upgrade" or cmd == "upgrades" or cmd == "gear" or cmd == "armor" then
    if not FG.CodexWindow then FG:CreateCodexWindow() end
    FG.CodexWindow:Show()
    FG:SetActiveCategory("upgrades")
    if rest ~= "" and ForeverGuideSearchBox then
      ForeverGuideSearchBox:SetText(rest)
    end

  -- 3. Quests (/spark quest <query>)
  elseif cmd == "quest" or cmd == "q" then
    FG:CmdQuest(rest)

  -- 4. Mobs & Bosses (/spark mob <query> or /spark creature <query>)
  elseif cmd == "mob" or cmd == "mobs" or cmd == "creature" or cmd == "boss" then
    FG:CmdCreature(rest)

  -- 5. Dungeons & Raids (/spark dungeon <query> or /spark raid <query>)
  elseif cmd == "dungeon" or cmd == "dungeons" or cmd == "inst" then
    FG:CmdDungeon(rest)
  elseif cmd == "raid" then
    FG:CmdRaid(rest)

  -- Spells & Abilities (/spark spell <query> or /spark spells <query>)
  elseif cmd == "spell" or cmd == "spells" or cmd == "ability" or cmd == "abilities" then
    if not FG.CodexWindow then FG:CreateCodexWindow() end
    FG.CodexWindow:Show()
    FG:SetActiveCategory("spells")
    if rest ~= "" and ForeverGuideSearchBox then
      ForeverGuideSearchBox:SetText(rest)
    end

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

  -- 11. NPCs & Vendors (/spark npc <name> or /spark vendor <item>)
  elseif cmd == "npc" or cmd == "npcs" or cmd == "vendor" or cmd == "merchant" then
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

  -- 22. Quest Map Pins (/spark pins [on|off] or /spark map)
  elseif cmd == "pins" or cmd == "mappins" or cmd == "pin" then
    FG:CmdMapPins(rest)

  -- Help Manual
  else
    FG:PrintHelpManual()
  end
end

function FG:PrintHelpManual()
  print(" ")
  print("|cffdf80ff✨ [Forever Guide: Sparky] — In-Game Commands:|r")
  print("  |cffcf52ff/sparky|r or |cffcf52ff/spark|r - Open Forever Codex search window")
  print("  |cffcf52ff/spark pins [on|off]|r - Toggle Quest Pins on Zone Map and Minimap")
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

--------------------------------------------------------------------------------
-- Quest Map & Minimap Pins Engine (Blizzard MapCanvas & HereBeDragons)
--------------------------------------------------------------------------------

FG.ZONE_NAME_TO_MAP_ID = {
  ["dun morogh"] = 1426,
  ["elwynn forest"] = 1429,
  ["durotar"] = 1411,
  ["mulgore"] = 1412,
  ["tirisfal glades"] = 1420,
  ["teldrassil"] = 1438,
  ["westfall"] = 1436,
  ["loch modan"] = 1432,
  ["darkshore"] = 1439,
  ["silverpine forest"] = 1421,
  ["the barrens"] = 1413,
  ["redridge mountains"] = 1433,
  ["stonetalon mountains"] = 1442,
  ["ashenvale"] = 1440,
  ["duskwood"] = 1431,
  ["hillsbrad foothills"] = 1424,
  ["wetlands"] = 1437,
  ["thousand needles"] = 1441,
  ["alterac mountains"] = 1416,
  ["arathi highlands"] = 1417,
  ["badlands"] = 1418,
  ["swamp of sorrows"] = 1435,
  ["dustwallow marsh"] = 1445,
  ["desolace"] = 1443,
  ["stranglethorn vale"] = 1434,
  ["the hinterlands"] = 1425,
  ["tanaris"] = 1446,
  ["feralas"] = 1444,
  ["searing gorge"] = 1427,
  ["burning steppes"] = 1428,
  ["felwood"] = 1448,
  ["un'goro crater"] = 1449,
  ["western plaguelands"] = 1422,
  ["eastern plaguelands"] = 1423,
  ["winterspring"] = 1452,
  ["deadwind pass"] = 1430,
  ["silithus"] = 1451,
  ["moonglade"] = 1450,
  ["stormwind city"] = 1453,
  ["ironforge"] = 1455,
  ["darnassus"] = 1457,
  ["orgrimmar"] = 1454,
  ["thunder bluff"] = 1456,
  ["undercity"] = 1458,
}

FG.MAP_ID_TO_ZONE_NAME = {}
for zName, mID in pairs(FG.ZONE_NAME_TO_MAP_ID) do
  FG.MAP_ID_TO_ZONE_NAME[mID] = zName:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest end)
end

function FG:GetZoneMapID(zoneName)
  if not zoneName then return nil end
  local zLower = zoneName:lower()
  if FG.ZONE_NAME_TO_MAP_ID[zLower] then
    return FG.ZONE_NAME_TO_MAP_ID[zLower]
  end
  for mapID, name in pairs(FG.MAP_ID_TO_ZONE_NAME) do
    if name:lower():find(zLower, 1, true) or zLower:find(name:lower(), 1, true) then
      return mapID
    end
  end
  return nil
end

function FG:GetMapZoneName(mapID)
  if not mapID then return nil end
  if C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(mapID)
    if info and info.name and info.name ~= "" then
      return info.name
    end
  end
  return FG.MAP_ID_TO_ZONE_NAME[mapID]
end

function FG:GetQuestCoords(q)
  if not q then return nil end
  if q._cachedX and q._cachedY then
    return q._cachedX, q._cachedY
  end
  local cx, cy
  if q.coords and q.coords ~= "" then
    cx, cy = q.coords:match("(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
  end
  if (not cx or not cy) and q.npc and q.npc ~= "" then
    local c = FG:FindCreatureByName(q.npc)
    if c and c.coords and c.coords ~= "" then
      cx, cy = c.coords:match("(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
    end
  end
  if (not cx or not cy) and q.npc and q.npc ~= "" and FG.Data.Vendors then
    for _, v in pairs(FG.Data.Vendors) do
      if v.name and v.name:lower() == q.npc:lower() and v.coords and v.coords ~= "" then
        cx, cy = v.coords:match("(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
        if cx and cy then break end
      end
    end
  end
  if (not cx or not cy) and q.tip and q.tip ~= "" then
    cx, cy = q.tip:match("%((%d+%.?%d*)%s*,%s*(%d+%.?%d*)%)")
  end
  if cx and cy then
    q._cachedX = tonumber(cx)
    q._cachedY = tonumber(cy)
    return q._cachedX, q._cachedY
  end
  return nil
end

function FG:GetQuestDifficultyColor(qLevel, pLevel)
  local diff = (qLevel or 0) - (pLevel or 1)
  if diff >= 5 then
    return "|cffff2020" -- Red
  elseif diff >= 3 then
    return "|cffff7c0a" -- Orange
  elseif diff >= -2 then
    return "|cffffd100" -- Yellow
  elseif diff >= -7 then
    return "|cff20ff20" -- Green
  else
    return "|cff808080" -- Gray (Trivial)
  end
end

function FG:GetMapCanvas()
  if not WorldMapFrame then return nil end
  if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
    return WorldMapFrame.ScrollContainer.Child
  elseif WorldMapFrame.GetCanvas then
    return WorldMapFrame:GetCanvas()
  elseif WorldMapFrame.GetCanvasContainer then
    return WorldMapFrame:GetCanvasContainer()
  elseif WorldMapButton then
    return WorldMapButton
  end
  return WorldMapFrame
end

FG.MapPinPool = FG.MapPinPool or {}
FG.MinimapPinPool = FG.MinimapPinPool or {}
FG.ActiveMapPins = FG.ActiveMapPins or {}
FG.ActiveMinimapPins = FG.ActiveMinimapPins or {}

local function AcquireMapPin(isMinimap)
  local pool = isMinimap and FG.MinimapPinPool or FG.MapPinPool
  for _, pin in ipairs(pool) do
    if not pin.inUse then
      pin.inUse = true
      return pin
    end
  end

  local parent = isMinimap and Minimap or (FG:GetMapCanvas() or UIParent)
  local pin = CreateFrame("Button", nil, parent)
  pin:SetSize(20, 20)
  pin:SetFrameStrata(isMinimap and "MEDIUM" or "HIGH")
  pin:SetFrameLevel((parent:GetFrameLevel() or 10) + (isMinimap and 15 or 30))
  pin:EnableMouse(true)
  pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  local glow = pin:CreateTexture(nil, "BACKGROUND")
  glow:SetSize(28, 28)
  glow:SetPoint("CENTER", pin, "CENTER", 0, 0)
  glow:SetTexture("Interface\\Buttons\\WHITE8X8")
  glow:SetVertexColor(0.05, 0.05, 0.1, 0.75)
  pin.Glow = glow

  local halo = pin:CreateTexture(nil, "BORDER")
  halo:SetSize(26, 26)
  halo:SetPoint("CENTER", pin, "CENTER", 0, 0)
  halo:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockets")
  halo:SetTexCoord(0.395, 0.585, 0.02, 0.40)
  halo:SetVertexColor(0.85, 0.25, 1.0, 0.95)
  halo:Hide()
  pin.Halo = halo

  local icon = pin:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetPoint("CENTER", pin, "CENTER", 0, 0)
  icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
  pin.Icon = icon

  local badge = pin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  badge:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 4, -2)
  badge:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  badge:SetTextColor(1, 0.9, 0.2)
  pin.Badge = badge

  pin:SetScript("OnEnter", function(self)
    if not self.questList or #self.questList == 0 then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local pLevel = (UnitLevel and UnitLevel("player")) or 1
    local npcName = self.npcName or (self.questList[1] and self.questList[1].npc) or "Quest Location"
    local qCount = #self.questList

    if qCount > 1 then
      GameTooltip:AddLine(string.format("|cffcf52ff✨ %s|r |cffffffff(%d Quests)|r", npcName, qCount), 1, 1, 1)
      GameTooltip:AddLine(string.format("|cff888899Coordinates: [%0.1f, %0.1f]|r", self.cx or 0, self.cy or 0), 0.8, 0.8, 0.8)
      GameTooltip:AddLine(" ")
      for i, q in ipairs(self.questList) do
        local diffColor = FG:GetQuestDifficultyColor(q.questLevel or pLevel, pLevel)
        local statusText = ""
        if q.status == "ready_to_turn_in" then
          statusText = " |cff20ff20[Ready to Turn In]|r"
        elseif q.status == "active" then
          statusText = " |cff38bdf8[Active / In Progress]|r"
        else
          statusText = " |cffffd24d[Available]|r"
        end
        local foreverTag = q.isForever and " |cffe6cc80[Forever]|r" or ""
        GameTooltip:AddLine(string.format("  • %s%s|r%s |cffaaaaaa(Lvl %d)|r%s", diffColor, q.title or "Quest", foreverTag, q.questLevel or 0, statusText))
      end
    else
      local q = self.questList[1]
      local diffColor = FG:GetQuestDifficultyColor(q.questLevel or pLevel, pLevel)
      local foreverTag = q.isForever and " |cffe6cc80[Forever Exclusive]|r" or ""
      GameTooltip:AddLine(string.format("%s%s|r%s", diffColor, q.title or "Quest", foreverTag), 1, 1, 1)
      GameTooltip:AddLine(string.format("|cff38bdf8Level:|r %d |cff888899(Req %d)|r", q.questLevel or 0, q.reqLevel or 0), 0.9, 0.9, 0.9)
      if npcName and npcName ~= "" then
        GameTooltip:AddLine(string.format("|cffffffffQuest Giver:|r %s", npcName), 0.9, 0.9, 0.9)
      end
      if self.cx and self.cy then
        GameTooltip:AddLine(string.format("|cff888899Coordinates:|r |cff38bdf8[%0.1f, %0.1f]|r in %s", self.cx, self.cy, q.zone or "Current Zone"), 0.8, 0.8, 0.8)
      end
      if q.status == "ready_to_turn_in" then
        GameTooltip:AddLine("|cff20ff20Status: Ready to Complete & Turn In!|r", 0.2, 1.0, 0.2)
      elseif q.status == "active" then
        GameTooltip:AddLine("|cff38bdf8Status: In Progress (Active in Quest Log)|r", 0.2, 0.8, 1.0)
      else
        GameTooltip:AddLine("|cffffd24dStatus: Available to Accept|r", 1.0, 0.85, 0.2)
      end
      if q.objectives and q.objectives ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffObjectives:|r", 1, 1, 1)
        GameTooltip:AddLine(q.objectives, 0.85, 0.85, 0.85, true)
      end
      if q.rewards and q.rewards ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffaa00Rewards:|r " .. q.rewards, 1, 0.85, 0.2, true)
      end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Track in Sparky Radar & Waypoints", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cffdf80ff<Shift-Left-Click>|r Inspect Quest in Forever Codex", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  pin:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  pin:SetScript("OnClick", function(self, button)
    if not self.questList or #self.questList == 0 then return end
    local q = self.questList[1]
    if IsShiftKeyDown() then
      FG:OpenCodex("quests")
      FG:ShowDetailPanel("quest", q)
      FG:PlaySparkSound("shimmer")
    else
      local targetName = self.npcName or q.npc or q.title
      FG:TrackEntityCoords(targetName, q.zone, string.format("%0.1f, %0.1f", self.cx, self.cy))
      FG:PlaySparkSound("pulse")
    end
  end)

  pin.inUse = true
  table.insert(pool, pin)
  return pin
end

function FG:ReleaseMapPins()
  for _, pin in ipairs(FG.ActiveMapPins) do
    pin:Hide()
    pin:ClearAllPoints()
    pin.inUse = false
  end
  wipe(FG.ActiveMapPins)

  for _, pin in ipairs(FG.ActiveMinimapPins) do
    pin:Hide()
    pin:ClearAllPoints()
    pin.inUse = false
  end
  wipe(FG.ActiveMinimapPins)

  local HBDPins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)
  if HBDPins then
    HBDPins:RemoveAllWorldMapIcons("ForeverGuide")
    HBDPins:RemoveAllMinimapIcons("ForeverGuide")
  end
end

function FG:UpdateMapPinsScale()
  if not FG.ActiveMapPins or #FG.ActiveMapPins == 0 then return end
  local canvas = FG:GetMapCanvas()
  if not canvas then return end
  local cw, ch = canvas:GetSize()
  if not cw or not ch or cw <= 0 or ch <= 0 then return end

  local canvasScale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale())
                   or (WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.GetCanvasScale and WorldMapFrame.ScrollContainer:GetCanvasScale())
                   or (canvas.GetScale and canvas:GetScale()) or 1
  if canvasScale <= 0 then canvasScale = 1 end
  local pinScale = (1.0 / canvasScale) * (ForeverGuideDB.mapPinScale or 1.0)

  for _, pin in ipairs(FG.ActiveMapPins) do
    if pin:IsShown() and pin.cx and pin.cy then
      pin:SetScale(pinScale)
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", canvas, "TOPLEFT", (cw * (pin.cx / 100)) / pinScale, -(ch * (pin.cy / 100)) / pinScale)
    end
  end
end

function FG:UpdateMapPins(forcedMapID)
  FG:ReleaseMapPins()
  if not ForeverGuideDB or ForeverGuideDB.showMapPins == false then
    return
  end
  if not WorldMapFrame or not WorldMapFrame:IsShown() then
    return
  end
  local canvas = FG:GetMapCanvas()
  if not canvas then return end
  local cw, ch = canvas:GetSize()
  if not cw or not ch or cw <= 0 or ch <= 0 then
    C_Timer.After(0.05, function() FG:UpdateMapPins(forcedMapID) end)
    return
  end

  local mapID = forcedMapID or (WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()) or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
  local zoneName = FG:GetMapZoneName(mapID)
  if not zoneName or zoneName == "" then return end
  local zoneLower = zoneName:lower()

  local pFaction = (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
  local pLevel = (UnitLevel and UnitLevel("player")) or 1

  local HBDPins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)
  if HBDPins then
    HBDPins:RemoveAllWorldMapIcons("ForeverGuide")
    HBDPins:RemoveAllMinimapIcons("ForeverGuide")
  end

  local coordGroups = {}
  if FG.Data.Quests then
    for _, q in pairs(FG.Data.Quests) do
      local qZone = (q.zone or ""):lower()
      if qZone == zoneLower or qZone:find(zoneLower, 1, true) or zoneLower:find(qZone, 1, true) then
        local qFaction = q.faction
        local factionMatch = (not qFaction or qFaction == "" or qFaction == "Both" or qFaction == pFaction)
        local reqLvl = q.reqLevel or 0
        local levelMatch = (pLevel >= reqLvl)
        local status = FG:GetQuestStatus(q.id, q.title)

        if factionMatch and levelMatch and status ~= "completed" then
          local cx, cy = FG:GetQuestCoords(q)
          if cx and cy and cx > 0 and cy > 0 and cx <= 100 and cy <= 100 then
            local key = string.format("%0.1f,%0.1f", cx, cy)
            coordGroups[key] = coordGroups[key] or { cx = cx, cy = cy, quests = {}, npc = q.npc }
            q.status = status
            table.insert(coordGroups[key].quests, q)
          end
        end
      end
    end
  end

  local canvasScale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale())
                   or (WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.GetCanvasScale and WorldMapFrame.ScrollContainer:GetCanvasScale())
                   or (canvas.GetScale and canvas:GetScale()) or 1
  if canvasScale <= 0 then canvasScale = 1 end
  local pinScale = (1.0 / canvasScale) * (ForeverGuideDB.mapPinScale or 1.0)

  for key, grp in pairs(coordGroups) do
    local pin = AcquireMapPin(false)
    pin:SetParent(canvas)
    pin:SetScale(pinScale)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT", (cw * (grp.cx / 100)) / pinScale, -(ch * (grp.cy / 100)) / pinScale)

    pin.questList = grp.quests
    pin.npcName = grp.npc
    pin.cx = grp.cx
    pin.cy = grp.cy

    local topStatus = "uncompleted"
    local hasForever = false
    for _, q in ipairs(grp.quests) do
      if q.isForever then hasForever = true end
      if q.status == "ready_to_turn_in" then
        topStatus = "ready_to_turn_in"
        break
      elseif q.status == "active" and topStatus ~= "ready_to_turn_in" then
        topStatus = "active"
      end
    end

    if topStatus == "ready_to_turn_in" then
      pin.Icon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
      pin.Icon:SetVertexColor(1, 1, 1, 1)
    elseif topStatus == "active" then
      pin.Icon:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon")
      pin.Icon:SetVertexColor(1, 1, 1, 1)
    else
      pin.Icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
      pin.Icon:SetVertexColor(1, 1, 1, 1)
    end

    if hasForever then
      pin.Halo:Show()
    else
      pin.Halo:Hide()
    end

    if #grp.quests > 1 then
      pin.Badge:SetText(#grp.quests)
      pin.Badge:Show()
    else
      pin.Badge:Hide()
    end

    pin:Show()
    table.insert(FG.ActiveMapPins, pin)

    if HBDPins and mapID and ForeverGuideDB.showMinimapPins ~= false then
      local mPin = AcquireMapPin(true)
      mPin.questList = grp.quests
      mPin.npcName = grp.npc
      mPin.cx = grp.cx
      mPin.cy = grp.cy
      mPin.Icon:SetTexture(pin.Icon:GetTexture())
      mPin.Icon:SetVertexColor(pin.Icon:GetVertexColor())
      if hasForever then mPin.Halo:Show() else mPin.Halo:Hide() end
      if #grp.quests > 1 then mPin.Badge:SetText(#grp.quests) mPin.Badge:Show() else mPin.Badge:Hide() end
      mPin:Show()
      HBDPins:AddMinimapIconMap("ForeverGuide", mPin, mapID, grp.cx / 100, grp.cy / 100, true)
      table.insert(FG.ActiveMinimapPins, mPin)
    end
  end
end

function FG:HideMapPins()
  FG:ReleaseMapPins()
end

function FG:CreateWorldMapToggleButton()
  if not WorldMapFrame or FG.WorldMapToggleBtn then return end

  local btn = CreateFrame("Button", "ForeverGuideWorldMapToggle", WorldMapFrame, "BackdropTemplate")
  btn:SetSize(22, 22)
  btn:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -36, -3)
  btn:SetFrameStrata("HIGH")
  btn:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 10) + 15)
  btn:EnableMouse(true)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  btn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  btn:SetBackdropColor(0.12, 0.08, 0.22, 0.92)
  btn:SetBackdropBorderColor(0.85, 0.25, 1.0, 0.90)

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(16, 16)
  icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
  icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
  btn.Icon = icon

  local function UpdateVisual()
    local enabled = ForeverGuideDB and (ForeverGuideDB.showMapPins ~= false)
    if enabled then
      icon:SetDesaturated(false)
      icon:SetVertexColor(1, 1, 1, 1)
      btn:SetBackdropBorderColor(0.85, 0.25, 1.0, 0.95)
    else
      icon:SetDesaturated(true)
      icon:SetVertexColor(0.5, 0.5, 0.5, 0.6)
      btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.7)
    end
  end

  btn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.24, 0.16, 0.40, 0.98)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    local enabled = ForeverGuideDB and (ForeverGuideDB.showMapPins ~= false)
    GameTooltip:AddLine("|cffcf52ffForever Guide: Quest Pins|r", 1, 1, 1)
    GameTooltip:AddLine(string.format("Status: %s", enabled and "|cff20ff20Enabled (Showing Quests)|r" or "|cffff4040Disabled (Hidden)|r"))
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffdf80ff<Left-Click>|r Toggle Quest Pins on World Map", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cffdf80ff<Right-Click>|r Open Forever Codex", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)

  btn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.08, 0.22, 0.92)
    GameTooltip:Hide()
  end)

  btn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      FG:ToggleCodex()
    else
      ForeverGuideDB.showMapPins = not (ForeverGuideDB.showMapPins ~= false)
      UpdateVisual()
      FG:PlaySparkSound(ForeverGuideDB.showMapPins and "shimmer" or "chirp")
      FG:UpdateMapPins()
      print(string.format("|cffdf80ff[Forever Guide]|r Quest map pins: %s.", ForeverGuideDB.showMapPins and "|cff20ff20Enabled|r" or "|cffff4040Disabled|r"))
    end
  end)

  UpdateVisual()
  FG.WorldMapToggleBtn = btn
end

function FG:HookWorldMap()
  if not WorldMapFrame then return end
  if FG.WorldMapHooked then return end
  FG.WorldMapHooked = true

  WorldMapFrame:HookScript("OnShow", function()
    FG:UpdateMapPins()
  end)
  WorldMapFrame:HookScript("OnHide", function()
    FG:HideMapPins()
  end)

  if WorldMapFrame.OnMapChanged then
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
      FG:UpdateMapPins()
    end)
  end

  if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("MapCanvas.MapSet", function(_, mapID)
      if WorldMapFrame:IsShown() then
        FG:UpdateMapPins(mapID)
      end
    end)
  end

  if WorldMapFrame.OnCanvasScaleChanged then
    hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", function()
      FG:UpdateMapPinsScale()
    end)
  end
  if WorldMapFrame.OnFrameSizeChanged then
    hooksecurefunc(WorldMapFrame, "OnFrameSizeChanged", function()
      FG:UpdateMapPinsScale()
    end)
  end

  FG:CreateWorldMapToggleButton()
end

function FG:InitMapPins()
  FG:HookWorldMap()
end

function FG:CmdMapPins(arg)
  arg = (arg or ""):lower():trim()
  if arg == "on" or arg == "enable" or arg == "1" then
    ForeverGuideDB.showMapPins = true
    ForeverGuideDB.showMinimapPins = true
    print("|cffdf80ff[Forever Guide]|r Quest map pins: |cff20ff20Enabled|r on World Map & Minimap.")
  elseif arg == "off" or arg == "disable" or arg == "0" then
    ForeverGuideDB.showMapPins = false
    ForeverGuideDB.showMinimapPins = false
    print("|cffdf80ff[Forever Guide]|r Quest map pins: |cffff4040Disabled|r.")
  else
    ForeverGuideDB.showMapPins = not (ForeverGuideDB.showMapPins ~= false)
    ForeverGuideDB.showMinimapPins = ForeverGuideDB.showMapPins
    print(string.format("|cffdf80ff[Forever Guide]|r Quest map pins toggled: %s.", ForeverGuideDB.showMapPins and "|cff20ff20Enabled|r" or "|cffff4040Disabled|r"))
  end
  if FG.WorldMapToggleBtn and FG.WorldMapToggleBtn.Icon then
    FG.WorldMapToggleBtn.Icon:SetDesaturated(not ForeverGuideDB.showMapPins)
  end
  FG:UpdateMapPins()
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

function FG:MatchesVendorSubtype(v, subType)
  if not v or not subType or subType == "all" then return true end
  local tip = (((v.tip or "") .. " " .. (v.item or ""))):lower()
  if subType == "flight" or subType == "flightpaths" then
    return tip:find("flight") or tip:find("gryphon") or tip:find("wind rider") or tip:find("bat handler")
  elseif subType == "repairs" then
    return tip:find("repair") or tip:find("blacksmith") or tip:find("weaponsmith") or tip:find("armorsmith") or tip:find("armorer") or tip:find("metalsmith") or tip:find("macecrafter") or tip:find("shield")
  elseif subType == "reagents" then
    return tip:find("reagent") or tip:find("alchemy") or tip:find("herbalism") or tip:find("poison") or tip:find("potion") or tip:find("herb")
  elseif subType == "food" then
    return tip:find("food") or tip:find("drink") or tip:find("innkeeper") or tip:find("bartender") or tip:find("baker") or tip:find("butcher") or tip:find("cook") or tip:find("ale") or tip:find("wine") or tip:find("vintner") or tip:find("fruit") or tip:find("fish") or tip:find("bread") or tip:find("meat") or tip:find("water")
  elseif subType == "weapons_armor" then
    return tip:find("weapon") or tip:find("armor") or tip:find("bowyer") or tip:find("gunsmith") or tip:find("blade") or tip:find("sword") or tip:find("axe") or tip:find("mace") or tip:find("cloth") or tip:find("leather") or tip:find("mail") or tip:find("plate") or tip:find("tailor") or tip:find("leatherwork")
  elseif subType == "tradesupplies" then
    return tip:find("trade supplies") or tip:find("general supplies") or tip:find("trade") or tip:find("supplies") or tip:find("tailor") or tip:find("leatherwork") or tip:find("engineer") or tip:find("mining") or tip:find("thread") or tip:find("dye") or tip:find("flux") or tip:find("bleach") or tip:find("spices")
  elseif subType == "trainers" then
    return tip:find("trainer") or tip:find("weapon master") or tip:find("riding instructor") or tip:find("pet trainer")
  elseif subType == "pvp" then
    return tip:find("quartermaster") or tip:find("officer") or tip:find("battleground") or tip:find("honor") or tip:find("pvp") or tip:find("sergeant") or tip:find("commander")
  elseif subType == "specialty" then
    return (v.limitedStock and v.limitedStock ~= "") or tip:find("specialty") or tip:find("rare") or tip:find("exotic") or tip:find("pet") or tip:find("mount")
  end
  return false
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

function FG:GetSpellIcon(s)
  if not s then return "Interface\\Icons\\INV_Misc_Book_09" end
  local sid = s.id
  if sid and sid > 0 then
    if C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(sid)
      if info and info.iconID and info.iconID > 0 then
        return info.iconID
      end
    elseif GetSpellInfo then
      local _, _, icon = GetSpellInfo(sid)
      if icon and icon ~= "" then
        return icon
      end
    end
  end
  local sIcon = s.icon
  if sIcon and sIcon ~= "" then
    sIcon = string.gsub(sIcon, "\\\\+", "\\")
    if not string.find(sIcon, "[/\\]") then
      sIcon = "Interface\\Icons\\" .. sIcon
    end
    return sIcon
  end
  return "Interface\\Icons\\INV_Misc_Book_09"
end

function FG:GetSpellDescription(s)
  if not s then return "" end
  local sid = s.id
  if sid and sid > 0 then
    if C_Spell and C_Spell.GetSpellDescription then
      local d = C_Spell.GetSpellDescription(sid)
      if d and d ~= "" then return d end
    elseif GetSpellDescription then
      local d = GetSpellDescription(sid)
      if d and d ~= "" then return d end
    end
  end
  local desc = s.desc
  if desc and desc ~= "" and not string.find(desc, "class ability trained at level") then
    return desc
  end
  return (s.class or "") .. " ability learned at level " .. (s.reqLevel or 1) .. "."
end

function FG:GetSpellCastingInfo(s)
  if not s then return "None / Passive", "Instant", "Melee / Self", "" end
  local cost = (s.cost and s.cost ~= "") and s.cost or nil
  local cast = (s.castTime and s.castTime ~= "") and s.castTime or nil
  local range = (s.range and s.range ~= "") and s.range or nil
  local cd = (s.cooldown and s.cooldown ~= "") and s.cooldown or ""

  local sid = s.id
  if sid and sid > 0 and (not cast or not range or not cost) then
    if C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(sid)
      if info then
        if not cast and info.castTime then
          cast = (info.castTime == 0) and "Instant" or string.format("%.1f sec cast", info.castTime / 1000)
        end
        if not range and info.maxRange then
          range = (info.maxRange == 0) and "Melee / Self" or string.format("%d yd range", info.maxRange)
        end
      end
    elseif GetSpellInfo then
      local _, _, _, cTime, minR, maxR = GetSpellInfo(sid)
      if not cast and cTime then
        cast = (cTime == 0) and "Instant" or string.format("%.1f sec cast", cTime / 1000)
      end
      if not range and maxR then
        range = (maxR == 0) and "Melee / Self" or string.format("%d yd range", maxR)
      end
    end
  end

  cost = cost or "None / Passive"
  cast = cast or "Instant"
  range = range or "Melee / Self"
  return cost, cast, range, cd
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
    -- Check if numeric quest ID
    local qId = item.source:match("Quest Reward:%s*(%d+)") or item.source:match("Quest:%s*(%d+)")
    if qId and FG.Data and FG.Data.Quests then
      local q = FG.Data.Quests[tonumber(qId)]
      if q and q.title then
        local zStr = (q.zone and q.zone ~= "") and (" (" .. q.zone .. ")") or ""
        return "Quest: " .. q.title .. zStr
      end
    end
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
    if item.source:find("^Quest Reward:%s*") then
      return "Quest: " .. item.source:gsub("^Quest Reward:%s*", "")
    end
    return item.source
  end
  return "World Drop"
end

function FG:IsArmorOrUpgradeItem(item)
  if not item then return false end
  local name = item.name or ""
  local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
  if isRecipe then return false end
  local aType = item.itemType and item.itemType:lower() or ""
  if aType:find("cloth") or aType:find("leather") or aType:find("mail") or aType:find("plate") or aType:find("shield") then
    return true
  end
  local slot = item.slot or ""
  if slot == "Back" or slot == "Finger" or slot == "Trinket" or slot == "Neck" or slot == "Held In Off-hand" or slot == "Shield" then
    return true
  end
  return false
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

  -- 11. Top Level Armor / Items / Upgrades
  if path:find("upgrade") or name:find("upgrade") then
    if path:find("recommended") or name:find("recommended") then return "Interface\\Icons\\Spell_Holy_MindVision" end
    if path:find("cloth") then return "Interface\\Icons\\INV_Chest_Cloth_23" end
    if path:find("leather") then return "Interface\\Icons\\INV_Chest_Leather_08" end
    if path:find("mail") then return "Interface\\Icons\\INV_Chest_Chain_15" end
    if path:find("plate") then return "Interface\\Icons\\INV_Chest_Plate03" end
    if path:find("accessories") then return "Interface\\Icons\\INV_Jewelry_Necklace_07" end
    if path:find("dungeon") then return "Interface\\Icons\\Spell_Shadow_Teleport" end
    if path:find("quest") then return "Interface\\Icons\\INV_Misc_Book_07" end
    return "Interface\\Icons\\INV_Chest_Plate03"
  end
  if path == "items/armor" or name == "armor" then return "Interface\\Icons\\INV_Chest_Plate03" end
  if path == "items" or name:find("item") then return "Interface\\Icons\\INV_Sword_04" end

  -- 12. Spells & Class Abilities
  if path:find("spells/druid") then return "Interface\\Icons\\Ability_Druid_Maul" end
  if path:find("spells/hunter") then return "Interface\\Icons\\INV_Weapon_Bow_07" end
  if path:find("spells/mage") then return "Interface\\Icons\\Spell_Fire_FlameBolt" end
  if path:find("spells/paladin") then return "Interface\\Icons\\Spell_Holy_HolyBolt" end
  if path:find("spells/priest") then return "Interface\\Icons\\Spell_Holy_PowerWordShield" end
  if path:find("spells/rogue") then return "Interface\\Icons\\Ability_Stealth" end
  if path:find("spells/shaman") then return "Interface\\Icons\\Spell_Nature_Lightning" end
  if path:find("spells/warlock") then return "Interface\\Icons\\Spell_Shadow_CurseOfTounges" end
  if path:find("spells/warrior") then return "Interface\\Icons\\Ability_Warrior_OffensiveStance" end
  if path:find("spells/racials") then return "Interface\\Icons\\Spell_Nature_Windfury" end
  if path:find("spells/forever") then return "Interface\\Icons\\Spell_Holy_MagicalSentry" end
  if path:find("spell") or name:find("spell") or name:find("ability") then return "Interface\\Icons\\Spell_Holy_MagicalSentry" end

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
    local displaySlot = nil
    local itemName = item.name or ""
    if item.slot and item.slot ~= "" and item.slot ~= "Non-equippable" and item.slot ~= "Consumable" then
      displaySlot = item.slot
    elseif item.itemType and item.itemType ~= "" and item.itemType ~= "Consumable" and item.itemType ~= "Miscellaneous" then
      displaySlot = item.itemType
    else
      -- Infer specific subtype from item name if slot/itemType was generic
      if itemName:find("Potion") or itemName:find("Draft") or itemName:find("Brew") or itemName:find("Tears") then displaySlot = "Potion"
      elseif itemName:find("Elixir") then displaySlot = "Elixir"
      elseif itemName:find("Flask") then displaySlot = "Flask"
      elseif itemName:find("Scroll") then displaySlot = "Scroll"
      elseif itemName:find("Bandage") or itemName:find("Anti%-Venom") then displaySlot = "Bandage"
      elseif itemName:find(" Oil") or itemName:find("Sharpening") or itemName:find("Weightstone") then displaySlot = "Oil / Buff"
      elseif item.itemType and item.itemType ~= "" then displaySlot = item.itemType
      end
    end
    if displaySlot then
      table.insert(parts, "|cff8ba5cc" .. displaySlot .. "|r")
    end
    if item.reqLvl and item.reqLvl > 0 then
      table.insert(parts, "|cff22c55eReq Lvl " .. item.reqLvl .. "|r")
    end

    local srcText = FG:GetItemRowSourceText(item)
    if srcText and srcText ~= "" and srcText ~= "World Drop" then
      table.insert(parts, "|cff38bdf8" .. srcText .. "|r")
    elseif item.bonding and item.bonding ~= "" then
      table.insert(parts, "|cff7e8c9e" .. item.bonding .. "|r")
    else
      table.insert(parts, "|cff7e8c9eWorld Drop|r")
    end

    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "item"
      btn.InspectBtn.entityData = item
    end

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.14, 0.18, 0.26, 0.95)
      self:SetBackdropBorderColor(0.45, 0.25, 0.85, 0.90)
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
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
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
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
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
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    end)
    btn:SetScript("OnClick", function()
      if IsShiftKeyDown() then
        FG:LinkEntityToChat("vendor", v)
      else
        FG:TrackEntityCoords(v.name, v.zone, v.coords)
        FG:PlaySparkSound("shimmer")
      end
    end)

  elseif match.type == "spell" then
    local s = match.data
    btn:SetHeight(50)
    btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
    btn:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
    btn.Hint:SetText("|cffcf52ffInspect >|r")
    if btn.InspectBtn then
      btn.InspectBtn:Show()
      btn.InspectBtn.onClick = nil
      btn.InspectBtn.entityType = "spell"
      btn.InspectBtn.entityData = s
    end

    if btn.IconFrame then
      btn.IconFrame:Show()
      local sIcon = FG:GetSpellIcon(s)
      btn.Icon:SetTexture(sIcon)
      btn.IconFrame:SetBackdropBorderColor(0.55, 0.22, 0.85, 0.9)
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

    local rankStr = (s.rank and s.rank ~= "") and (" |cff7e8c9e(" .. s.rank .. ")|r") or ""
    local foreverTag = s.isForever and " |cffe6cc80[Forever]|r" or ""
    btn.Title:SetText("|cffc084fc" .. (s.name or "Spell") .. "|r" .. rankStr .. foreverTag)

    local parts = {}
    if s.class and s.class ~= "" then
      table.insert(parts, "|cff38bdf8" .. s.class .. "|r")
    end
    if s.reqLevel and s.reqLevel > 0 then
      table.insert(parts, "|cff22c55eLevel " .. s.reqLevel .. "|r")
    end
    local costStr, castStr = FG:GetSpellCastingInfo(s)
    if costStr and costStr ~= "" and costStr ~= "None / Passive" then
      table.insert(parts, "|cff94a3b8" .. costStr .. "|r")
    end
    if castStr and castStr ~= "" then
      table.insert(parts, "|cff8ba5cc" .. castStr .. "|r")
    end
    btn.Sub:SetText(table.concat(parts, " |cff475569·|r "))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.14, 0.18, 0.26, 0.95)
      self:SetBackdropBorderColor(0.55, 0.25, 0.90, 0.90)
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
      self:SetBackdropBorderColor(0.18, 0.24, 0.33, 0.70)
      GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
      if IsShiftKeyDown() then
        FG:LinkEntityToChat("spell", s)
      else
        FG:ShowDetailPanel("spell", s)
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
  searchBox:SetSize(145, 24)
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

  searchBox.searchDelay = 0
  searchBox.pendingQuery = nil

  clearBtn:SetScript("OnClick", function()
    searchBox.searchDelay = 0
    searchBox.pendingQuery = nil
    searchBox.scopedSearchLock = nil
    searchBox:SetText("")
    searchBox:ClearFocus()
    clearBtn:Hide()
    placeholder:Show()
    FG:SetActiveCategory("all")
  end)

  searchBox:SetScript("OnUpdate", function(self, elapsed)
    if self.searchDelay and self.searchDelay > 0 then
      self.searchDelay = self.searchDelay - elapsed
      if self.searchDelay <= 0 then
        self.searchDelay = 0
        local query = self.pendingQuery
        self.pendingQuery = nil
        if query ~= nil then
          if query == "" then
            self.scopedSearchLock = nil
            placeholder:Show()
            clearBtn:Hide()
            FG:PopulateCodexResults("")
          else
            placeholder:Hide()
            clearBtn:Show()
            if FG.activeCategory ~= "all" and FG.activeCategory ~= "nearby" and FG.activeCategory ~= "upgrades" and not self.scopedSearchLock then
              FG:SetActiveCategory("all")
            else
              FG:PopulateCodexResults(query)
            end
          end
        end
      end
    end
  end)

  searchBox:SetScript("OnTextChanged", function(self)
    local query = self:GetText():trim()
    if query == "" then
      self.searchDelay = 0
      self.pendingQuery = nil
      self.scopedSearchLock = nil
      placeholder:Show()
      clearBtn:Hide()
      FG:PopulateCodexResults("")
    else
      placeholder:Hide()
      clearBtn:Show()
      self.pendingQuery = query
      self.searchDelay = 0.15 -- 150ms debounce for butter-smooth 60fps typing
    end
  end)

  searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local query = self:GetText():trim()
    self.searchDelay = 0
    self.pendingQuery = nil
    if query == "" then
      self.scopedSearchLock = nil
      placeholder:Show()
      clearBtn:Hide()
      FG:PopulateCodexResults("")
    else
      placeholder:Hide()
      clearBtn:Show()
      if FG.activeCategory ~= "all" and FG.activeCategory ~= "nearby" and FG.activeCategory ~= "upgrades" and not self.scopedSearchLock then
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

  local allBtn    = CreateCategoryPill("all", "All", 30, 5, searchBox)
  local nearbyBtn = CreateCategoryPill("nearby", "Nearby", 50, 3, allBtn)
  local itemsBtn  = CreateCategoryPill("items", "Items", 38, 3, nearbyBtn)
  local upgBtn    = CreateCategoryPill("upgrades", "Upgrades", 60, 3, itemsBtn)
  local questBtn  = CreateCategoryPill("quests", "Quests", 46, 3, upgBtn)
  local mobBtn    = CreateCategoryPill("creatures", "Mobs", 38, 3, questBtn)
  local dungBtn   = CreateCategoryPill("dungeons", "Dungeons", 58, 3, mobBtn)
  local npcBtn    = CreateCategoryPill("vendors", "NPCs", 40, 3, dungBtn)
  local spellBtn  = CreateCategoryPill("spells", "Spells", 42, 3, npcBtn)

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
    ["upgrades"] = "upgrades",
    ["quests"] = "quests",
    ["creatures"] = "creatures",
    ["dungeons"] = "dungeons",
    ["vendors"] = "vendors",
    ["spells"] = "spells",
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
  elseif entityType == "spell" then
    local rankStr = (data.rank and data.rank ~= "") and (" (" .. data.rank .. ")") or ""
    text = "[Spell: " .. (data.name or "Ability") .. rankStr .. " (Lvl " .. (data.reqLevel or "?") .. " " .. (data.class or "") .. ")]"
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

  elseif entityType == "spell" then
    local sIcon = FG:GetSpellIcon(data)
    if p.HeaderIcon then
      p.HeaderIcon:SetTexture(sIcon)
      p.HeaderIconFrame:SetBackdropBorderColor(0.65, 0.35, 1.0, 0.9)
    end
    p.Title:SetText("|cffcf52ffSpell & Ability Intel|r")
    local rankStr = (data.rank and data.rank ~= "") and (" |cff7e8c9e(" .. data.rank .. ")|r") or ""
    local foreverTag = data.isForever and " |cffe6cc80[Forever Alpha]|r" or ""
    AddLine("|cffc084fc" .. (data.name or "Spell") .. "|r" .. rankStr .. foreverTag, 15, nil, nil, nil, 6)

    AddLine("Class: |cff38bdf8" .. (data.class or "All") .. "|r  ·  Required: |cff22c55eLevel " .. (data.reqLevel or 1) .. "|r", 12)
    if data.id and data.id > 0 then
      AddLine("Spell ID: |cff94a3b8" .. data.id .. "|r", 11)
    end

    AddSection("CASTING & RESOURCE")
    local costStr, castStr, rangeStr, cdStr = FG:GetSpellCastingInfo(data)
    AddLine("Cost: |cffffffff" .. costStr .. "|r", 12)
    AddLine("Cast Time: |cff8ba5cc" .. castStr .. "|r  ·  Range: |cff38bdf8" .. rangeStr .. "|r", 12)
    if cdStr and cdStr ~= "" then
      AddLine("Cooldown: |cffffd100" .. cdStr .. "|r", 12)
    end

    AddSection("EFFECT & TOOLTIP")
    local descText = FG:GetSpellDescription(data)
    AddLine(descText, 11, 0.85, 0.90, 0.95, 6)

    if data.isForever then
      AddSection("WARCRAFT FOREVER ALPHA NOTES")
      AddLine("This ability or talent is custom created or reworked specifically for Warcraft Forever Alpha. Verified from client build data and patch notes.", 11, 1.0, 0.85, 0.40, 6)
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
      { path = "upgrades", name = "Armor Upgrades (By Type)", desc = "Cloth, Leather, Mail, Plate, Accessories & Where to obtain them", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "nearby", name = "Nearby Area Intel (Zone Radar)", desc = "Live radar: local mobs, quests, vendors & loot in current zone", icon = "Interface\\Icons\\Ability_Tracking" },
      { path = "quests", name = "Quests", desc = "By Continent, Zone, Class, & Dungeon", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "spells", name = "Spells & Abilities", desc = "Class abilities, ranks, Alpha talents & racial traits", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
      { path = "vendors", name = "Vendors & Flight Paths", desc = "Flight Masters, PvP Quartermasters & Reagents", icon = "Interface\\Icons\\Ability_Hunter_EagleEye" },
      { path = "forever", name = "[Forever] Warcraft Forever Exclusives", desc = "Exclusive items, quests, NPCs & dungeons", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    },
  },

  -- ARMOR UPGRADES HIERARCHY (Sorted by Type)
  ["upgrades"] = {
    title = "Armor Upgrades (Sorted by Type)",
    parent = "root",
    folders = {
      { path = "upgrades/recommended", name = "★ Recommended Upgrades (My Class)", desc = "Armor upgrades matching your current class and level", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
      { path = "upgrades/cloth", name = "Cloth Armor Upgrades", desc = "Mage, Priest & Warlock (Head, Shoulders, Chest, Legs, Boots...)", icon = "Interface\\Icons\\INV_Chest_Cloth_23" },
      { path = "upgrades/leather", name = "Leather Armor Upgrades", desc = "Rogue, Druid, Hunter & Shaman (Head, Shoulders, Chest, Legs...)", icon = "Interface\\Icons\\INV_Chest_Leather_08" },
      { path = "upgrades/mail", name = "Mail Armor Upgrades", desc = "Hunter, Shaman, Warrior & Paladin (Head, Shoulders, Chest, Legs...)", icon = "Interface\\Icons\\INV_Chest_Chain_15" },
      { path = "upgrades/plate", name = "Plate Armor Upgrades", desc = "Warrior & Paladin Level 40+ (Head, Shoulders, Chest, Legs...)", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "upgrades/accessories", name = "Jewelry, Cloaks & Shields", desc = "Cloaks, Rings, Trinkets, Necklaces & Off-Hand Shields", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07" },
      { path = "upgrades/dungeons", name = "Dungeon & Raid Armor Drops", desc = "Armor pieces dropped by dungeon and raid bosses", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
      { path = "upgrades/quests", name = "Quest Reward Armor", desc = "High-stat armor guaranteed from storyline & dungeon quests", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "upgrades/all", name = "[All Armor Upgrades (Full Catalog)]", desc = "Complete armor catalog sorted by Type, Slot, and Item Level", icon = "Interface\\Icons\\INV_Chest_Chain_05", isAll = true },
    },
  },

  ["upgrades/cloth"] = {
    title = "Cloth Armor Upgrades",
    parent = "upgrades",
    folders = {
      { path = "upgrades/cloth/Head", name = "Head (Circlets & Hoods)", desc = "Cloth headgear (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Helmet_08" },
      { path = "upgrades/cloth/Shoulder", name = "Shoulders (Mantles)", desc = "Cloth shoulderpads (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Shoulder_02" },
      { path = "upgrades/cloth/Chest", name = "Chest (Robes & Tunics)", desc = "Cloth robes and vests (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Chest_Cloth_23" },
      { path = "upgrades/cloth/Wrist", name = "Wrist (Bracers)", desc = "Cloth bracers & cuffs (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Bracer_07" },
      { path = "upgrades/cloth/Hands", name = "Hands (Gloves)", desc = "Cloth gloves & mitts (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Gauntlets_14" },
      { path = "upgrades/cloth/Waist", name = "Waist (Belts & Sashes)", desc = "Cloth belts & sashes (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Belt_03" },
      { path = "upgrades/cloth/Legs", name = "Legs (Pants & Robes)", desc = "Cloth pants & leggings (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Pants_08" },
      { path = "upgrades/cloth/Feet", name = "Feet (Boots & Slippers)", desc = "Cloth footwear (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Boots_05" },
    },
  },

  ["upgrades/leather"] = {
    title = "Leather Armor Upgrades",
    parent = "upgrades",
    folders = {
      { path = "upgrades/leather/Head", name = "Head (Helms & Caps)", desc = "Leather headgear (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Helmet_04" },
      { path = "upgrades/leather/Shoulder", name = "Shoulders (Spaulders)", desc = "Leather shoulder armor (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Shoulder_01" },
      { path = "upgrades/leather/Chest", name = "Chest (Jerkins & Vests)", desc = "Leather chestpieces (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Chest_Leather_08" },
      { path = "upgrades/leather/Wrist", name = "Wrist (Bracers)", desc = "Leather wristguards (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Bracer_06" },
      { path = "upgrades/leather/Hands", name = "Hands (Gloves & Grips)", desc = "Leather gloves (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Gauntlets_04" },
      { path = "upgrades/leather/Waist", name = "Waist (Belts & Girdles)", desc = "Leather belts (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Belt_02" },
      { path = "upgrades/leather/Legs", name = "Legs (Pants & Breeches)", desc = "Leather pants (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Pants_06" },
      { path = "upgrades/leather/Feet", name = "Feet (Boots)", desc = "Leather boots (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Boots_08" },
    },
  },

  ["upgrades/mail"] = {
    title = "Mail Armor Upgrades",
    parent = "upgrades",
    folders = {
      { path = "upgrades/mail/Head", name = "Head (Helms & Coifs)", desc = "Mail headgear (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Helmet_03" },
      { path = "upgrades/mail/Shoulder", name = "Shoulders (Pauldrons)", desc = "Mail pauldrons (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Shoulder_10" },
      { path = "upgrades/mail/Chest", name = "Chest (Hauberks & Mail)", desc = "Mail chest armor (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Chest_Chain_15" },
      { path = "upgrades/mail/Wrist", name = "Wrist (Bracers)", desc = "Mail bracers (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Bracer_16" },
      { path = "upgrades/mail/Hands", name = "Hands (Gauntlets)", desc = "Mail gauntlets (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Gauntlets_17" },
      { path = "upgrades/mail/Waist", name = "Waist (Belts & Girdles)", desc = "Mail belts (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Belt_12" },
      { path = "upgrades/mail/Legs", name = "Legs (Legguards)", desc = "Mail legplates (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Pants_03" },
      { path = "upgrades/mail/Feet", name = "Feet (Boots & Sabatons)", desc = "Mail footwear (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Boots_Plate_01" },
    },
  },

  ["upgrades/plate"] = {
    title = "Plate Armor Upgrades",
    parent = "upgrades",
    folders = {
      { path = "upgrades/plate/Head", name = "Head (Helms & Visors)", desc = "Plate helms (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Helmet_01" },
      { path = "upgrades/plate/Shoulder", name = "Shoulders (Pauldrons)", desc = "Plate pauldrons (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Shoulder_19" },
      { path = "upgrades/plate/Chest", name = "Chest (Breastplates)", desc = "Plate breastplates (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "upgrades/plate/Wrist", name = "Wrist (Bracers)", desc = "Plate bracers (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Bracer_19" },
      { path = "upgrades/plate/Hands", name = "Hands (Gauntlets)", desc = "Plate gauntlets (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Gauntlets_10" },
      { path = "upgrades/plate/Waist", name = "Waist (Belts & Girdles)", desc = "Plate belts (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Belt_15" },
      { path = "upgrades/plate/Legs", name = "Legs (Legplates)", desc = "Plate legplates (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Pants_04" },
      { path = "upgrades/plate/Feet", name = "Feet (Boots & Sabatons)", desc = "Plate sabatons (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Boots_Plate_01" },
    },
  },

  ["upgrades/accessories"] = {
    title = "Jewelry, Cloaks & Shields",
    parent = "upgrades",
    folders = {
      { path = "upgrades/acc/Cloaks", name = "Cloaks & Capes", desc = "Back slot cloaks (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Misc_Cape_19", filter = { slot = "Back" } },
      { path = "upgrades/acc/Amulets", name = "Amulets & Necklaces", desc = "Necklaces and pendants (iLvl Low to High) & Sources", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07", filter = { slot = "Neck" } },
      { path = "upgrades/acc/Rings", name = "Rings & Bands", desc = "Finger slot rings (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Jewelry_Ring_03", filter = { slot = "Finger" } },
      { path = "upgrades/acc/Trinkets", name = "Trinkets & Talismans", desc = "Trinket charms (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Jewelry_Talisman_07", filter = { slot = "Trinket" } },
      { path = "upgrades/acc/Shields", name = "Shields", desc = "Off-Hand Shields (iLvl Low to High) & Drop Sources", icon = "Interface\\Icons\\INV_Shield_04", filter = { itemType = "Shield" } },
      { path = "upgrades/acc/Off-hand", name = "Held In Off-hand", desc = "Caster off-hands and tomes (iLvl Low to High)", icon = "Interface\\Icons\\INV_Misc_Book_06", filter = { slot = "Held In Off-hand" } },
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
      { path = "nearby/creatures/beasts", name = "Beasts & Wildlife", desc = "Animals, predators, critters & wild creatures", icon = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider" },
      { path = "nearby/creatures/humanoids", name = "Humanoids & NPCs", desc = "Townsfolk, guards, outlaws & mortal factions", icon = "Interface\\Icons\\INV_Misc_Head_Centaur_01" },
      { path = "nearby/creatures/undead", name = "Undead & Scourge", desc = "Skeletons, ghouls, ghosts & walking dead", icon = "Interface\\Icons\\Spell_DeathKnight_ArmyOfTheDead" },
      { path = "nearby/creatures/elementals", name = "Elementals", desc = "Earth, Fire, Water & Air elementals", icon = "Interface\\Icons\\Spell_Fire_Fire" },
      { path = "nearby/creatures/demons", name = "Demons & Infernals", desc = "Burning Legion demons, felbeasts & imps", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
      { path = "nearby/creatures/dragonkin", name = "Dragonkin", desc = "Whelps, drakes, dragonspawn & wyrms", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Red" },
      { path = "nearby/creatures/giants", name = "Giants & Ogres", desc = "Colossi, ogres, ettins & mountain giants", icon = "Interface\\Icons\\Ability_Racial_Avatar" },
      { path = "nearby/creatures/rares", name = "Rares & Named Spawns", desc = "Rare elites and unique monsters in the zone", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_02" },
      { path = "nearby/creatures/all", name = "[All Creatures (Full Zone List)]", desc = "Complete list of all creatures in the zone", icon = "Interface\\Icons\\Ability_Tracking", isAll = true },
    },
  },

  ["nearby/vendors"] = {
    title = "Nearby Vendors & Flight Masters",
    parent = "nearby",
    folders = {
      { path = "nearby/vendors/flight", name = "Flight Masters", desc = "Flight points and wind rider / gryphon masters", icon = "Interface\\Icons\\Spell_Magic_FeatherFall" },
      { path = "nearby/vendors/repairs", name = "Repairs & Armorers", desc = "Blacksmiths and equipment repairers", icon = "Interface\\Icons\\Trade_BlackSmithing" },
      { path = "nearby/vendors/reagents", name = "Reagents & Alchemy Supplies", desc = "Herbs, potions, poisons and crafting goods", icon = "Interface\\Icons\\INV_Potion_33" },
      { path = "nearby/vendors/food", name = "Food & Drink Merchants", desc = "Innkeepers, barkeepers, butchers & bakers", icon = "Interface\\Icons\\INV_Misc_Food_14" },
      { path = "nearby/vendors/weapons_armor", name = "Weapons & Armor Vendors", desc = "Weaponsmiths, leatherworkers, tailors & armorers", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "nearby/vendors/tradesupplies", name = "Trade Supplies & Materials", desc = "Tailoring, leather, mining, thread & materials", icon = "Interface\\Icons\\INV_Fabric_Silk_02" },
      { path = "nearby/vendors/trainers", name = "Class & Profession Trainers", desc = "Class, trade skill, weapon & riding trainers", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
      { path = "nearby/vendors/pvp", name = "PvP Quartermasters", desc = "Battlegrounds & Honor Vendors", icon = "Interface\\Icons\\INV_BannerPVP_02" },
      { path = "nearby/vendors/specialty", name = "Specialty & Rare Goods", desc = "Limited Recipes, Pets & Unique items", icon = "Interface\\Icons\\INV_Misc_Bag_07" },
      { path = "nearby/vendors/all", name = "[All Vendors & Services]", desc = "All merchants and service providers in this zone", icon = "Interface\\Icons\\INV_Misc_Coin_01", isAll = true },
    },
  },

  ["nearby/loot"] = {
    title = "Nearby Notable Loot & Drops",
    parent = "nearby",
    folders = {
      { path = "nearby/loot/armor", name = "Armor & Shields", desc = "Valuable BoE armor drops in this zone", icon = "Interface\\Icons\\INV_Chest_Chain_15" },
      { path = "nearby/loot/weapons", name = "Weapons", desc = "Prized world weapon drops in this zone", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "nearby/loot/recipes", name = "World Recipes & Plans", desc = "Crafting plans, patterns and formulas", icon = "Interface\\Icons\\INV_Scroll_03" },
      { path = "nearby/loot/accessories", name = "Jewelry & Accessories", desc = "Rings, trinkets, amulets and cloaks", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07" },
      { path = "nearby/loot/all", name = "[All Notable Zone Drops]", desc = "Complete catalog of notable loot in this zone", icon = "Interface\\Icons\\INV_Misc_Coin_02", isAll = true },
    },
  },

  ["nearby/quests"] = {
    title = "Nearby Quests",
    parent = "nearby",
    folders = {
      { path = "nearby/quests/recommended", name = "Recommended Quests", desc = "Level-appropriate quests in this zone", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
      { path = "nearby/quests/story", name = "Storyline & Zone Quests", desc = "Main storyline and side quests in this zone", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "nearby/quests/dungeons", name = "Dungeon Quests (Local)", desc = "Quests tied to instances in or near this zone", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
      { path = "nearby/quests/all", name = "[All Quests in Zone]", desc = "All available quests in this zone", icon = "Interface\\Icons\\INV_Misc_QuestionMark", isAll = true },
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

  ["quests/dungeons"] = {
    title = "Dungeon & Raid Quests",
    parent = "quests",
    folders = {
      { path = "quests/dungeons/The Deadmines", name = "The Deadmines", desc = "Westfall instance quests (Edwin VanCleef, Defias)", icon = "Interface\\Icons\\INV_Misc_Key_03" },
      { path = "quests/dungeons/Wailing Caverns", name = "Wailing Caverns", desc = "Barrens druid quests (Leaders of the Fang)", icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow" },
      { path = "quests/dungeons/Shadowfang Keep", name = "Shadowfang Keep", desc = "Silverpine worgen fortress (Arugal)", icon = "Interface\\Icons\\Spell_Shadow_Charm" },
      { path = "quests/dungeons/Blackfathom Deeps", name = "Blackfathom Deeps", desc = "Ashenvale twilight shrine (Aku'mai)", icon = "Interface\\Icons\\Spell_Shadow_DemonBreath" },
      { path = "quests/dungeons/The Stockade", name = "The Stockade", desc = "Stormwind prison riot quests (Bazil Thredd)", icon = "Interface\\Icons\\INV_Cask_01" },
      { path = "quests/dungeons/Gnomeregan", name = "Gnomeregan", desc = "Gnomish irradiated capital (Thermaplugg)", icon = "Interface\\Icons\\Trade_Engineering" },
      { path = "quests/dungeons/Scarlet Monastery", name = "Scarlet Monastery", desc = "Graveyard, Library, Armory & Cathedral quests", icon = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude" },
      { path = "quests/dungeons/Razorfen Kraul", name = "Razorfen Kraul", desc = "Quilboar thorned bastion quests (Charlga Razorflank)", icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar" },
      { path = "quests/dungeons/Razorfen Downs", name = "Razorfen Downs", desc = "Undead quilboar barrow quests (Amnennar)", icon = "Interface\\Icons\\Spell_DeathKnight_ArmyOfTheDead" },
      { path = "quests/dungeons/Uldaman", name = "Uldaman", desc = "Titan excavation quests (Ironaya, Archaedas)", icon = "Interface\\Icons\\INV_Stone_02" },
      { path = "quests/dungeons/Zul'Farrak", name = "Zul'Farrak", desc = "Tanaris sandfury troll empire (Ghaz'rilla)", icon = "Interface\\Icons\\Ability_Racial_ShadowMeld" },
      { path = "quests/dungeons/Maraudon", name = "Maraudon", desc = "Desolace centaur ancestral tombs (Princess Theradras)", icon = "Interface\\Icons\\Spell_Nature_Earthquake" },
      { path = "quests/dungeons/Sunken Temple", name = "Sunken Temple", desc = "Swamp of Sorrows Atal'ai temple (Eranikus)", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green" },
      { path = "quests/dungeons/Blackrock Depths", name = "Blackrock Depths", desc = "Dark iron dwarven capital & prison (Emperor Dagran)", icon = "Interface\\Icons\\INV_Hammer_05" },
      { path = "quests/dungeons/Blackrock Spire", name = "Blackrock Spire (LBRS/UBRS)", desc = "Orcish war fortress (Warmaster Voone, Rend, Drakkisath)", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
      { path = "quests/dungeons/Stratholme", name = "Stratholme", desc = "Living Scarlet & Undead Baron Rivendare quests", icon = "Interface\\Icons\\Spell_Fire_Fireball02" },
      { path = "quests/dungeons/Scholomance", name = "Scholomance", desc = "Necromantic crypts & Darkmaster Gandling", icon = "Interface\\Icons\\Spell_Shadow_Haunting" },
      { path = "quests/dungeons/Dire Maul", name = "Dire Maul", desc = "East, West & North highborne ruins (Tribute run)", icon = "Interface\\Icons\\INV_Misc_Bone_08" },
      { path = "quests/dungeons/Molten Core", name = "Molten Core & Onyxia", desc = "Ragnaros & Broodmother Onyxia raid questlines", icon = "Interface\\Icons\\Spell_Fire_Volcano" },
      { path = "quests/dungeons/Blackwing Lair", name = "Blackwing Lair", desc = "Nefarian & draconic experiments", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Red" },
      { path = "quests/dungeons/Zul'Gurub", name = "Zul'Gurub", desc = "Stranglethorn blood god Hakkar raid quests", icon = "Interface\\Icons\\Ability_Hunter_Pet_Bat" },
      { path = "quests/dungeons/Ahn'Qiraj", name = "Ruins & Temple of Ahn'Qiraj", desc = "Silithid qiraji war quests (Ossirian, C'Thun)", icon = "Interface\\Icons\\INV_Misc_AhnQirajTrinket_01" },
      { path = "quests/dungeons/Naxxramas", name = "Naxxramas", desc = "Dread citadel floating above Eastern Plaguelands (Kel'Thuzad)", icon = "Interface\\Icons\\Spell_Shadow_DeathScream" },
      { path = "quests/dungeons/all", name = "[All Dungeon Quests (Full List)]", desc = "Complete catalog of all instance & raid quests", icon = "Interface\\Icons\\Spell_Shadow_Teleport", isAll = true },
    },
  },

  -- ITEMS HIERARCHY
  ["items"] = {
    title = "Items & Equipment",
    parent = "root",
    folders = {
      { path = "items/armor", name = "Armor", desc = "Cloth, Leather, Mail, Plate, Shields & Cloaks", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "items/weapons", name = "Weapons", desc = "Swords, Axes, Maces, Staves, Bows, Daggers...", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "items/accessories", name = "Jewelry & Accessories", desc = "Rings, Trinkets, Necklaces & Cloaks", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07" },
      { path = "items/consumables", name = "Consumables", desc = "Potions, Elixirs, Flasks, Food, Bandages, Scrolls", icon = "Interface\\Icons\\INV_Potion_51" },
      { path = "items/trade_goods", name = "Trade Goods", desc = "Herbs, Metal & Stone, Cloth, Leather, Gems, Reagents", icon = "Interface\\Icons\\INV_Ore_Iron_01" },
      { path = "items/recipes", name = "Recipes & Plans", desc = "Alchemy, Blacksmithing, Tailoring, Enchanting...", icon = "Interface\\Icons\\INV_Scroll_03" },
      { path = "items/containers", name = "Bags & Containers", desc = "Bags, Quivers, Ammo Pouches & Specialty bags", icon = "Interface\\Icons\\INV_Misc_Bag_08" },
      { path = "forever/items", name = "[Forever] Forever Exclusive Gear", desc = "Exclusive Warcraft Forever items (By Type)", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
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
      { path = "items/sub/Shields", name = "Shields", desc = "Off-Hand Shields (iLvl Low to High)", icon = "Interface\\Icons\\INV_Shield_04" },
      { path = "items/sub/Off-hand", name = "Held In Off-hand", desc = "Tomes, lanterns, orbs & off-hands", icon = "Interface\\Icons\\INV_Misc_Book_06" },
      { path = "items/sub/All Accessories", name = "[All Accessories (Full List)]", desc = "Complete catalog of rings, trinkets, necks, cloaks & shields", icon = "Interface\\Icons\\INV_Jewelry_Ring_03", isAll = true },
    },
  },

  ["items/consumables"] = {
    title = "Consumables",
    parent = "items",
    folders = {
      { path = "items/sub/Potions", name = "Potions", desc = "Healing, Mana, Rage, Free Action & Protection potions", icon = "Interface\\Icons\\INV_Potion_51", filter = { itemType = "Potion" } },
      { path = "items/sub/Elixirs", name = "Elixirs", desc = "Defense, Agility, Strength & Intellect stat elixirs", icon = "Interface\\Icons\\INV_Potion_63", filter = { itemType = "Elixir" } },
      { path = "items/sub/Flasks", name = "Flasks", desc = "Flask of the Titans, Supreme Power, Distilled Wisdom", icon = "Interface\\Icons\\INV_Potion_62", filter = { itemType = "Flask" } },
      { path = "items/sub/Food", name = "Food & Drink", desc = "Food, water, alcoholic beverages & stat provisions", icon = "Interface\\Icons\\INV_Misc_Food_14", filter = { itemType = "Food & Drink" } },
      { path = "items/sub/Bandages", name = "Bandages", desc = "Linen, Silk, Mageweave & Runecloth bandages", icon = "Interface\\Icons\\INV_Misc_Bandage_08", filter = { itemType = "Bandage" } },
      { path = "items/sub/Scrolls", name = "Scrolls", desc = "Agility, Strength, Intellect & Stamina scrolls", icon = "Interface\\Icons\\INV_Scroll_02", filter = { itemType = "Scroll" } },
      { path = "items/sub/Oils", name = "Weapon Buffs & Oils", desc = "Mana oils, Wizard oils & Sharpening stones", icon = "Interface\\Icons\\INV_Potion_99", filter = { itemType = "Buff" } },
      { path = "items/sub/All Consumables", name = "[All Consumables (Full List)]", desc = "Complete catalog of all consumables (sorted by Type)", icon = "Interface\\Icons\\INV_Potion_54", isAll = true },
    },
  },

  ["items/trade_goods"] = {
    title = "Trade Goods",
    parent = "items",
    folders = {
      { path = "items/sub/Cloth", name = "Cloth & Bolts", desc = "Linen, Wool, Silk, Mageweave, Runecloth & Mooncloth", icon = "Interface\\Icons\\INV_Fabric_Silk_02", filter = { itemType = "Cloth" } },
      { path = "items/sub/Elemental", name = "Elemental & Essences", desc = "Elemental Earth, Fire, Water, Air, Essences & Cores", icon = "Interface\\Icons\\Spell_Fire_Volcano", filter = { itemType = "Elemental" } },
      { path = "items/sub/Gems", name = "Gems & Jewels", desc = "Malachite, Tigerseye, Shadowgem, Ruby, Diamond, Sapphire", icon = "Interface\\Icons\\INV_Misc_Gem_Ruby_01", filter = { itemType = "Gem" } },
      { path = "items/sub/Herbs", name = "Herbs", desc = "Peacebloom, Silverleaf, Kingsblood, Black Lotus...", icon = "Interface\\Icons\\INV_Misc_Herb_07", filter = { itemType = "Herb" } },
      { path = "items/sub/Leather", name = "Leather & Hides", desc = "Light, Medium, Heavy, Thick, Rugged leather & hides", icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", filter = { itemType = "Leather" } },
      { path = "items/sub/Ore", name = "Metal & Stone", desc = "Copper, Tin, Iron, Mithril, Thorium & Dark Iron bars", icon = "Interface\\Icons\\INV_Ore_Iron_01", filter = { itemType = "Metal & Stone" } },
      { path = "items/sub/Parts", name = "Parts & Devices", desc = "Gears, tubes, fuses & engineering components", icon = "Interface\\Icons\\INV_Misc_Gear_01", filter = { itemType = "Parts" } },
      { path = "items/sub/Reagents", name = "Reagents & Materials", desc = "Dusts, shards, vials, threads, dyes & oils", icon = "Interface\\Icons\\INV_Misc_Dust_01", filter = { itemType = "Reagent" } },
      { path = "items/sub/All Trade Goods", name = "[All Trade Goods (Full List)]", desc = "Complete catalog of all trade goods & materials", icon = "Interface\\Icons\\INV_Misc_Coin_01", isAll = true },
    },
  },

  ["items/recipes"] = {
    title = "Recipes & Plans",
    parent = "items",
    folders = {
      { path = "items/recipes/alchemy", name = "Alchemy Recipes", desc = "Potions, elixirs, flasks & transmutation recipes", icon = "Interface\\Icons\\Trade_Alchemy" },
      { path = "items/recipes/blacksmithing", name = "Blacksmithing Plans", desc = "Mail, plate, weapons & sharpening stones", icon = "Interface\\Icons\\Trade_BlackSmithing" },
      { path = "items/recipes/cooking", name = "Cooking Recipes", desc = "Food and beverage culinary recipes", icon = "Interface\\Icons\\INV_Misc_Food_15" },
      { path = "items/recipes/enchanting", name = "Enchanting Formulas", desc = "Weapon, chest, bracer, boot & oil enchant formulas", icon = "Interface\\Icons\\Trade_Engraving" },
      { path = "items/recipes/engineering", name = "Engineering Schematics", desc = "Explosives, guns, devices & gadget schematics", icon = "Interface\\Icons\\Trade_Engineering" },
      { path = "items/recipes/first_aid", name = "First Aid Manuals", desc = "Bandage, anti-venom & survival medicine manuals", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice" },
      { path = "items/recipes/leatherworking", name = "Leatherworking Patterns", desc = "Leather & mail armor, cloaks and patch patterns", icon = "Interface\\Icons\\Trade_LeatherWorking" },
      { path = "items/recipes/tailoring", name = "Tailoring Patterns", desc = "Cloth armor, robes, shirts & bag patterns", icon = "Interface\\Icons\\Trade_Tailoring" },
      { path = "items/recipes/all", name = "[All Recipes & Plans (Full List)]", desc = "Complete catalog of all crafting recipes", icon = "Interface\\Icons\\INV_Scroll_03", isAll = true },
    },
  },

  ["items/containers"] = {
    title = "Bags & Containers",
    parent = "items",
    folders = {
      { path = "items/sub/Bags", name = "Bags (General)", desc = "6-slot to 18-slot inventory containers", icon = "Interface\\Icons\\INV_Misc_Bag_08" },
      { path = "items/sub/Quivers", name = "Quivers & Ammo Pouches", desc = "Hunter bow quivers and gun ammo pouches", icon = "Interface\\Icons\\INV_Misc_Quiver_01" },
      { path = "items/sub/Specialty_Bags", name = "Profession & Specialty Bags", desc = "Soul pouches, Herb bags, Enchanting pouches", icon = "Interface\\Icons\\INV_Misc_Bag_14" },
      { path = "items/sub/All Containers", name = "[All Bags & Containers (Full List)]", desc = "Complete catalog of all bags, pouches & quivers", icon = "Interface\\Icons\\INV_Misc_Bag_08", isAll = true },
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
      { path = "vendors/flightpaths", name = "Flight Masters", desc = "Alliance & Horde Flight Masters", icon = "Interface\\Icons\\Ability_Hunter_EagleEye" },
      { path = "vendors/repairs", name = "Repairs & Armorers", desc = "Blacksmiths and equipment repairers", icon = "Interface\\Icons\\Trade_BlackSmithing" },
      { path = "vendors/reagents", name = "Reagents & Alchemy Supplies", desc = "Herbs, potions, poisons and crafting goods", icon = "Interface\\Icons\\INV_Potion_33" },
      { path = "vendors/food", name = "Food & Drink Merchants", desc = "Innkeepers, barkeepers, butchers & bakers", icon = "Interface\\Icons\\INV_Misc_Food_14" },
      { path = "vendors/weapons_armor", name = "Weapons & Armor Vendors", desc = "Weaponsmiths, leatherworkers, tailors & armorers", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "vendors/tradesupplies", name = "Trade Supplies & Materials", desc = "Tailoring, leather, engineering & crafting materials", icon = "Interface\\Icons\\INV_Fabric_Silk_02" },
      { path = "vendors/trainers", name = "Class & Profession Trainers", desc = "Class, profession, riding & weapon trainers", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
      { path = "vendors/pvp", name = "PvP Quartermasters", desc = "Battlegrounds & Honor Vendors", icon = "Interface\\Icons\\INV_BannerPVP_02" },
      { path = "vendors/specialty", name = "Specialty & Rare Goods", desc = "Limited Recipes, Pets & Unique items", icon = "Interface\\Icons\\INV_Misc_Bag_07" },
      { path = "vendors/all", name = "[All World Vendors (Full List)]", desc = "Complete alphabetical catalog of all merchants", icon = "Interface\\Icons\\INV_Misc_Coin_01", isAll = true },
    },
  },

  -- SPELLS & ABILITIES HIERARCHY
  ["spells"] = {
    title = "Spells & Abilities",
    parent = "root",
    folders = {
      { path = "spells/druid", name = "Druid", desc = "Druid class spells, forms & talents", icon = "Interface\\Icons\\Ability_Druid_Maul" },
      { path = "spells/hunter", name = "Hunter", desc = "Hunter shots, traps, aspects & pets", icon = "Interface\\Icons\\INV_Weapon_Bow_07" },
      { path = "spells/mage", name = "Mage", desc = "Arcane, Fire, and Frost spells", icon = "Interface\\Icons\\Spell_Fire_FlameBolt" },
      { path = "spells/paladin", name = "Paladin", desc = "Holy, Protection & Retribution seals", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
      { path = "spells/priest", name = "Priest", desc = "Discipline, Holy & Shadow prayers", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
      { path = "spells/rogue", name = "Rogue", desc = "Stealth, finishing moves, poisons & Shank", icon = "Interface\\Icons\\Ability_Stealth" },
      { path = "spells/shaman", name = "Shaman", desc = "Totems, shocks & elemental fury", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
      { path = "spells/warlock", name = "Warlock", desc = "Curses, demons, afflictions & destruction", icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges" },
      { path = "spells/warrior", name = "Warrior", desc = "Stances, shouts, strikes & rage abilities", icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
      { path = "spells/racials", name = "Racial Traits & Passives", desc = "Skyborne, Dwarf, Human, Orc, Tauren, Undead, Gnome, Troll", icon = "Interface\\Icons\\Spell_Nature_Windfury" },
      { path = "spells/forever", name = "[Forever] Custom & Reworked Spells", desc = "50 custom Alpha abilities, passives & reworks", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
      { path = "spells/all", name = "[All Spells & Abilities]", desc = "Complete catalog of spells across all classes", icon = "Interface\\Icons\\INV_Misc_Book_09", isAll = true },
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
      { path = "forever/spells", name = "Forever Spells & Talents", desc = "50 custom Alpha abilities, racials & reworks", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    },
  },

  ["forever/items"] = {
    title = "[Forever] Gear by Type",
    parent = "forever",
    folders = {
      { path = "forever/items/weapons", name = "Weapons", desc = "Forever swords, axes, bows, staves...", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "forever/items/armor", name = "Armor & Shields", desc = "Cloth, Leather, Mail, Plate & Shields", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "forever/items/accessories", name = "Jewelry & Accessories", desc = "Rings, Trinkets, Necklaces & Cloaks", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07" },
      { path = "forever/items/consumables", name = "Consumables", desc = "Potions, Elixirs, Food & Bandages", icon = "Interface\\Icons\\INV_Potion_51" },
      { path = "forever/items/trade_goods", name = "Trade Goods & Reagents", desc = "Herbs, Ores, Gems & Materials", icon = "Interface\\Icons\\INV_Ore_Iron_01" },
      { path = "forever/items/recipes", name = "Recipes & Plans", desc = "Crafting Recipes, Formulas & Manuals", icon = "Interface\\Icons\\INV_Scroll_03" },
      { path = "forever/items/quest", name = "Quest Items", desc = "Exclusive quest items & artifacts", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "forever/items/all", name = "[All Forever Gear (Full List)]", desc = "Complete catalog of all Forever items (sorted by Type)", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", isAll = true },
    },
  },

  ["items/forever"] = {
    title = "[Forever] Exclusive Gear by Type",
    parent = "items",
    folders = {
      { path = "items/forever/weapons", name = "Weapons", desc = "Forever swords, axes, bows, staves...", icon = "Interface\\Icons\\INV_Sword_04" },
      { path = "items/forever/armor", name = "Armor & Shields", desc = "Cloth, Leather, Mail, Plate & Shields", icon = "Interface\\Icons\\INV_Chest_Plate03" },
      { path = "items/forever/accessories", name = "Jewelry & Accessories", desc = "Rings, Trinkets, Necklaces & Cloaks", icon = "Interface\\Icons\\INV_Jewelry_Necklace_07" },
      { path = "items/forever/consumables", name = "Consumables", desc = "Potions, Elixirs, Food & Bandages", icon = "Interface\\Icons\\INV_Potion_51" },
      { path = "items/forever/trade_goods", name = "Trade Goods & Reagents", desc = "Herbs, Ores, Gems & Materials", icon = "Interface\\Icons\\INV_Ore_Iron_01" },
      { path = "items/forever/recipes", name = "Recipes & Plans", desc = "Crafting Recipes, Formulas & Manuals", icon = "Interface\\Icons\\INV_Scroll_03" },
      { path = "items/forever/quest", name = "Quest Items", desc = "Exclusive quest items & artifacts", icon = "Interface\\Icons\\INV_Misc_Book_07" },
      { path = "items/forever/all", name = "[All Forever Gear (Full List)]", desc = "Complete catalog of all Forever items (sorted by Type)", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", isAll = true },
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
    elseif cur:find("^upgrades/[^/]+/[^/]+$") then
      local uType = cur:match("^upgrades/([^/]+)/[^/]+$")
      parent = "upgrades/" .. uType
    elseif cur:find("^upgrades/[^/]+$") then
      parent = "upgrades"
    elseif cur == "upgrades" then
      parent = "root"
    elseif cur:find("^forever/items/") then
      parent = "forever/items"
    elseif cur == "forever/items" then
      parent = "forever"
    elseif cur:find("^items/forever/") then
      parent = "items/forever"
    elseif cur == "items/forever" then
      parent = "items"
    elseif cur:find("^items/recipes/") then
      parent = "items/recipes"
    elseif cur:find("^items/containers") or cur:find("^items/sub/Bags") or cur:find("^items/sub/Quivers") or cur:find("^items/sub/Specialty_Bags") or cur == "items/sub/All Containers" then
      parent = (cur == "items/containers") and "items" or "items/containers"
    elseif cur:find("^items/sub/") then
      local sub = cur:sub(11)
      if sub:find("Armor$") or sub == "Shields" or sub == "Cloaks" then
        parent = "items/armor"
      elseif sub == "Potions" or sub == "Elixirs" or sub == "Flasks" or sub == "Food" or sub == "Bandages" or sub == "Scrolls" or sub == "Oils" or sub == "All Consumables" then
        parent = "items/consumables"
      elseif sub == "Herbs" or sub == "Ore" or sub == "Cloth" or sub == "Leather" or sub == "Gems" or sub == "Elemental" or sub == "Parts" or sub == "Reagents" or sub == "All Trade Goods" then
        parent = "items/trade_goods"
      elseif sub:find("Axe") or sub:find("Sword") or sub:find("Mace") or sub == "Daggers" or sub == "Polearms" or sub == "Staves" or sub == "Bows" or sub == "Guns" or sub == "Wands" or sub == "Fist Weapons" then
        parent = "items/weapons"
      elseif sub == "Amulets" or sub == "Rings" or sub == "Trinkets" or sub == "Off-hand" or sub == "All Accessories" then
        parent = "items/accessories"
      else
        parent = "items"
      end
    elseif cur:find("^quests/dungeons/") then
      parent = "quests/dungeons"
    elseif cur == "quests/dungeons" then
      parent = "quests"
    elseif cur:find("^nearby/creatures/") then
      parent = "nearby/creatures"
    elseif cur:find("^nearby/vendors/") then
      parent = "nearby/vendors"
    elseif cur:find("^nearby/loot/") then
      parent = "nearby/loot"
    elseif cur:find("^nearby/quests/") then
      parent = "nearby/quests"
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
    elseif cur:find("^nearby/quests/(.+)$") then
      local qSub = cur:match("^nearby/quests/(.+)$")
      local qNames = { recommended = "Recommended", story = "Storyline", dungeons = "Dungeons", all = "All Quests" }
      table.insert(trail, "|cff88aaccQuests|r")
      table.insert(trail, "|cffffd24d" .. (qNames[qSub] or qSub) .. "|r")
    elseif cur == "nearby/rares" then table.insert(trail, "|cffffd24dRares & Bosses|r")
    elseif cur == "nearby/creatures" then table.insert(trail, "|cffffd24dCreatures|r")
    elseif cur:find("^nearby/creatures/(.+)$") then
      local cSub = cur:match("^nearby/creatures/(.+)$")
      local cNames = {
        beasts = "Beasts",
        humanoids = "Humanoids",
        undead = "Undead",
        elementals = "Elementals",
        demons = "Demons",
        dragonkin = "Dragonkin",
        giants = "Giants",
        rares = "Rares",
        all = "All Creatures",
      }
      table.insert(trail, "|cff88aaccCreatures|r")
      table.insert(trail, "|cffffd24d" .. (cNames[cSub] or cSub:gsub("^%l", string.upper)) .. "|r")
    elseif cur == "nearby/vendors" then table.insert(trail, "|cffffd24dVendors & Services|r")
    elseif cur:find("^nearby/vendors/(.+)$") then
      local vSub = cur:match("^nearby/vendors/(.+)$")
      local vNames = {
        flight = "Flight Masters",
        repairs = "Repairs & Armorers",
        reagents = "Reagents & Alchemy",
        food = "Food & Drink",
        weapons_armor = "Weapons & Armor",
        tradesupplies = "Trade Supplies",
        trainers = "Trainers",
        pvp = "PvP Quartermasters",
        specialty = "Specialty Goods",
        all = "All Vendors",
      }
      table.insert(trail, "|cff88aaccVendors|r")
      table.insert(trail, "|cffffd24d" .. (vNames[vSub] or vSub) .. "|r")
    elseif cur == "nearby/dungeons" then table.insert(trail, "|cffffd24dDungeons|r")
    elseif cur == "nearby/loot" then table.insert(trail, "|cffffd24dNotable Loot|r")
    elseif cur:find("^nearby/loot/(.+)$") then
      local lSub = cur:match("^nearby/loot/(.+)$")
      local lNames = { armor = "Armor & Shields", weapons = "Weapons", recipes = "Recipes & Plans", accessories = "Jewelry & Accessories", all = "All Loot" }
      table.insert(trail, "|cff88aaccNotable Loot|r")
      table.insert(trail, "|cffffd24d" .. (lNames[lSub] or lSub) .. "|r")
    elseif cur == "nearby/closest" then table.insert(trail, "|cffffd24dClosest Radar|r")
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
    elseif cur:find("^quests/dungeons/(.+)$") then
      local dKey = cur:match("^quests/dungeons/(.+)$")
      table.insert(trail, "|cff88aaccDungeon Quests|r")
      table.insert(trail, "|cffffd24d" .. dKey .. "|r")
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
    elseif cur == "items/containers" then table.insert(trail, "|cffffffffBags & Containers|r")
    elseif cur:find("^items/recipes/(.+)$") then
      local rec = cur:match("^items/recipes/(.+)$")
      local recNames = {
        alchemy = "Alchemy Recipes",
        blacksmithing = "Blacksmithing Plans",
        cooking = "Cooking Recipes",
        enchanting = "Enchanting Formulas",
        engineering = "Engineering Schematics",
        first_aid = "First Aid Manuals",
        leatherworking = "Leatherworking Patterns",
        tailoring = "Tailoring Patterns",
        all = "All Recipes",
      }
      table.insert(trail, "|cffffffffRecipes|r")
      table.insert(trail, "|cffffd24d" .. (recNames[rec] or rec) .. "|r")
    elseif cur == "items/forever" then
      table.insert(trail, "|cffe6cc80[Forever] Gear (By Type)|r")
    elseif cur:find("^items/forever/(.+)$") then
      local subType = cur:match("^items/forever/(.+)$")
      local typeName = subType:gsub("^%l", string.upper)
      if subType == "trade_goods" then typeName = "Trade Goods"
      elseif subType == "all" then typeName = "All Gear"
      end
      table.insert(trail, "|cffe6cc80[Forever] Gear|r")
      table.insert(trail, "|cffffd24d" .. typeName .. "|r")
    elseif cur:find("^items/sub/") then
      local sub = cur:sub(11)
      if sub == "Potions" or sub == "Elixirs" or sub == "Flasks" or sub == "Food" or sub == "Bandages" or sub == "Scrolls" or sub == "Oils" or sub == "All Consumables" then
        table.insert(trail, "|cffffffffConsumables|r")
      elseif sub == "Herbs" or sub == "Ore" or sub == "Cloth" or sub == "Leather" or sub == "Gems" or sub == "Elemental" or sub == "Parts" or sub == "Reagents" or sub == "All Trade Goods" then
        table.insert(trail, "|cffffffffTrade Goods|r")
      elseif sub == "Bags" or sub == "Quivers" or sub == "Specialty_Bags" then
        table.insert(trail, "|cffffffffBags|r")
      elseif sub:find("Axe") or sub:find("Sword") or sub:find("Mace") or sub == "Daggers" or sub == "Polearms" or sub == "Staves" or sub == "Bows" or sub == "Guns" or sub == "Wands" or sub == "Fist Weapons" then
        table.insert(trail, "|cffffffffWeapons|r")
      elseif sub == "Amulets" or sub == "Rings" or sub == "Trinkets" or sub == "Cloaks" then
        table.insert(trail, "|cffffffffAccessories|r")
      end
      table.insert(trail, "|cffffd24d" .. (sub:gsub("_", " ")) .. "|r")
    end
  elseif cur:find("^upgrades") then
    table.insert(trail, "|cff88aaccUpgrades|r")
    if cur == "upgrades/recommended" then
      local _, pClass = UnitClass("player")
      local pLevel = (UnitLevel and UnitLevel("player")) or 1
      table.insert(trail, "|cffffd24d★ " .. (pClass and (pClass:sub(1,1):upper() .. pClass:sub(2):lower()) or "My Class") .. " Upgrades (Lvl " .. pLevel .. ")|r")
    elseif cur == "upgrades/dungeons" then
      table.insert(trail, "|cffffd24dDungeon & Raid Drops|r")
    elseif cur == "upgrades/quests" then
      table.insert(trail, "|cffffd24dQuest Rewards|r")
    elseif cur == "upgrades/all" then
      table.insert(trail, "|cffffd24dAll Armor Upgrades|r")
    elseif cur == "upgrades/accessories" then
      table.insert(trail, "|cffffd24dJewelry, Cloaks & Shields|r")
    elseif cur:find("^upgrades/acc/([^/]+)$") then
      local slot = cur:match("^upgrades/acc/([^/]+)$")
      table.insert(trail, "|cffffffffJewelry & Shields|r")
      table.insert(trail, "|cffffd24d" .. slot .. "|r")
    elseif cur:find("^upgrades/[^/]+/[^/]+$") then
      local armorType, slot = cur:match("^upgrades/([^/]+)/([^/]+)$")
      local slotDisplay = slot
      if slot == "Waist" then slotDisplay = "Waist (Belts)"
      elseif slot == "Wrist" then slotDisplay = "Wrist (Bracers)"
      elseif slot == "Hands" then slotDisplay = "Hands (Gauntlets)"
      elseif slot == "Feet" then slotDisplay = "Feet (Boots)"
      elseif slot == "Shoulder" then slotDisplay = "Shoulders"
      end
      table.insert(trail, "|cffffffff" .. armorType:gsub("^%l", string.upper) .. " Armor|r")
      table.insert(trail, "|cffffd24d" .. slotDisplay .. "|r")
    elseif cur:find("^upgrades/[^/]+$") then
      local armorType = cur:match("^upgrades/([^/]+)$")
      table.insert(trail, "|cffffd24d" .. armorType:gsub("^%l", string.upper) .. " Armor|r")
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
    elseif cur == "vendors/repairs" then table.insert(trail, "|cffffffffRepairs & Armorers|r")
    elseif cur == "vendors/reagents" then table.insert(trail, "|cffffffffReagents & Alchemy|r")
    elseif cur == "vendors/food" then table.insert(trail, "|cffffffffFood & Drink|r")
    elseif cur == "vendors/weapons_armor" then table.insert(trail, "|cffffffffWeapons & Armor|r")
    elseif cur == "vendors/tradesupplies" then table.insert(trail, "|cffffffffTrade Supplies|r")
    elseif cur == "vendors/trainers" then table.insert(trail, "|cffffffffTrainers|r")
    elseif cur == "vendors/pvp" then table.insert(trail, "|cffffffffPvP Vendors|r")
    elseif cur == "vendors/specialty" then table.insert(trail, "|cffffffffSpecialty Goods|r")
    end
  elseif cur:find("^forever") then
    table.insert(trail, "|cffe6cc80[Forever] Content|r")
    if cur == "forever/items" then
      table.insert(trail, "|cffffffffGear (By Type)|r")
    elseif cur:find("^forever/items/(.+)$") then
      local subType = cur:match("^forever/items/(.+)$")
      local typeName = subType:gsub("^%l", string.upper)
      if subType == "trade_goods" then typeName = "Trade Goods"
      elseif subType == "all" then typeName = "All Gear"
      end
      table.insert(trail, "|cffffffffGear|r")
      table.insert(trail, "|cffffd24d" .. typeName .. "|r")
    elseif cur == "forever/quests" then table.insert(trail, "|cffffffffQuests|r")
    elseif cur == "forever/creatures" then table.insert(trail, "|cffffffffNPCs|r")
    elseif cur == "forever/dungeons" then table.insert(trail, "|cffffffffDungeons|r")
    elseif cur == "forever/spells" then table.insert(trail, "|cffffffffSpells|r")
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

function FG:GetItemTypeSortKey(item)
  if not item then return 99, "Other" end
  local slot = (item.slot and item.slot ~= "" and item.slot ~= "Non-equippable" and item.slot ~= "Consumable") and item.slot or nil
  local iType = (item.itemType and item.itemType ~= "") and item.itemType or nil
  local name = item.name or ""
  local displayType = slot or iType or "Other"
  if not slot then
    if (iType and iType:find("Potion")) or name:find("Potion") or name:find("Draft") or name:find("Brew") or name:find("Tears") then displayType = "Potion"
    elseif (iType and iType:find("Elixir")) or name:find("Elixir") then displayType = "Elixir"
    elseif (iType and iType:find("Flask")) or name:find("^Flask of") or name:find(" Flask") then displayType = "Flask"
    elseif (iType and iType:find("Scroll")) or name:find("^Scroll of") or name:find("Scroll") then displayType = "Scroll"
    elseif (iType and iType:find("Bandage")) or name:find("Bandage") or name:find("Anti%-Venom") then displayType = "Bandage"
    elseif name:find(" Oil") or name:find("Sharpening") or name:find("Weightstone") then displayType = "Oil"
    elseif (iType and iType:find("Food")) or name:find("Meat") or name:find("Bread") or name:find("Fish") or name:find("Stew") or name:find("Soup") or name:find("Water") or name:find("Juice") or name:find("Milk") or name:find("Ale") or name:find("Beer") or name:find("Wine") or name:find("Pie") or name:find("Roast") or name:find("Ribs") or name:find("Cheese") or name:find("Apple") or name:find("Fruit") or name:find("Ration") or name:find("Melon") or name:find("Tea") or name:find("Bisque") or name:find("Sausage") or name:find("Chop") or name:find("Steak") then displayType = "Food & Drink"
    end
  end

  -- Determine high-level group rank:
  -- 1: Weapons
  -- 2: Armor & Shields
  -- 3: Jewelry & Accessories
  -- 4: Consumables
  -- 5: Bags & Containers
  -- 6: Trade Goods & Reagents
  -- 7: Recipes & Plans
  -- 8: Quest Items
  -- 9: Junk & Misc
  local group = 9

  -- Check recipe name prefixes first
  if name:find("^Recipe:") or name:find("^Pattern:") or name:find("^Plans:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Manual:") or name:find("^Book:") then
    group = 7
    displayType = "Recipe"
  elseif slot then
    if slot == "Shield" or slot == "Held In Off-hand" or slot == "Head" or slot == "Shoulder" or slot == "Chest" or slot == "Waist" or slot == "Legs" or slot == "Feet" or slot == "Wrist" or slot == "Hands" or slot == "Back" or slot == "Shirt" or slot == "Tabard" then
      group = 2
    elseif slot == "One-Hand" or slot == "Two-Hand" or slot == "Main Hand" or slot == "Ranged" or slot == "Thrown" then
      group = 1
    elseif slot == "Off Hand" then
      if iType and (iType:lower():find("shield") or iType:lower():find("armor")) then
        group = 2
      else
        group = 1
      end
    elseif slot == "Neck" or slot == "Finger" or slot == "Trinket" or slot == "Relic" then
      group = 3
    elseif slot == "Bag" then
      group = 5
    end
  end

  if group == 9 and iType then
    local itLower = iType:lower()
    if itLower:find("weapon") or itLower:find("sword") or itLower:find("axe") or itLower:find("mace") or itLower:find("dagger") or itLower:find("bow") or itLower:find("gun") or itLower:find("crossbow") or itLower:find("staff") or itLower:find("polearm") or itLower:find("wand") or itLower:find("fist") then
      group = 1
    elseif itLower:find("armor") or itLower:find("cloth") or itLower:find("leather") or itLower:find("mail") or itLower:find("plate") or itLower:find("shield") then
      group = 2
    elseif itLower:find("ring") or itLower:find("neck") or itLower:find("trinket") or itLower:find("amulet") then
      group = 3
    elseif itLower:find("potion") or itLower:find("elixir") or itLower:find("flask") or itLower:find("food") or itLower:find("bandage") or itLower:find("scroll") or itLower:find("consumable") then
      group = 4
    elseif itLower:find("bag") or itLower:find("container") or itLower:find("quiver") or itLower:find("pouch") then
      group = 5
    elseif itLower:find("herb") or itLower:find("metal") or itLower:find("stone") or itLower:find("ore") or itLower:find("parts") or itLower:find("reagent") or itLower:find("trade") or itLower:find("elemental") or itLower:find("gem") or itLower:find("materials") then
      group = 6
    elseif itLower:find("recipe") or itLower:find("book") or itLower:find("plans") or itLower:find("pattern") or itLower:find("schematic") then
      group = 7
    elseif itLower:find("quest") or item.bind == "Quest Item" then
      group = 8
    elseif itLower:find("junk") or itLower:find("money") or name == "Gold" or name == "Silver" or name == "Copper" then
      group = 9
    end
  end

  if group == 9 and (name:find("Quest") or item.bind == "Quest Item") then
    group = 8
  end

  return group, displayType
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
      local creatureSub = cur:match("^nearby/creatures/(.+)$")
      local vendorSub = cur:match("^nearby/vendors/(.+)$")
      local lootSub = cur:match("^nearby/loot/(.+)$")
      local questSub = cur:match("^nearby/quests/(.+)$")

      local showCreatures = (creatureSub ~= nil) or (cur == "nearby/rares") or isClosest or (isNearbyRoot and q ~= "") or (cur == "nearby/creatures" and q ~= "")
      local showVendors = (vendorSub ~= nil) or isClosest or (isNearbyRoot and q ~= "") or (cur == "nearby/vendors" and q ~= "")
      local showQuests = (questSub ~= nil) or isClosest or (isNearbyRoot and q ~= "") or (cur == "nearby/quests" and q ~= "")
      local showDungeons = (cur == "nearby/dungeons") or isClosest or (isNearbyRoot and q ~= "")
      local showLoot = (lootSub ~= nil) or (cur == "nearby/loot" and q ~= "") or (isNearbyRoot and q ~= "")

      -- 1. Category subfolders when browsing nearby/creatures with no query
      if cur == "nearby/creatures" and q == "" then
        local cCounts = { beasts = 0, humanoids = 0, undead = 0, elementals = 0, demons = 0, dragonkin = 0, giants = 0, rares = 0, all = 0 }
        if FG.Data.Creatures then
          for _, c in pairs(FG.Data.Creatures) do
            if not FG:IsInternalCreature(c.name, c.family) then
              local inZone = (c.zone and c.zone:lower() == pZoneLower) or (c.location and c.location:lower():find(pZoneLower, 1, true))
              local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
              if inZone or inSub then
                cCounts.all = cCounts.all + 1
                local isRare = (c.classification == "Boss" or c.classification == "World Boss" or c.classification == "Rare" or c.classification == "Rare Elite")
                if isRare then cCounts.rares = cCounts.rares + 1 end
                if c.family then
                  local fam = c.family:lower()
                  if fam == "beast" then cCounts.beasts = cCounts.beasts + 1
                  elseif fam == "humanoid" then cCounts.humanoids = cCounts.humanoids + 1
                  elseif fam == "undead" then cCounts.undead = cCounts.undead + 1
                  elseif fam == "elemental" then cCounts.elementals = cCounts.elementals + 1
                  elseif fam == "demon" then cCounts.demons = cCounts.demons + 1
                  elseif fam == "dragonkin" then cCounts.dragonkin = cCounts.dragonkin + 1
                  elseif fam == "giant" then cCounts.giants = cCounts.giants + 1
                  end
                end
              end
            end
          end
        end
        local cFolders = (FG.FolderTree["nearby/creatures"] and FG.FolderTree["nearby/creatures"].folders) or {}
        for _, f in ipairs(cFolders) do
          local subKey = f.path:match("^nearby/creatures/(.+)$")
          local count = (subKey and cCounts[subKey]) or 0
          table.insert(matches, {
            type = "folder",
            data = {
              name = f.name,
              path = f.path,
              desc = string.format("%d %s in %s", count, f.name, pZone),
              count = count,
              icon = f.icon,
              isAll = f.isAll,
            }
          })
        end
      end

      -- 2. Category subfolders when browsing nearby/vendors with no query
      if cur == "nearby/vendors" and q == "" then
        local vCounts = { flight = 0, repairs = 0, reagents = 0, food = 0, weapons_armor = 0, tradesupplies = 0, trainers = 0, pvp = 0, specialty = 0, all = 0 }
        if FG.Data.Flightpaths then
          for _, fp in pairs(FG.Data.Flightpaths) do
            if fp.zone and fp.zone:lower() == pZoneLower then
              vCounts.flight = vCounts.flight + 1
              vCounts.all = vCounts.all + 1
            end
          end
        end
        local addedVendorsCount = {}
        if FG.Data.Vendors then
          for _, v in pairs(FG.Data.Vendors) do
            local vZone = v.zone
            if (vZone == "Azeroth" or vZone == "Eastern Kingdoms" or vZone == "Kalimdor" or not vZone) and v.name then
              local cObj = FG:FindCreatureByName(v.name)
              if cObj and cObj.zone then vZone = cObj.zone end
            end
            if vZone and vZone:lower() == pZoneLower then
              local key = (v.name or "") .. ":" .. (v.zone or "")
              if not addedVendorsCount[key] then
                addedVendorsCount[key] = true
                vCounts.all = vCounts.all + 1
                for subKey, _ in pairs(vCounts) do
                  if subKey ~= "all" and subKey ~= "flight" and FG:MatchesVendorSubtype(v, subKey) then
                    vCounts[subKey] = vCounts[subKey] + 1
                  end
                end
              end
            end
          end
        end
        if FG.Data.Creatures then
          for _, c in pairs(FG.Data.Creatures) do
            local inZone = (c.zone and c.zone:lower() == pZoneLower) or (c.location and c.location:lower():find(pZoneLower, 1, true))
            if inZone and not FG:IsInternalCreature(c.name, c.family) then
              local vTitle = FG:GetVendorTitle(c)
              if vTitle then
                local key = (c.name or "") .. ":" .. (c.zone or "")
                if not addedVendorsCount[key] then
                  addedVendorsCount[key] = true
                  local vData = { name = c.name, zone = c.zone or pZone, coords = c.coords, item = vTitle, tip = "<" .. vTitle .. ">" }
                  vCounts.all = vCounts.all + 1
                  for subKey, _ in pairs(vCounts) do
                    if subKey ~= "all" and FG:MatchesVendorSubtype(vData, subKey) then
                      vCounts[subKey] = vCounts[subKey] + 1
                    end
                  end
                end
              end
            end
          end
        end
        local vFolders = (FG.FolderTree["nearby/vendors"] and FG.FolderTree["nearby/vendors"].folders) or {}
        for _, f in ipairs(vFolders) do
          local subKey = f.path:match("^nearby/vendors/(.+)$")
          local count = (subKey and vCounts[subKey]) or 0
          table.insert(matches, {
            type = "folder",
            data = {
              name = f.name,
              path = f.path,
              desc = string.format("%d %s in %s", count, f.name, pZone),
              count = count,
              icon = f.icon,
              isAll = f.isAll,
            }
          })
        end
      end

      -- 3. Category subfolders when browsing nearby/loot with no query
      if cur == "nearby/loot" and q == "" then
        local lCounts = { armor = 0, weapons = 0, recipes = 0, accessories = 0, all = 0 }
        if FG.Data.Items then
          for _, item in pairs(FG.Data.Items) do
            if not FG:IsInternalItem(item.name) and item.source and item.source:lower():find(pZoneLower, 1, true) then
              lCounts.all = lCounts.all + 1
              local grp = FG:GetItemTypeSortKey(item)
              if grp == 1 then lCounts.weapons = lCounts.weapons + 1
              elseif grp == 2 then lCounts.armor = lCounts.armor + 1
              elseif grp == 3 then lCounts.accessories = lCounts.accessories + 1
              elseif grp == 7 then lCounts.recipes = lCounts.recipes + 1
              end
            end
          end
        end
        local lFolders = (FG.FolderTree["nearby/loot"] and FG.FolderTree["nearby/loot"].folders) or {}
        for _, f in ipairs(lFolders) do
          local subKey = f.path:match("^nearby/loot/(.+)$")
          local count = (subKey and lCounts[subKey]) or 0
          table.insert(matches, {
            type = "folder",
            data = {
              name = f.name,
              path = f.path,
              desc = string.format("%d %s in %s", count, f.name, pZone),
              count = count,
              icon = f.icon,
              isAll = f.isAll,
            }
          })
        end
      end

      -- 4. Category subfolders when browsing nearby/quests with no query
      if cur == "nearby/quests" and q == "" then
        local qCounts = { recommended = 0, story = 0, dungeons = 0, all = 0 }
        local pLvl = (UnitLevel and UnitLevel("player")) or 0
        if FG.Data.Quests then
          for _, quest in pairs(FG.Data.Quests) do
            if not FG:IsInternalQuest(quest.title) then
              local inZone = quest.zone and quest.zone:lower() == pZoneLower
              local inSub = pSubLower ~= "" and ((quest.zone and quest.zone:lower():find(pSubLower, 1, true)) or (quest.npc and quest.npc:lower():find(pSubLower, 1, true)))
              if inZone or inSub then
                qCounts.all = qCounts.all + 1
                local qz = (quest.zone or ""):lower()
                local isDungeonQuest = qz:find("deadmines") or qz:find("wailing") or qz:find("shadowfang") or qz:find("blackfathom") or qz:find("gnomeregan") or qz:find("scarlet") or qz:find("razorfen") or qz:find("uldaman") or qz:find("zul'") or qz:find("maraudon") or qz:find("blackrock") or qz:find("stratholme") or qz:find("scholomance") or qz:find("dire maul") or qz:find("molten") or qz:find("ahn'qiraj") or qz:find("naxxramas")
                if isDungeonQuest then
                  qCounts.dungeons = qCounts.dungeons + 1
                else
                  qCounts.story = qCounts.story + 1
                end
                local req = quest.reqLevel or 0
                local ql = quest.questLevel or req
                if pLvl == 0 or (pLvl >= req and pLvl <= ql + 3 and pLvl >= ql - 4) then
                  qCounts.recommended = qCounts.recommended + 1
                end
              end
            end
          end
        end
        local qFolders = (FG.FolderTree["nearby/quests"] and FG.FolderTree["nearby/quests"].folders) or {}
        for _, f in ipairs(qFolders) do
          local subKey = f.path:match("^nearby/quests/(.+)$")
          local count = (subKey and qCounts[subKey]) or 0
          table.insert(matches, {
            type = "folder",
            data = {
              name = f.name,
              path = f.path,
              desc = string.format("%d %s in %s", count, f.name, pZone),
              count = count,
              icon = f.icon,
              isAll = f.isAll,
            }
          })
        end
      end

      -- 1. Nearby Creatures & Mobs (with sub-grouping)
      if showCreatures and FG.Data.Creatures then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) then
            local isRare = (c.classification == "Boss" or c.classification == "World Boss" or c.classification == "Rare" or c.classification == "Rare Elite")
            local passesSubFilter = true
            if cur == "nearby/rares" or creatureSub == "rares" then
              passesSubFilter = isRare
            elseif creatureSub and creatureSub ~= "all" then
              passesSubFilter = CreatureMatchesFamily(c, creatureSub) and not isRare
            elseif isClosest then
              passesSubFilter = (c.coords and c.coords ~= "")
            end

            if passesSubFilter then
              local inZone = (c.zone and c.zone:lower() == pZoneLower) or (c.location and c.location:lower():find(pZoneLower, 1, true))
              local inSub = pSubLower ~= "" and ((c.location and c.location:lower():find(pSubLower, 1, true)) or (c.zone and c.zone:lower():find(pSubLower, 1, true)))
              if inZone or inSub then
                if q == "" or (c.name and c.name:lower():find(q, 1, true)) then
                  table.insert(matches, { type = "creature", data = c, isNearby = true, inSub = inSub })
                end
              end
            end
          end
        end
      end

      -- 2. Nearby Quests
      if showQuests and FG.Data.Quests then
        local qFilter = questSub or "all"
        local pLvl = (UnitLevel and UnitLevel("player")) or 0
        for _, quest in pairs(FG.Data.Quests) do
          if not FG:IsInternalQuest(quest.title) then
            local inZone = quest.zone and quest.zone:lower() == pZoneLower
            local inSub = pSubLower ~= "" and ((quest.zone and quest.zone:lower():find(pSubLower, 1, true)) or (quest.npc and quest.npc:lower():find(pSubLower, 1, true)))
            if inZone or inSub then
              local pass = false
              local qz = (quest.zone or ""):lower()
              local isDungeonQuest = qz:find("deadmines") or qz:find("wailing") or qz:find("shadowfang") or qz:find("blackfathom") or qz:find("gnomeregan") or qz:find("scarlet") or qz:find("razorfen") or qz:find("uldaman") or qz:find("zul'") or qz:find("maraudon") or qz:find("blackrock") or qz:find("stratholme") or qz:find("scholomance") or qz:find("dire maul") or qz:find("molten") or qz:find("ahn'qiraj") or qz:find("naxxramas")
              if qFilter == "all" then
                pass = true
              elseif qFilter == "recommended" then
                local req = quest.reqLevel or 0
                local ql = quest.questLevel or req
                pass = (pLvl == 0 or (pLvl >= req and pLvl <= ql + 3 and pLvl >= ql - 4))
              elseif qFilter == "story" then
                pass = not isDungeonQuest
              elseif qFilter == "dungeons" then
                pass = isDungeonQuest
              end
              if pass and (q == "" or (quest.title and quest.title:lower():find(q, 1, true))) then
                table.insert(matches, { type = "quest", data = quest, isNearby = true })
              end
            end
          end
        end
      end

      -- 3. Nearby Vendors & Flight Masters
      if showVendors then
        local addedVendors = {}
        local vFilter = vendorSub or "all"

        if (vFilter == "all" or vFilter == "flight" or vFilter == "flightpaths") and FG.Data.Flightpaths then
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

        if FG.Data.Vendors then
          for _, v in pairs(FG.Data.Vendors) do
            local vZone = v.zone
            if (vZone == "Azeroth" or vZone == "Eastern Kingdoms" or vZone == "Kalimdor" or not vZone) and v.name then
              local cObj = FG:FindCreatureByName(v.name)
              if cObj and cObj.zone then vZone = cObj.zone end
            end
            local inZone = vZone and vZone:lower() == pZoneLower
            if inZone then
              if FG:MatchesVendorSubtype(v, vFilter) then
                if q == "" or (v.name and v.name:lower():find(q, 1, true)) or (v.item and v.item:lower():find(q, 1, true)) or (v.tip and v.tip:lower():find(q, 1, true)) then
                  table.insert(matches, { type = "vendor", data = v, isNearby = true })
                  if v.name then addedVendors[v.name:lower()] = true end
                end
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
                local vData = {
                  name = c.name,
                  zone = c.zone or pZone,
                  coords = c.coords,
                  item = vTitle,
                  tip = "<" .. vTitle .. ">" .. ((c.minLevel and c.minLevel > 0) and (" • Level " .. c.minLevel) or ""),
                }
                if FG:MatchesVendorSubtype(vData, vFilter) then
                  if q == "" or c.name:lower():find(q, 1, true) or vTitle:lower():find(q, 1, true) then
                    table.insert(matches, { type = "vendor", data = vData, isNearby = true })
                    addedVendors[c.name:lower()] = true
                  end
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
        local lFilter = lootSub or "all"
        for _, item in pairs(FG.Data.Items) do
          if not FG:IsInternalItem(item.name) then
            local inSource = item.source and item.source:lower():find(pZoneLower, 1, true)
            if inSource then
              local pass = false
              local grp = FG:GetItemTypeSortKey(item)
              if lFilter == "all" then
                pass = true
              elseif lFilter == "armor" then
                pass = (grp == 2)
              elseif lFilter == "weapons" then
                pass = (grp == 1)
              elseif lFilter == "recipes" then
                pass = (grp == 7)
              elseif lFilter == "accessories" then
                pass = (grp == 3)
              end
              if pass and (q == "" or (item.name and item.name:lower():find(q, 1, true))) then
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
      local armorType = cur:match("^items/armor/([^/]+)$") or cur:match("^upgrades/([^/]+)$")
      if armorType and (armorType == "cloth" or armorType == "leather" or armorType == "mail" or armorType == "plate") and FG.Data.Items then
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

      local foreverCounts = nil
      if (cur == "forever/items" or cur == "items/forever") and FG.Data.Items then
        foreverCounts = { weapons = 0, armor = 0, accessories = 0, consumables = 0, trade_goods = 0, recipes = 0, quest = 0, all = 0 }
        for _, item in pairs(FG.Data.Items) do
          if item.isForever and not FG:IsInternalItem(item.name) then
            foreverCounts.all = foreverCounts.all + 1
            local grp = FG:GetItemTypeSortKey(item)
            if grp == 1 then foreverCounts.weapons = foreverCounts.weapons + 1
            elseif grp == 2 then foreverCounts.armor = foreverCounts.armor + 1
            elseif grp == 3 then foreverCounts.accessories = foreverCounts.accessories + 1
            elseif grp == 4 then foreverCounts.consumables = foreverCounts.consumables + 1
            elseif grp == 6 then foreverCounts.trade_goods = foreverCounts.trade_goods + 1
            elseif grp == 7 then foreverCounts.recipes = foreverCounts.recipes + 1
            elseif grp == 8 or grp == 9 then foreverCounts.quest = foreverCounts.quest + 1
            end
          end
        end
      end

      for _, f in ipairs(folderDef.folders) do
        local fCopy = f
        if slotCounts and f.path then
          local slot = f.path:match("^upgrades/[^/]+/([^/]+)$") or f.path:match("^items/armor/[^/]+/([^/]+)$")
          if slot and slotCounts[slot] then
            local count = slotCounts[slot]
            local armorCap = armorType:gsub("^%l", string.upper)
            fCopy = {
              name = f.name,
              path = f.path,
              desc = string.format("%d %s %s upgrades & drop sources (iLvl Low to High)", count, armorCap, f.name or slot),
              count = count,
              icon = f.icon,
            }
          end
        elseif foreverCounts and f.path then
          local key = f.path:match("([^/]+)$")
          if key and foreverCounts[key] then
            local count = foreverCounts[key]
            fCopy = {
              name = f.name,
              path = f.path,
              desc = string.format("%d Forever %s", count, f.name),
              count = count,
              icon = f.icon,
              isAll = f.isAll,
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
      local dFolders = (FG.FolderTree["quests/dungeons"] and FG.FolderTree["quests/dungeons"].folders) or {}
      local dCounts = {}
      local allDCount = 0
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone then
          local qz = quest.zone:lower()
          local isDung = false
          for _, f in ipairs(dFolders) do
            if not f.isAll then
              local targetName = f.name:lower()
              local matched = false
              if targetName == "the deadmines" then matched = qz:find("deadmines")
              elseif targetName == "the stockade" then matched = qz:find("stockade")
              elseif targetName:find("molten core") then matched = qz:find("molten core") or qz:find("onyxia")
              elseif targetName:find("ahn'qiraj") then matched = qz:find("ahn'qiraj")
              elseif targetName:find("blackrock spire") then matched = qz:find("blackrock spire")
              else matched = qz:find(targetName, 1, true)
              end
              if matched then
                dCounts[f.path] = (dCounts[f.path] or 0) + 1
                isDung = true
              end
            end
          end
          if isDung or qz:find("dungeon") or qz:find("deadmines") or qz:find("wailing") or qz:find("shadowfang") or qz:find("blackfathom") or qz:find("gnomeregan") or qz:find("scarlet") or qz:find("razorfen") or qz:find("uldaman") or qz:find("zul'") or qz:find("maraudon") or qz:find("blackrock") or qz:find("stratholme") or qz:find("scholomance") or qz:find("dire maul") or qz:find("molten") or qz:find("ahn'qiraj") or qz:find("naxxramas") then
            allDCount = allDCount + 1
          end
        end
      end
      for _, f in ipairs(dFolders) do
        local count = f.isAll and allDCount or (dCounts[f.path] or 0)
        table.insert(matches, {
          type = "folder",
          data = {
            name = f.name,
            path = f.path,
            desc = f.desc,
            count = count,
            icon = f.icon,
            isAll = f.isAll,
          }
        })
      end
    elseif cur:find("^quests/dungeons/(.+)$") and FG.Data.Quests then
      local dKey = cur:match("^quests/dungeons/(.+)$")
      for _, quest in pairs(FG.Data.Quests) do
        if not FG:IsInternalQuest(quest.title) and quest.zone then
          local qz = quest.zone:lower()
          local pass = false
          if dKey == "all" then
            pass = qz:find("deadmines") or qz:find("wailing") or qz:find("shadowfang") or qz:find("blackfathom") or qz:find("gnomeregan") or qz:find("scarlet") or qz:find("razorfen") or qz:find("uldaman") or qz:find("zul'") or qz:find("maraudon") or qz:find("blackrock") or qz:find("stratholme") or qz:find("scholomance") or qz:find("dire maul") or qz:find("molten") or qz:find("onyxia") or qz:find("blackwing") or qz:find("ahn'qiraj") or qz:find("naxxramas") or qz:find("dungeon")
          else
            local targetName = dKey:lower()
            if targetName == "the deadmines" then pass = qz:find("deadmines")
            elseif targetName == "the stockade" then pass = qz:find("stockade")
            elseif targetName:find("molten core") then pass = qz:find("molten core") or qz:find("onyxia")
            elseif targetName:find("ahn'qiraj") then pass = qz:find("ahn'qiraj")
            elseif targetName:find("blackrock spire") then pass = qz:find("blackrock spire")
            else pass = qz:find(targetName, 1, true)
            end
          end
          if pass then
            table.insert(matches, { type = "quest", data = quest })
          end
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
    elseif cur:find("^upgrades/([^/]+)/([^/]+)$") and FG.Data.Items then
      local armorType, slotName = cur:match("^upgrades/([^/]+)/([^/]+)$")
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe then
          local pass = false
          if armorType == "acc" or armorType == "accessories" then
            if slotName == "Shields" and (item.itemType == "Shield" or item.slot == "Shield") then pass = true
            elseif slotName == "Cloaks" and item.slot == "Back" then pass = true
            elseif slotName == "Amulets" and item.slot == "Neck" then pass = true
            elseif slotName == "Rings" and item.slot == "Finger" then pass = true
            elseif slotName == "Trinkets" and item.slot == "Trinket" then pass = true
            elseif slotName == "Off-hand" and item.slot == "Held In Off-hand" then pass = true
            elseif item.slot == slotName then pass = true
            end
          elseif item.itemType and item.itemType:lower():find(armorType) then
            if item.slot and item.slot == slotName then pass = true end
          end
          if pass then
            local key = item.id or (name .. ":" .. (item.ilvl or 0))
            if not seen[key] then
              seen[key] = true
              table.insert(matches, { type = "item", data = item })
            end
          end
        end
      end
    elseif cur == "upgrades/recommended" and FG.Data.Items then
      local _, pClass = UnitClass("player")
      pClass = (pClass or "WARRIOR"):upper()
      local pLevel = (UnitLevel and UnitLevel("player")) or 1
      if pLevel == 0 then pLevel = 1 end

      local minLvl = math.max(1, pLevel - 8)
      local maxLvl = pLevel + 4

      local allowedArmor = {}
      local wantsShield = false
      if pClass == "WARRIOR" or pClass == "PALADIN" then
        if pLevel >= 40 then
          allowedArmor["plate"] = true
          allowedArmor["mail"] = true
        else
          allowedArmor["mail"] = true
          allowedArmor["leather"] = true
        end
        wantsShield = true
      elseif pClass == "HUNTER" then
        if pLevel >= 40 then
          allowedArmor["mail"] = true
          allowedArmor["leather"] = true
        else
          allowedArmor["leather"] = true
        end
      elseif pClass == "SHAMAN" then
        if pLevel >= 40 then
          allowedArmor["mail"] = true
          allowedArmor["leather"] = true
        else
          allowedArmor["leather"] = true
        end
        wantsShield = true
      elseif pClass == "ROGUE" or pClass == "DRUID" then
        allowedArmor["leather"] = true
      elseif pClass == "MAGE" or pClass == "PRIEST" or pClass == "WARLOCK" then
        allowedArmor["cloth"] = true
      else
        allowedArmor["cloth"] = true
        allowedArmor["leather"] = true
      end

      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe then
          local iReq = tonumber(item.reqLvl) or 0
          local iLvl = tonumber(item.ilvl) or 0
          local isLevelEligible = (iReq <= maxLvl) and (iReq >= minLvl or (pLevel <= 10 and iReq <= maxLvl))
          if isLevelEligible then
            local aType = item.itemType and item.itemType:lower() or ""
            local isArmorMatch = allowedArmor[aType]
            local isAccessory = (item.slot == "Back" or item.slot == "Finger" or item.slot == "Trinket" or item.slot == "Neck")
            local isShieldMatch = wantsShield and (item.itemType == "Shield" or item.slot == "Shield")
            if isArmorMatch or isAccessory or isShieldMatch then
              local key = item.id or (name .. ":" .. iLvl)
              if not seen[key] then
                seen[key] = true
                table.insert(matches, { type = "item", data = item })
              end
            end
          end
        end
      end
    elseif cur == "upgrades/dungeons" and FG.Data.Items then
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe then
          local s = (item.source or ""):lower()
          local hasDungeonSource = s:find("deadmines") or s:find("wailing caverns") or s:find("shadowfang") or s:find("blackfathom")
            or s:find("gnomeregan") or s:find("razorfen") or s:find("scarlet") or s:find("monastery") or s:find("uldaman")
            or s:find("zul'farrak") or s:find("maraudon") or s:find("sunken temple") or s:find("blackrock") or s:find("scholomance")
            or s:find("stratholme") or s:find("dire maul") or s:find("onyxia") or s:find("molten core") or s:find("blackwing")
            or s:find("crypts") or s:find("karazhan") or s:find("dungeon") or s:find("raid")
          local droppers = FG:GetItemDroppers(item.id)
          local hasDungeonBoss = false
          if droppers and #droppers > 0 then
            for _, drop in ipairs(droppers) do
              if drop.creature and (drop.creature.classification == "Boss" or drop.creature.classification == "World Boss") then
                hasDungeonBoss = true
                break
              end
            end
          end
          if (hasDungeonSource or hasDungeonBoss) and (item.slot and item.slot ~= "" and item.slot ~= "Non-equippable") then
            local key = item.id or (name .. ":" .. (item.ilvl or 0))
            if not seen[key] then
              seen[key] = true
              table.insert(matches, { type = "item", data = item })
            end
          end
        end
      end
    elseif cur == "upgrades/quests" and FG.Data.Items then
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe then
          local s = (item.source or ""):lower()
          if s:find("quest") and (item.slot and item.slot ~= "" and item.slot ~= "Non-equippable") then
            local key = item.id or (name .. ":" .. (item.ilvl or 0))
            if not seen[key] then
              seen[key] = true
              table.insert(matches, { type = "item", data = item })
            end
          end
        end
      end
    elseif cur == "upgrades/all" and FG.Data.Items then
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:")
        if not FG:IsInternalItem(name) and not isRecipe then
          local aType = item.itemType and item.itemType:lower() or ""
          local isArmor = aType:find("cloth") or aType:find("leather") or aType:find("mail") or aType:find("plate") or aType:find("shield")
          local isAcc = item.slot == "Back" or item.slot == "Finger" or item.slot == "Trinket" or item.slot == "Neck" or item.slot == "Held In Off-hand"
          if (isArmor or isAcc) and (item.slot and item.slot ~= "" and item.slot ~= "Non-equippable") then
            local key = item.id or (name .. ":" .. (item.ilvl or 0))
            if not seen[key] then
              seen[key] = true
              table.insert(matches, { type = "item", data = item })
            end
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
            elseif subName == "Cloth Armor" and not isRecipe and item.itemType and item.itemType:find("Cloth") and item.slot and item.slot ~= "Non-equippable" then matchesFilter = true
            elseif subName == "Leather Armor" and not isRecipe and item.itemType and item.itemType:find("Leather") and item.slot and item.slot ~= "Non-equippable" then matchesFilter = true
            elseif subName == "Mail Armor" and not isRecipe and item.itemType and item.itemType:find("Mail") and item.slot and item.slot ~= "Non-equippable" then matchesFilter = true
            elseif subName == "Plate Armor" and not isRecipe and item.itemType and item.itemType:find("Plate") and item.slot and item.slot ~= "Non-equippable" then matchesFilter = true
            elseif subName == "Shields" and not isRecipe and item.slot and item.slot:find("Shield") then matchesFilter = true
            elseif subName == "Amulets" and not isRecipe and item.slot and item.slot:find("Neck") then matchesFilter = true
            elseif subName == "Rings" and not isRecipe and item.slot and item.slot:find("Finger") then matchesFilter = true
            elseif subName == "Trinkets" and not isRecipe and item.slot and item.slot:find("Trinket") then matchesFilter = true
            elseif subName == "Cloaks" and not isRecipe and item.slot and item.slot:find("Back") then matchesFilter = true
            elseif subName == "Off-hand" and not isRecipe and item.slot and (item.slot:find("Off%-hand") or item.slot:find("Off%-Hand") or item.slot == "Held in Off-hand") then matchesFilter = true
            elseif subName == "All Accessories" and not isRecipe then
              local grp = FG:GetItemTypeSortKey(item)
              if grp == 3 or (item.slot and item.slot:find("Shield")) then matchesFilter = true end
            elseif subName == "Potions" and not isRecipe then
              if item.itemType == "Potion" then matchesFilter = true
              elseif (not item.itemType or item.itemType == "Consumable" or item.itemType == "Miscellaneous") and (name:find("Potion") or name:find("Draft") or name:find("Brew") or name:find("Tears")) and not name:find("Elixir") and not name:find("Flask") then
                matchesFilter = true
              end
            elseif subName == "Elixirs" and not isRecipe then
              if item.itemType == "Elixir" or (name:find("Elixir") and not name:find("Flask")) then matchesFilter = true end
            elseif subName == "Flasks" and not isRecipe then
              if item.itemType == "Flask" or name:find("^Flask of") or name:find(" Flask") then matchesFilter = true end
            elseif subName == "Food" and not isRecipe then
              if (item.itemType and item.itemType:find("Food")) or ((item.itemType == "Consumable" or item.itemType == "Miscellaneous") and (name:find("Meat") or name:find("Bread") or name:find("Fish") or name:find("Stew") or name:find("Soup") or name:find("Water") or name:find("Juice") or name:find("Milk") or name:find("Ale") or name:find("Beer") or name:find("Wine") or name:find("Pie") or name:find("Roast") or name:find("Ribs") or name:find("Cheese") or name:find("Apple") or name:find("Fruit") or name:find("Ration") or name:find("Melon") or name:find("Tea") or name:find("Bisque") or name:find("Sausage") or name:find("Chop") or name:find("Steak"))) then
                matchesFilter = true
              end
            elseif subName == "Bandages" and not isRecipe then
              if (item.itemType and item.itemType:find("Bandage")) or name:find("Bandage") or name:find("Anti%-Venom") then matchesFilter = true end
            elseif subName == "Scrolls" and not isRecipe then
              if (item.itemType and item.itemType:find("Scroll")) or name:find("^Scroll of") then matchesFilter = true end
            elseif subName == "Oils" and not isRecipe then
              if name:find(" Oil") or name:find("Sharpening Stone") or name:find("Weightstone") or name:find("Wizard Oil") or name:find("Mana Oil") then matchesFilter = true end
            elseif subName == "All Consumables" and not isRecipe then
              local grp = FG:GetItemTypeSortKey(item)
              if grp == 4 then matchesFilter = true end
            elseif subName == "Cloth" and not isRecipe then
              if (item.slot == "Non-equippable" or not item.slot or item.slot == "") and ((item.itemType and item.itemType:find("Cloth")) or name:find("Cloth") or name:find("Bolt of") or name:find("Linen") or name:find("Wool") or name:find("Silk") or name:find("Mageweave") or name:find("Runecloth") or name:find("Mooncloth")) then
                matchesFilter = true
              end
            elseif subName == "Elemental" and not isRecipe then
              if (item.itemType and item.itemType:find("Elemental")) or name:find("Elemental ") or name:find("Essence of") or name:find("Core of") or name:find("Breath of") or name:find("Globe of") or name:find("Heart of") or name:find("Ichor of") or name:find("Living Essence") then matchesFilter = true end
            elseif subName == "Gems" and not isRecipe then
              if (item.itemType and item.itemType:find("Gem")) or name:find("Malachite") or name:find("Tigerseye") or name:find("Shadowgem") or name:find("Ruby") or name:find("Sapphire") or name:find("Diamond") or name:find("Emerald") or name:find("Topaz") or name:find("Pearl") or name:find("Agate") or name:find("Citrine") or name:find("Aquamarine") or name:find("Opal") then matchesFilter = true end
            elseif subName == "Herbs" and not isRecipe then
              if (item.itemType and item.itemType:find("Herb")) or name:find("Peacebloom") or name:find("Silverleaf") or name:find("Earthroot") or name:find("Mageroyal") or name:find("Briarthorn") or name:find("Stranglekelp") or name:find("Bruiseweed") or name:find("Wild Steelbloom") or name:find("Grave Moss") or name:find("Kingsblood") or name:find("Liferoot") or name:find("Fadeleaf") or name:find("Goldthorn") or name:find("Khadgar") or name:find("Wintersbite") or name:find("Firebloom") or name:find("Purple Lotus") or name:find("Arthas") or name:find("Sungrass") or name:find("Blindweed") or name:find("Ghost Mushroom") or name:find("Gromsblood") or name:find("Golden Sansam") or name:find("Dreamfoil") or name:find("Mountain Silversage") or name:find("Plaguebloom") or name:find("Icecap") or name:find("Black Lotus") then matchesFilter = true end
            elseif subName == "Leather" and not isRecipe then
              if (item.slot == "Non-equippable" or not item.slot or item.slot == "") and ((item.itemType and item.itemType:find("Leather")) or name:find("Leather") or name:find("Hide") or name:find("Scale") or name:find("Pelt")) then
                matchesFilter = true
              end
            elseif subName == "Ore" and not isRecipe then
              if (item.itemType and (item.itemType:find("Metal") or item.itemType:find("Stone") or item.itemType:find("Ore"))) or name:find("Ore") or name:find(" Bar") or (name:find("Stone") and not name:find("Sharpening") and not name:find("Weightstone")) or name:find("Flux") then matchesFilter = true end
            elseif subName == "Parts" and not isRecipe then
              if (item.itemType and (item.itemType:find("Parts") or item.itemType:find("Device"))) or name:find("Tube") or name:find("Fuse") or name:find("Gear") or name:find("Trigger") or name:find("Casing") or name:find("Dynamite") or name:find("Bomb") or name:find("Wire") or name:find("Blasting Powder") then matchesFilter = true end
            elseif subName == "Reagents" and not isRecipe then
              if (item.itemType and item.itemType:find("Reagent")) or name:find("Dust") or name:find("Essence") or name:find("Shard") or name:find("Crystal") or name:find("Thread") or name:find("Dye") or name:find("Vial") or name:find("Potion Vial") or name:find("Ankh") or name:find("Rune of") or name:find("Flash Powder") or name:find("Wild Berries") or name:find("Wild Thornroot") or name:find("Sacred Candle") then matchesFilter = true end
            elseif subName == "All Trade Goods" and not isRecipe then
              local grp = FG:GetItemTypeSortKey(item)
              if grp == 6 then matchesFilter = true end
            elseif subName == "Bags" and not isRecipe then
              if (item.slot == "Bag" or (item.itemType and item.itemType == "Bag")) and not (name:find("Quiver") or name:find("Ammo") or name:find("Shot") or name:find("Herb") or name:find("Enchant") or name:find("Soul")) then matchesFilter = true end
            elseif subName == "Quivers" and not isRecipe then
              if (item.itemType and (item.itemType:find("Quiver") or item.itemType:find("Ammo"))) or name:find("Quiver") or name:find("Ammo Pouch") or name:find("Bandolier") or name:find("Shot Pouch") then matchesFilter = true end
            elseif subName == "Specialty_Bags" and not isRecipe then
              if name:find("Soul Pouch") or name:find("Box of Souls") or name:find("Herb Pouch") or name:find("Herb Bag") or name:find("Cenarion Herb Bag") or name:find("Enchanter's") or name:find("Big Bag of Enchantment") then matchesFilter = true end
            elseif subName == "All Containers" and not isRecipe then
              if (item.slot == "Bag" or (item.itemType and item.itemType == "Bag") or name:find("Quiver") or name:find("Ammo") or name:find("Shot") or name:find("Herb") or name:find("Enchant") or name:find("Soul") or name:find("Pouch") or name:find("Bag")) then matchesFilter = true end
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
    elseif cur:find("^items/recipes/") and FG.Data.Items then
      local prof = cur:match("^items/recipes/([^/]+)$")
      local seen = {}
      for _, item in pairs(FG.Data.Items) do
        local name = item.name or ""
        if not FG:IsInternalItem(name) then
          local isRecipe = name:find("^Plans:") or name:find("^Pattern:") or name:find("^Schematic:") or name:find("^Formula:") or name:find("^Recipe:") or name:find("^Manual:") or (item.itemType and item.itemType:find("Recipe"))
          if isRecipe then
            local eff = (item.effects or ""):lower()
            local itype = item.itemType or ""
            local pass = false
            if prof == "all" then
              pass = true
            elseif prof == "blacksmithing" then
              pass = (name:find("^Plans:") ~= nil)
            elseif prof == "enchanting" then
              pass = (name:find("^Formula:") ~= nil)
            elseif prof == "engineering" then
              pass = (name:find("^Schematic:") ~= nil)
            elseif prof == "first_aid" then
              pass = (name:find("^Manual:") ~= nil or name:find("First Aid") ~= nil)
            elseif prof == "alchemy" then
              if name:find("^Recipe:") then
                pass = name:find("Potion") or name:find("Elixir") or name:find("Flask") or name:find("Transmute") or name:find("Oil") or name:find("Firewater") or name:find("Philosopher") or name:find("Gniodine") or name:find("Rejuvenation") or name:find("Spellblasting") or name:find("Frenzy Potion") or eff:find("brew") or eff:find("distill") or eff:find("transmute") or eff:find("make a") or eff:find("make an")
              end
            elseif prof == "cooking" then
              if name:find("^Recipe:") then
                local isAlch = name:find("Potion") or name:find("Elixir") or name:find("Flask") or name:find("Transmute") or name:find("Oil") or name:find("Firewater") or name:find("Philosopher") or name:find("Gniodine") or name:find("Rejuvenation") or name:find("Spellblasting") or name:find("Frenzy Potion") or eff:find("brew") or eff:find("distill") or eff:find("transmute") or eff:find("make a") or eff:find("make an")
                pass = not isAlch
              end
            elseif prof == "tailoring" then
              if name:find("^Pattern:") then
                pass = (itype == "Cloth") or name:find("Cloth") or name:find("Robe") or name:find("Shirt") or name:find("Bag") or name:find("Pouch") or name:find("Mooncloth") or name:find("Silk") or name:find("Linen") or name:find("Wool") or name:find("Mageweave") or name:find("Runecloth") or name:find("Shadoweave") or name:find("Felcloth") or name:find("Ghostweave") or name:find("Dress") or name:find("Pantaloons")
              end
            elseif prof == "leatherworking" then
              if name:find("^Pattern:") then
                local isTailoring = (itype == "Cloth") or name:find("Cloth") or name:find("Robe") or name:find("Shirt") or name:find("Bag") or name:find("Pouch") or name:find("Mooncloth") or name:find("Silk") or name:find("Linen") or name:find("Wool") or name:find("Mageweave") or name:find("Runecloth") or name:find("Shadoweave") or name:find("Felcloth") or name:find("Ghostweave") or name:find("Dress") or name:find("Pantaloons")
                pass = not isTailoring
              end
            end

            if pass then
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
      table.insert(matches, {
        type = "folder",
        data = {
          name = string.format("[All %s (Full List)]", famCap),
          path = "creatures/" .. sub .. "/all",
          desc = string.format("All %s across Azeroth", famCap),
          icon = "Interface\\Icons\\Ability_Tracking",
          isAll = true,
        }
      })
      if q ~= "" then
        for _, c in pairs(FG.Data.Creatures) do
          if not FG:IsInternalCreature(c.name, c.family) and CreatureMatchesFamily(c, sub) then
            if c.name and c.name:lower():find(q, 1, true) then
              table.insert(matches, { type = "creature", data = c })
            end
          end
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
    elseif cur:find("^vendors/") and (FG.Data.Vendors or FG.Data.Flightpaths or FG.Data.Creatures) then
      local vSub = cur:match("^vendors/([^/]+)$")
      local added = {}
      if (vSub == "flightpaths" or vSub == "all") and FG.Data.Flightpaths then
        for _, fp in pairs(FG.Data.Flightpaths) do
          local key = (fp.name or "") .. ":" .. (fp.zone or "")
          if not added[key] then
            added[key] = true
            table.insert(matches, { type = "vendor", data = { name = fp.name, zone = fp.zone, coords = fp.coords, item = fp.faction .. " Flight Master", tip = fp.notes or fp.connections } })
          end
        end
      end

      if vSub ~= "flightpaths" then
        if FG.Data.Vendors then
          for _, v in pairs(FG.Data.Vendors) do
            if FG:MatchesVendorSubtype(v, vSub) then
              local key = (v.name or "") .. ":" .. (v.zone or "")
              if not added[key] then
                added[key] = true
                table.insert(matches, { type = "vendor", data = v })
              end
            end
          end
        end

        if FG.Data.Creatures then
          for _, c in pairs(FG.Data.Creatures) do
            if not FG:IsInternalCreature(c.name, c.family) then
              local vTitle = FG:GetVendorTitle(c)
              if vTitle then
                local vObj = {
                  name = c.name,
                  zone = c.zone,
                  coords = c.coords,
                  item = vTitle,
                  tip = "<" .. vTitle .. ">" .. ((c.minLevel and c.minLevel > 0) and (" • Level " .. c.minLevel) or ""),
                }
                if FG:MatchesVendorSubtype(vObj, vSub) then
                  local key = (c.name or "") .. ":" .. (c.zone or "")
                  if not added[key] then
                    added[key] = true
                    table.insert(matches, { type = "vendor", data = vObj })
                  end
                end
              end
            end
          end
        end
      end
    elseif cur:find("^forever/items/") or cur:find("^items/forever/") then
      local subType = cur:match("^forever/items/([^/]+)$") or cur:match("^items/forever/([^/]+)$")
      if subType and FG.Data.Items then
        for _, item in pairs(FG.Data.Items) do
          if item.isForever and not FG:IsInternalItem(item.name) then
            local grp, dType = FG:GetItemTypeSortKey(item)
            local pass = false
            if subType == "all" then
              pass = true
            elseif subType == "weapons" and grp == 1 then
              pass = true
            elseif subType == "armor" and grp == 2 then
              pass = true
            elseif subType == "accessories" and grp == 3 then
              pass = true
            elseif subType == "consumables" and grp == 4 then
              pass = true
            elseif subType == "trade_goods" and grp == 6 then
              pass = true
            elseif subType == "recipes" and grp == 7 then
              pass = true
            elseif subType == "quest" and (grp == 8 or grp == 9) then
              pass = true
            end
            if pass then
              table.insert(matches, { type = "item", data = item })
            end
          end
        end
      end
    elseif cur:find("^forever/") then
      local sub = cur:sub(9)
      if sub == "items" and FG.Data.Items and not (FG.FolderTree[cur] and FG.FolderTree[cur].folders) then
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
      elseif sub == "spells" and FG.Data.Spells then
        for _, s in pairs(FG.Data.Spells) do
          if s.isForever then table.insert(matches, { type = "spell", data = s }) end
        end
      end
    elseif cur == "spells/all" and FG.Data.Spells then
      for _, s in pairs(FG.Data.Spells) do
        table.insert(matches, { type = "spell", data = s })
      end
    elseif cur == "spells/forever" and FG.Data.Spells then
      for _, s in pairs(FG.Data.Spells) do
        if s.isForever then table.insert(matches, { type = "spell", data = s }) end
      end
    elseif cur == "spells/racials" and FG.Data.Spells then
      for _, s in pairs(FG.Data.Spells) do
        if s.class == "Racial" then table.insert(matches, { type = "spell", data = s }) end
      end
    elseif cur:find("^spells/([^/]+)$") and FG.Data.Spells then
      local cls = cur:match("^spells/([^/]+)$"):lower()
      for _, s in pairs(FG.Data.Spells) do
        if s.class and s.class:lower() == cls then
          table.insert(matches, { type = "spell", data = s })
        end
      end
    end

  else
    -- Active search query filtered by category
    local maxItems = (cat == "all") and 120 or 300
    local maxSpells = (cat == "all") and 100 or 250
    local maxQuests = (cat == "all") and 100 or 250
    local maxCreatures = (cat == "all") and 100 or 250
    local maxVendors = (cat == "all") and 100 or 250
    local maxDungeons = 50

    if (cat == "all" or cat == "spells") and FG.Data.Spells then
      local count = 0
      for _, s in pairs(FG.Data.Spells) do
        s._nl = s._nl or (s.name and s.name:lower() or "")
        s._cl = s._cl or (s.class and s.class:lower() or "")
        s._rl = s._rl or (s.rank and s.rank:lower() or "")
        s._dl = s._dl or (s.desc and s.desc:lower() or "")
        local matchName = s._nl ~= "" and s._nl:find(q, 1, true)
        local matchClass = s._cl ~= "" and s._cl:find(q, 1, true)
        local matchRank = s._rl ~= "" and s._rl:find(q, 1, true)
        local matchDesc = s._dl ~= "" and s._dl:find(q, 1, true)
        if matchName or matchClass or matchRank or matchDesc then
          local score = 5
          if s._nl == q then score = 1
          elseif s._nl:sub(1, #q) == q then score = 2
          elseif matchName then
            local pos = s._nl:find(q, 1, true)
            local prevChar = (pos and pos > 1) and s._nl:sub(pos - 1, pos - 1) or " "
            score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
          end
          table.insert(matches, { type = "spell", data = s, score = score, nl = s._nl })
          count = count + 1
          if count >= maxSpells then break end
        end
      end
    end

    if (cat == "all" or cat == "items") and FG.Data.Items then
      local count = 0
      for _, item in pairs(FG.Data.Items) do
        if item._isInternal == nil then item._isInternal = FG:IsInternalItem(item.name) end
        if not item._isInternal and item.name then
          item._nl = item._nl or item.name:lower()
          item._sl = item._sl or (item.source and item.source:lower() or "")
          local matchName = item._nl:find(q, 1, true)
          local matchSource = item._sl ~= "" and item._sl:find(q, 1, true)
          if matchName or matchSource then
            local score = 5
            if item._nl == q then score = 1
            elseif item._nl:sub(1, #q) == q then score = 2
            elseif matchName then
              local pos = item._nl:find(q, 1, true)
              local prevChar = (pos and pos > 1) and item._nl:sub(pos - 1, pos - 1) or " "
              score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
            end
            table.insert(matches, { type = "item", data = item, score = score, nl = item._nl })
            count = count + 1
            if count >= maxItems then break end
          end
        end
      end
    end

    if (cat == "all" or cat == "quests") and FG.Data.Quests then
      local count = 0
      local isSpecialStatus = (q == "completed" or q == "done" or q == "uncompleted" or q == "incomplete" or q == "active" or q == "in progress")
      for _, quest in pairs(FG.Data.Quests) do
        if quest._isInternal == nil then quest._isInternal = FG:IsInternalQuest(quest.title) end
        if not quest._isInternal then
          quest._tl = quest._tl or (quest.title and quest.title:lower() or "")
          quest._nl = quest._nl or (quest.npc and quest.npc:lower() or "")
          quest._zl = quest._zl or (quest.zone and quest.zone:lower() or "")
          quest._ol = quest._ol or (quest.objectives and quest.objectives:lower() or "")
          quest._tpl = quest._tpl or (quest.tip and quest.tip:lower() or "")

          local matchTitle = quest._tl ~= "" and quest._tl:find(q, 1, true)
          local matchNpc = quest._nl ~= "" and quest._nl:find(q, 1, true)
          local matchZone = quest._zl ~= "" and quest._zl:find(q, 1, true)
          local matchObj = quest._ol ~= "" and quest._ol:find(q, 1, true)
          local matchTip = quest._tpl ~= "" and quest._tpl:find(q, 1, true)
          local matchStatus = false
          if isSpecialStatus then
            if q == "completed" or q == "done" then
              matchStatus = (FG:GetQuestStatus(quest.id, quest.title) == "completed")
            elseif q == "uncompleted" or q == "incomplete" then
              matchStatus = (FG:GetQuestStatus(quest.id, quest.title) == "uncompleted")
            elseif q == "active" or q == "in progress" then
              local st = FG:GetQuestStatus(quest.id, quest.title)
              matchStatus = (st == "active" or st == "ready_to_turn_in")
            end
          end
          if matchTitle or matchNpc or matchZone or matchObj or matchTip or matchStatus then
            local score = 5
            if quest._tl == q then score = 1
            elseif quest._tl:sub(1, #q) == q then score = 2
            elseif matchTitle then
              local pos = quest._tl:find(q, 1, true)
              local prevChar = (pos and pos > 1) and quest._tl:sub(pos - 1, pos - 1) or " "
              score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
            end
            table.insert(matches, { type = "quest", data = quest, score = score, nl = quest._tl })
            count = count + 1
            if count >= maxQuests then break end
          end
        end
      end
    end

    if (cat == "all" or cat == "creatures") and FG.Data.Creatures then
      local count = 0
      for _, c in pairs(FG.Data.Creatures) do
        if c._isInternal == nil then c._isInternal = FG:IsInternalCreature(c.name, c.family) end
        if not c._isInternal then
          c._nl = c._nl or (c.name and c.name:lower() or "")
          c._zl = c._zl or (c.zone and c.zone:lower() or "")
          c._ll = c._ll or (c.location and c.location:lower() or "")
          local matchName = c._nl ~= "" and c._nl:find(q, 1, true)
          local matchZone = c._zl ~= "" and c._zl:find(q, 1, true)
          local matchLoc = c._ll ~= "" and c._ll:find(q, 1, true)
          if matchName or matchZone or matchLoc then
            local score = 5
            if c._nl == q then score = 1
            elseif c._nl:sub(1, #q) == q then score = 2
            elseif matchName then
              local pos = c._nl:find(q, 1, true)
              local prevChar = (pos and pos > 1) and c._nl:sub(pos - 1, pos - 1) or " "
              score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
            end
            table.insert(matches, { type = "creature", data = c, score = score, nl = c._nl })
            count = count + 1
            if count >= maxCreatures then break end
          end
        end
      end
    end

    if (cat == "all" or cat == "dungeons") and FG.Data.Dungeons then
      local count = 0
      for _, d in pairs(FG.Data.Dungeons) do
        d._nl = d._nl or (d.name and d.name:lower() or "")
        d._zl = d._zl or (d.zone and d.zone:lower() or "")
        local matchName = d._nl ~= "" and d._nl:find(q, 1, true)
        local matchZone = d._zl ~= "" and d._zl:find(q, 1, true)
        if matchName or matchZone then
          local score = 5
          if d._nl == q then score = 1
          elseif d._nl:sub(1, #q) == q then score = 2
          elseif matchName then
            local pos = d._nl:find(q, 1, true)
            local prevChar = (pos and pos > 1) and d._nl:sub(pos - 1, pos - 1) or " "
            score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
          end
          table.insert(matches, { type = "dungeon", data = d, score = score, nl = d._nl })
          count = count + 1
          if count >= maxDungeons then break end
        end
      end
    end

    if (cat == "all" or cat == "vendors") then
      local addedGlobalVendors = {}
      local count = 0
      if FG.Data.Vendors then
        for _, v in pairs(FG.Data.Vendors) do
          local vZone = v.zone
          if (vZone == "Azeroth" or vZone == "Eastern Kingdoms" or vZone == "Kalimdor" or not vZone) and v.name then
            local cObj = FG:FindCreatureByName(v.name)
            if cObj and cObj.zone then vZone = cObj.zone end
          end
          v._nl = v._nl or (v.name and v.name:lower() or "")
          v._il = v._il or (v.item and v.item:lower() or "")
          v._zl = v._zl or (vZone and vZone:lower() or "")
          local matchName = v._nl ~= "" and v._nl:find(q, 1, true)
          local matchItem = v._il ~= "" and v._il:find(q, 1, true)
          local matchZone = v._zl ~= "" and v._zl:find(q, 1, true)
          if matchName or matchItem or matchZone then
            local score = 5
            if v._nl == q then score = 1
            elseif v._nl:sub(1, #q) == q then score = 2
            elseif matchName then
              local pos = v._nl:find(q, 1, true)
              local prevChar = (pos and pos > 1) and v._nl:sub(pos - 1, pos - 1) or " "
              score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
            end
            table.insert(matches, { type = "vendor", data = v, score = score, nl = v._nl })
            if v._nl ~= "" then addedGlobalVendors[v._nl] = true end
            count = count + 1
            if count >= maxVendors then break end
          end
        end
      end
      if FG.Data.Flightpaths and count < maxVendors then
        for _, fp in pairs(FG.Data.Flightpaths) do
          fp._nl = fp._nl or (fp.name and fp.name:lower() or "")
          fp._zl = fp._zl or (fp.zone and fp.zone:lower() or "")
          local matchName = fp._nl ~= "" and fp._nl:find(q, 1, true)
          local matchZone = fp._zl ~= "" and fp._zl:find(q, 1, true)
          if matchName or matchZone then
            local vData = { name = fp.name, zone = fp.zone, coords = fp.coords, item = fp.faction .. " Flight Master", tip = fp.notes or fp.connections }
            local score = 5
            if fp._nl == q then score = 1
            elseif fp._nl:sub(1, #q) == q then score = 2
            elseif matchName then
              local pos = fp._nl:find(q, 1, true)
              local prevChar = (pos and pos > 1) and fp._nl:sub(pos - 1, pos - 1) or " "
              score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
            end
            table.insert(matches, { type = "vendor", data = vData, score = score, nl = fp._nl })
            if fp._nl ~= "" then addedGlobalVendors[fp._nl] = true end
            count = count + 1
            if count >= maxVendors then break end
          end
        end
      end
      if cat == "vendors" and FG.Data.Creatures and count < maxVendors then
        for _, c in pairs(FG.Data.Creatures) do
          if c._isInternal == nil then c._isInternal = FG:IsInternalCreature(c.name, c.family) end
          if not c._isInternal then
            c._nl = c._nl or (c.name and c.name:lower() or "")
            if c._vTitle == nil then
              c._vTitle = FG:GetVendorTitle(c) or false
            end
            local vTitle = c._vTitle
            if vTitle and c._nl ~= "" and not addedGlobalVendors[c._nl] then
              c._vtl = c._vtl or vTitle:lower()
              c._zl = c._zl or (c.zone and c.zone:lower() or "")
              local matchName = c._nl:find(q, 1, true)
              local matchTitle = c._vtl:find(q, 1, true)
              local matchZone = c._zl:find(q, 1, true)
              if matchName or matchTitle or matchZone then
                local vData = {
                  name = c.name,
                  zone = c.zone,
                  coords = c.coords,
                  item = vTitle,
                  tip = "<" .. vTitle .. ">" .. ((c.minLevel and c.minLevel > 0) and (" • Level " .. c.minLevel) or ""),
                }
                local score = 5
                if c._nl == q then score = 1
                elseif c._nl:sub(1, #q) == q then score = 2
                elseif matchName then
                  local pos = c._nl:find(q, 1, true)
                  local prevChar = (pos and pos > 1) and c._nl:sub(pos - 1, pos - 1) or " "
                  score = (prevChar:match("%s") or prevChar:match("[^%a%d]")) and 3 or 4
                end
                table.insert(matches, { type = "vendor", data = vData, score = score, nl = c._nl })
                addedGlobalVendors[c._nl] = true
                count = count + 1
                if count >= maxVendors then break end
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
      local typeRankA = (a.type == "item" and 1) or (a.type == "spell" and 2) or (a.type == "quest" and 3) or (a.type == "creature" and 4) or (a.type == "dungeon" and 5) or 6
      local typeRankB = (b.type == "item" and 1) or (b.type == "spell" and 2) or (b.type == "quest" and 3) or (b.type == "creature" and 4) or (b.type == "dungeon" and 5) or 6
      if typeRankA ~= typeRankB then
        return typeRankA < typeRankB
      end

      -- Within the same type, best match relevance tier comes first
      local scoreA = a.score or GetSearchMatchScore(a, q)
      local scoreB = b.score or GetSearchMatchScore(b, q)
      if scoreA ~= scoreB then
        return scoreA < scoreB
      end

      -- Within same type & score tier:
      if a.type == "item" and b.type == "item" then
        local groupA, typeA = FG:GetItemTypeSortKey(a.data)
        local groupB, typeB = FG:GetItemTypeSortKey(b.data)
        if groupA ~= groupB then
          return groupA < groupB
        end
        if typeA ~= typeB then
          return typeA < typeB
        end
        local nlA = a.nl or ((a.data and (a.data.name or a.data.title or "")) or ""):lower()
        local nlB = b.nl or ((b.data and (b.data.name or b.data.title or "")) or ""):lower()
        if nlA ~= nlB then
          return nlA < nlB
        end
        local ilvlA = tonumber(a.data and a.data.ilvl) or 0
        local ilvlB = tonumber(b.data and b.data.ilvl) or 0
        if ilvlA ~= ilvlB then return ilvlA < ilvlB end
      elseif a.type == "spell" and b.type == "spell" then
        local nlA = a.nl or ((a.data and a.data.name) or ""):lower()
        local nlB = b.nl or ((b.data and b.data.name) or ""):lower()
        if nlA ~= nlB then
          return nlA < nlB
        end
        local lvlA = tonumber(a.data and a.data.reqLevel) or 0
        local lvlB = tonumber(b.data and b.data.reqLevel) or 0
        if lvlA ~= lvlB then return lvlA < lvlB end
      end

      local nlA = a.nl or ((a.data and (a.data.title or a.data.name or "")) or ""):lower()
      local nlB = b.nl or ((b.data and (b.data.title or b.data.name or "")) or ""):lower()
      return nlA < nlB
    end

    -- Folder browsing (q == ""):
    if a.type == "item" and b.type == "item" then
      if cur == "upgrades/recommended" then
        local qRank = { ["Legendary"] = 1, ["Epic"] = 2, ["Rare"] = 3, ["Uncommon"] = 4, ["Common"] = 5, ["Poor"] = 6 }
        local rA = qRank[a.data and a.data.quality or "Common"] or 5
        local rB = qRank[b.data and b.data.quality or "Common"] or 5
        if rA ~= rB then return rA < rB end
        local ilvlA = tonumber(a.data and a.data.ilvl) or 0
        local ilvlB = tonumber(b.data and b.data.ilvl) or 0
        if ilvlA ~= ilvlB then return ilvlA > ilvlB end
        return ((a.data and a.data.name) or "") < ((b.data and b.data.name) or "")
      end

      local isLeafItemFolder = cur:find("^items/sub/")
        or cur:find("^items/armor/[^/]+/[^/]+$")
        or cur:find("^upgrades/[^/]+/[^/]+$")
        or cur:find("^upgrades/acc/")
        or (cur:find("^items/recipes/") and cur ~= "items/recipes/all")
        or (cur:find("^forever/items/") and cur ~= "forever/items/all" and cur ~= "forever/items")
        or (cur:find("^items/forever/") and cur ~= "items/forever/all" and cur ~= "items/forever")

      if isLeafItemFolder and cur ~= "items/sub/All Consumables" and cur ~= "items/sub/All Trade Goods" then
        local ilvlA = tonumber(a.data and a.data.ilvl) or 0
        local ilvlB = tonumber(b.data and b.data.ilvl) or 0
        if ilvlA ~= ilvlB then
          return ilvlA < ilvlB
        end
        local nameA = (a.data and (a.data.name or a.data.title or "")) or ""
        local nameB = (b.data and (b.data.name or b.data.title or "")) or ""
        return nameA:lower() < nameB:lower()
      else
        local groupA, typeA = FG:GetItemTypeSortKey(a.data)
        local groupB, typeB = FG:GetItemTypeSortKey(b.data)
        if groupA ~= groupB then
          return groupA < groupB
        end
        if typeA ~= typeB then
          return typeA < typeB
        end
        local ilvlA = tonumber(a.data and a.data.ilvl) or 0
        local ilvlB = tonumber(b.data and b.data.ilvl) or 0
        if ilvlA ~= ilvlB then
          return ilvlA < ilvlB
        end
        local nameA = (a.data and (a.data.name or a.data.title or "")) or ""
        local nameB = (b.data and (b.data.name or b.data.title or "")) or ""
        return nameA:lower() < nameB:lower()
      end
    end

    if a.type == "creature" and b.type == "creature" then
      local classRankA = (a.data and (a.data.classification == "Boss" or a.data.classification == "World Boss") and 1)
        or (a.data and (a.data.classification == "Rare Elite") and 2)
        or (a.data and (a.data.classification == "Rare") and 3)
        or (a.data and (a.data.classification == "Elite") and 4) or 5
      local classRankB = (b.data and (b.data.classification == "Boss" or b.data.classification == "World Boss") and 1)
        or (b.data and (b.data.classification == "Rare Elite") and 2)
        or (b.data and (b.data.classification == "Rare") and 3)
        or (b.data and (b.data.classification == "Elite") and 4) or 5
      if classRankA ~= classRankB then
        return classRankA < classRankB
      end
      local famA = (a.data and a.data.family or ""):lower()
      local famB = (b.data and b.data.family or ""):lower()
      if famA ~= famB then
        return famA < famB
      end
      local lvlA = tonumber(a.data and (a.data.maxLevel or a.data.minLevel)) or 0
      local lvlB = tonumber(b.data and (b.data.maxLevel or b.data.minLevel)) or 0
      if lvlA ~= lvlB then
        return lvlA < lvlB
      end
      local nameA = (a.data and a.data.name or ""):lower()
      local nameB = (b.data and b.data.name or ""):lower()
      return nameA < nameB
    end

    if a.type == "quest" and b.type == "quest" then
      local znA = (a.data and (a.data.zone or a.data.category or "")) or ""
      local znB = (b.data and (b.data.zone or b.data.category or "")) or ""
      if znA:lower() ~= znB:lower() then
        return znA:lower() < znB:lower()
      end
      local lvlA = tonumber(a.data and (a.data.reqLevel or a.data.questLevel)) or 0
      local lvlB = tonumber(b.data and (b.data.reqLevel or b.data.questLevel)) or 0
      if lvlA ~= lvlB then
        return lvlA < lvlB
      end
      local tA = (a.data and a.data.title or ""):lower()
      local tB = (b.data and b.data.title or ""):lower()
      return tA < tB
    end

    if a.type == "spell" and b.type == "spell" then
      local clsA = (a.data and a.data.class or ""):lower()
      local clsB = (b.data and b.data.class or ""):lower()
      if clsA ~= clsB then
        return clsA < clsB
      end
      local lvlA = tonumber(a.data and a.data.reqLevel) or 0
      local lvlB = tonumber(b.data and b.data.reqLevel) or 0
      if lvlA ~= lvlB then
        return lvlA < lvlB
      end
      local nameA = (a.data and a.data.name or ""):lower()
      local nameB = (b.data and b.data.name or ""):lower()
      return nameA < nameB
    end

    if a.type == "dungeon" and b.type == "dungeon" then
      local tierA = (a.data and a.data.isForever and 5)
        or (a.data and a.data.minLevel == 60 and 4)
        or (a.data and a.data.minLevel and a.data.minLevel > 45 and 3)
        or (a.data and a.data.minLevel and a.data.minLevel > 25 and 2) or 1
      local tierB = (b.data and b.data.isForever and 5)
        or (b.data and b.data.minLevel == 60 and 4)
        or (b.data and b.data.minLevel and b.data.minLevel > 45 and 3)
        or (b.data and b.data.minLevel and b.data.minLevel > 25 and 2) or 1
      if tierA ~= tierB then
        return tierA < tierB
      end
      local minA = tonumber(a.data and a.data.minLevel) or 0
      local minB = tonumber(b.data and b.data.minLevel) or 0
      if minA ~= minB then
        return minA < minB
      end
      local nameA = (a.data and a.data.name or ""):lower()
      local nameB = (b.data and b.data.name or ""):lower()
      return nameA < nameB
    end

    if a.type == "vendor" and b.type == "vendor" then
      local itemA = (a.data and (a.data.item or "") or ""):lower()
      local itemB = (b.data and (b.data.item or "") or ""):lower()
      if itemA ~= itemB then
        return itemA < itemB
      end
      local znA = (a.data and (a.data.zone or "") or ""):lower()
      local znB = (b.data and (b.data.zone or "") or ""):lower()
      if znA ~= znB then
        return znA < znB
      end
      local nameA = (a.data and (a.data.name or "") or ""):lower()
      local nameB = (b.data and (b.data.name or "") or ""):lower()
      return nameA < nameB
    end

    local isNearbyView = (cur:find("^nearby") ~= nil) or (cat == "nearby") or a.isNearby or b.isNearby
    if isNearbyView then
      if a.inSub and not b.inSub then return true end
      if b.inSub and not a.inSub then return false end

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
        if cur == "nearby" or cat == "nearby" or cur:find("^nearby") then
          local pZone = FG:GetPlayerZoneInfo()
          if q ~= "" then
            content.NoResultsState.Title:SetText("|cffff8080No nearby intel matching \"|r|cffffffff" .. (query or "") .. "|r|cffff8080\" in " .. pZone .. "|r")
          else
            content.NoResultsState.Title:SetText("|cffff8080No nearby intel found in " .. pZone .. "|r")
          end
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

      if cur == "nearby" or cat == "nearby" or cur:find("^nearby") then
        cw.StatusText:SetText("|cff20ff20" .. countStr .. " nearby points of interest (" .. (FG.lastKnownZone or "Local Area") .. ")|r")
      elseif folderCount == #matches then
        cw.StatusText:SetText("|cffdf80ff" .. countStr .. " categories in view|r")
      elseif itemCount == #matches then
        if cat == "upgrades" or cur:find("^upgrades") then
          cw.StatusText:SetText("|cff38bdf8" .. countStr .. " armor upgrades in view (sorted by type & source)|r")
        elseif isItemView or cat == "items" then
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
    local defaultRadius = 80
    local radius = (ForeverGuideDB and ForeverGuideDB.minimap and ForeverGuideDB.minimap.radius) or defaultRadius
    if not radius or radius > 90 or radius < 70 then
      radius = defaultRadius
      if ForeverGuideDB and ForeverGuideDB.minimap then
        ForeverGuideDB.minimap.radius = radius
      end
    end
    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local cosA, sinA = math.cos(rad), math.sin(rad)
    if minimapShape == "ROUND" then
      btn:SetPoint("CENTER", Minimap, "CENTER", cosA * radius, sinA * radius)
    else
      local diagRadius = radius * 1.289
      local sx = math.max(-radius, math.min(cosA * diagRadius, radius))
      local sy = math.max(-radius, math.min(sinA * diagRadius, radius))
      btn:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
    end
  end
  btn.UpdatePosition = UpdatePosition

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
    if ForeverGuideDB.minimap and (not ForeverGuideDB.minimap.radius or ForeverGuideDB.minimap.radius > 90 or ForeverGuideDB.minimap.radius < 70) then
      ForeverGuideDB.minimap.radius = 80
    end

    FG:CreateSparkFrame()
    FG:CreateMinimapButton()
    FG:InitMapPins()

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
    FG:HookWorldMap()
    FG:UpdateMapPins()

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
    FG:UpdateMapPins()
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
    FG:UpdateMapPins()
    if FG.CodexWindow and FG.CodexWindow:IsShown() and FG.activeCategory == "upgrades" then
      FG:PopulateCodexResults(ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or "")
    end

  elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" or event == "QUEST_FINISHED" or event == "QUEST_WATCH_UPDATE" then
    FG:UpdateMapPins()
    if FG.CodexWindow and FG.CodexWindow:IsShown() then
      local cat = FG.activeCategory
      local cur = FG.currentFolder
      if cat == "quests" or cat == "nearby" or (cur and (cur:find("^quests") or cur:find("^nearby"))) then
        FG:PopulateCodexResults(ForeverGuideSearchBox and ForeverGuideSearchBox:GetText():trim() or "")
      end
    end
  end
end)

