--[[
  ForeverGuide.lua
  Warcraft Forever Addon: The Blue Spark Companion
  Version: 1.0.0
  CurseForge Compliant (Blizzard AddOn Policy Approved)
--]]

local ADDON_NAME, FG = ...
_G.ForeverGuide = FG

-- Data reference
FG.Data = ForeverGuide_Data or {}

-- Default Configuration
local DEFAULT_CONFIG = {
  sparkLocked = false,
  sparkScale = 1.0,
  combatFade = true,
  soundEnabled = true,
  showSpeechBubbles = true,
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
-- Slash Command Handler
--------------------------------------------------------------------------------
SLASH_FOREVERGUIDE1 = "/fg"
SLASH_FOREVERGUIDE2 = "/spark"
SLASH_FOREVERGUIDE3 = "/foreverguide"

SlashCmdList["FOREVERGUIDE"] = function(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = cmd:lower()

  if cmd == "" or cmd == "toggle" then
    FG:ToggleCodex()
  elseif cmd == "spark" then
    FG:ToggleSpark()
  elseif cmd == "lock" then
    ForeverGuideDB.sparkLocked = not ForeverGuideDB.sparkLocked
    local state = ForeverGuideDB.sparkLocked and "|cffff2020Locked|r" or "|cff20ff20Unlocked|r"
    print("|cff00bfff[Forever Guide]|r Blue Spark is now " .. state)
  elseif cmd == "zone" or cmd == "where" then
    FG:ShowCurrentZoneIntel()
  elseif cmd == "search" or cmd == "find" then
    FG:OpenCodexWithSearch(rest)
  elseif cmd == "reset" then
    ForeverGuideDB.sparkPosition = { point = "CENTER", relativePoint = "CENTER", x = 240, y = 60 }
    if FG.SparkFrame then
      FG.SparkFrame:ClearAllPoints()
      FG.SparkFrame:SetPoint("CENTER", UIParent, "CENTER", 240, 60)
    end
    print("|cff00bfff[Forever Guide]|r Blue Spark position reset to default.")
  else
    print("|cff00bfff[Forever Guide - The Blue Spark]|r Commands:")
    print("  |cff71d5ff/spark|r - Toggle Forever Codex window")
    print("  |cff71d5ff/spark zone|r - Show leveling intel for your current zone")
    print("  |cff71d5ff/spark find <query>|r - Search items, dungeons, and forever content")
    print("  |cff71d5ff/spark lock|r - Toggle spark frame position locking")
    print("  |cff71d5ff/spark reset|r - Reset spark position to screen center")
  end
end

--------------------------------------------------------------------------------
-- The Blue Spark Companion Frame
--------------------------------------------------------------------------------
function FG:CreateSparkFrame()
  local f = CreateFrame("Button", "ForeverGuideSparkFrame", UIParent)
  f:SetSize(52, 52)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")

  -- Position Restore
  local pos = ForeverGuideDB.sparkPosition or DEFAULT_CONFIG.sparkPosition
  f:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 240, pos.y or 60)
  f:SetScale(ForeverGuideDB.sparkScale or 1.0)

  -- Outer Pulsing Aura (Glow)
  local aura = f:CreateTexture(nil, "BACKGROUND")
  aura:SetTexture("Interface\\Cooldown\\star4")
  aura:SetPoint("CENTER", f, "CENTER", 0, 0)
  aura:SetSize(74, 74)
  aura:SetVertexColor(0.1, 0.7, 1.0, 0.75)
  f.Aura = aura

  -- Core Luminous Spark Sphere
  local core = f:CreateTexture(nil, "ARTWORK")
  core:SetTexture("Interface\\CHARACTERFRAME\\UI-Player-Status")
  core:SetTexCoord(0.15, 0.40, 0.15, 0.40)
  core:SetPoint("CENTER", f, "CENTER", 0, 0)
  core:SetSize(42, 42)
  core:SetVertexColor(0.5, 0.88, 1.0, 1.0)
  f.Core = core

  -- Celestial Sparkle Highlight
  local spark = f:CreateTexture(nil, "OVERLAY")
  spark:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
  spark:SetTexCoord(0.2, 0.8, 0.2, 0.8)
  spark:SetPoint("CENTER", f, "CENTER", 0, 0)
  spark:SetSize(36, 36)
  spark:SetVertexColor(0.8, 0.95, 1.0, 0.9)
  f.Spark = spark

  -- Breathing / Pulse Animation Group
  local ag = f:CreateAnimationGroup()
  local scaleAnim = ag:CreateAnimation("Scale")
  scaleAnim:SetScale(1.12, 1.12)
  scaleAnim:SetDuration(1.6)
  scaleAnim:SetSmoothing("IN_OUT")

  local alphaAnim = ag:CreateAnimation("Alpha")
  alphaAnim:SetFromAlpha(0.65)
  alphaAnim:SetToAlpha(1.0)
  alphaAnim:SetDuration(1.6)
  alphaAnim:SetSmoothing("IN_OUT")

  ag:SetLooping("BOUNCE")
  ag:Play()
  f.AnimGroup = ag

  -- Dragging Logic
  f:SetScript("OnDragStart", function(self)
    if not ForeverGuideDB.sparkLocked then
      self:StartMoving()
    end
  end)

  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrMoving()
    local point, _, relPoint, x, y = self:GetPoint()
    ForeverGuideDB.sparkPosition = {
      point = point,
      relativePoint = relPoint,
      x = math.floor(x + 0.5),
      y = math.floor(y + 0.5),
    }
  end)

  -- Click Handlers
  f:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
      FG:ToggleCodex()
      FG:PlaySparkSound("shimmer")
    elseif button == "RightButton" then
      FG:ShowCurrentZoneIntel()
      FG:PlaySparkSound("pulse")
    end
  end)

  -- Hover Tooltip
  f:SetScript("OnEnter", function(self)
    aura:SetVertexColor(0.3, 0.9, 1.0, 1.0)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cff00bfffThe Blue Spark|r", 1, 1, 1)
    GameTooltip:AddLine("Your celestial companion across Warcraft Forever.", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff71d5ff<Left-Click>|r Open Forever Codex & Search", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Right-Click>|r Consult Spark on Current Zone", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Drag>|r Move companion (" .. (ForeverGuideDB.sparkLocked and "|cffff2020Locked|r" or "|cff20ff20Unlocked|r") .. ")", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function(self)
    aura:SetVertexColor(0.1, 0.7, 1.0, 0.75)
    GameTooltip:Hide()
  end)

  FG.SparkFrame = f
end

function FG:ToggleSpark()
  if not FG.SparkFrame then return end
  if FG.SparkFrame:IsShown() then
    FG.SparkFrame:Hide()
    print("|cff00bfff[Forever Guide]|r Blue Spark companion dismissed.")
  else
    FG.SparkFrame:Show()
    FG:PlaySparkSound("shimmer")
    print("|cff00bfff[Forever Guide]|r Blue Spark summoned.")
  end
end

--------------------------------------------------------------------------------
-- Zone Wayfarer & Ambient Whisper Logic
--------------------------------------------------------------------------------
function FG:GetCurrentZone()
  local zone = GetRealZoneText()
  if not zone or zone == "" then
    zone = GetZoneText()
  end
  return zone or "Unknown"
end

function FG:GetZoneData(zoneName)
  if not FG.Data.Zones then return nil end
  for _, z in ipairs(FG.Data.Zones) do
    if z.name:lower() == zoneName:lower() then
      return z
    end
  end
  return nil
end

function FG:ShowCurrentZoneIntel()
  local currentZone = FG:GetCurrentZone()
  local zoneInfo = FG:GetZoneData(currentZone)
  local playerLevel = UnitLevel("player")
  local faction = UnitFactionGroup("player")

  print(" ")
  print("|cff00bfff✨ The Blue Spark whispers concerning:|r |cffffffff" .. currentZone .. "|r")

  if zoneInfo then
    local levelColor = "|cff20ff20"
    print("  |cff71d5ffLevel Range:|r " .. levelColor .. zoneInfo.level .. "|r  |cff71d5ffFaction:|r " .. zoneInfo.faction)
    print("  |cff71d5ffContinent:|r " .. zoneInfo.continent)
  else
    print("  |cff888888Sanctuary or Uncharted Territory.|r")
  end

  -- Dungeons in this zone
  local localDungeons = {}
  if FG.Data.Dungeons then
    for _, d in pairs(FG.Data.Dungeons) do
      if d.zone and d.zone:lower() == currentZone:lower() then
        table.insert(localDungeons, d)
      end
    end
  end

  if #localDungeons > 0 then
    print("  |cff00ff00Nearby Dungeons & Raids:|r")
    for _, d in ipairs(localDungeons) do
      local tag = d.isForever and " |cffe6cc80[Forever]|r" or ""
      print("    • |cffffd100" .. d.name .. "|r (Lvl " .. d.recLevel .. ")" .. tag)
      if d.coords and d.coords ~= "" then
        print("      Entrance Coords: |cff71d5ff" .. d.coords .. "|r")
      end
      if d.strategy and d.strategy ~= "" then
        print("      Tactical Note: |cffcccccc" .. d.strategy .. "|r")
      end
    end
  end

  -- Flightpaths in this zone
  local localFP = {}
  if FG.Data.Flightpaths then
    for _, fp in pairs(FG.Data.Flightpaths) do
      if fp.zone and fp.zone:lower() == currentZone:lower() then
        if fp.faction == "Neutral" or fp.faction == faction then
          table.insert(localFP, fp)
        end
      end
    end
  end

  if #localFP > 0 then
    print("  |cff00e5ffFlight Master / Aerial Outposts:|r")
    for _, fp in ipairs(localFP) do
      local coords = (fp.coords and fp.coords ~= "") and (" (" .. fp.coords .. ")") or ""
      print("    • " .. fp.name .. coords)
    end
  end
  print(" ")
end

--------------------------------------------------------------------------------
-- Forever Codex Search & UI Window
--------------------------------------------------------------------------------
function FG:CreateCodexWindow()
  local f = CreateFrame("Frame", "ForeverGuideCodexWindow", UIParent, "BackdropTemplate")
  f:SetSize(580, 500)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")

  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  f:SetBackdropColor(0.05, 0.08, 0.14, 0.95)

  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrMoving)

  -- Header Title
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -18)
  title:SetText("|cff00bfffForever Guide:|r |cff71d5ffThe Blue Spark Codex|r")

  -- Close Button
  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
  closeBtn:SetScript("OnClick", function() f:Hide() end)

  -- Search EditBox
  local searchBox = CreateFrame("EditBox", "ForeverGuideSearchBox", f, "InputBoxTemplate")
  searchBox:SetSize(340, 26)
  searchBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 6, -12)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject("ChatFontNormal")

  local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
  placeholder:SetText("Search items, dungeons, bosses, or forever content...")

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

  searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)

  -- Dungeons / Quick View Button
  local dungeonsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  dungeonsBtn:SetSize(90, 24)
  dungeonsBtn:SetPoint("LEFT", searchBox, "RIGHT", 12, 0)
  dungeonsBtn:SetText("Dungeons")
  dungeonsBtn:SetScript("OnClick", function()
    searchBox:SetText("")
    FG:PopulateDungeons()
  end)

  -- Forever Content Filter Button
  local foreverBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  foreverBtn:SetSize(80, 24)
  foreverBtn:SetPoint("LEFT", dungeonsBtn, "RIGHT", 6, 0)
  foreverBtn:SetText("Forever")
  foreverBtn:SetScript("OnClick", function()
    searchBox:SetText("forever")
  end)

  -- Scroll Frame Container
  local scrollFrame = CreateFrame("ScrollFrame", "ForeverGuideScrollFrame", f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -14)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 18)

  local content = CreateFrame("Frame", "ForeverGuideScrollContent", scrollFrame)
  content:SetSize(520, 1000)
  scrollFrame:SetScrollChild(content)
  f.Content = content

  f:Hide()
  FG.CodexWindow = f
end

function FG:PopulateCodexResults(query)
  if not FG.CodexWindow or not FG.CodexWindow.Content then return end
  local content = FG.CodexWindow.Content

  -- Clear previous children
  if content.Buttons then
    for _, btn in ipairs(content.Buttons) do
      btn:Hide()
    end
  end
  content.Buttons = content.Buttons or {}

  local q = query:lower():trim()
  local matches = {}

  if q == "" then
    -- Show top Forever content by default
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
          if #matches >= 60 then break end
        end
      end
    end

    -- Search Dungeons
    if FG.Data.Dungeons then
      for _, d in pairs(FG.Data.Dungeons) do
        if d.name and (d.name:lower():find(q, 1, true) or d.zone:lower():find(q, 1, true) or d.bosses:lower():find(q, 1, true)) then
          table.insert(matches, { type = "dungeon", data = d })
        end
      end
    end
  end

  local yOffset = -4
  for i, match in ipairs(matches) do
    local btn = content.Buttons[i]
    if not btn then
      btn = CreateFrame("Button", nil, content, "BackdropTemplate")
      btn:SetSize(514, 52)
      btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })
      btn:SetBackdropColor(0.1, 0.15, 0.22, 0.85)

      local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -8)
      btn.Title = titleText

      local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
      subText:SetWidth(490)
      subText:SetJustifyH("LEFT")
      btn.Sub = subText

      content.Buttons[i] = btn
    end

    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

    if match.type == "item" then
      local item = match.data
      local qColor = FG.QualityColors[item.quality] or "ffffffff"
      local foreverTag = item.isForever and " |cffe6cc80[Warcraft Forever]|r" or ""
      btn.Title:SetText("|c" .. qColor .. item.name .. "|r" .. foreverTag .. " |cff888888(iLvl " .. item.ilvl .. ")|r")

      local desc = (item.slot and item.slot ~= "" and (item.slot .. " • ") or "") .. (item.source or "World Drop")
      if item.tip and item.tip ~= "" then
        desc = desc .. " |cff71d5ffNote:|r " .. item.tip
      end
      btn.Sub:SetText(desc)

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.3, 0.45, 0.95)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetItemByID(item.id)
        if item.tip and item.tip ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("|cff00bfffSpark Intel:|r " .. item.tip, 0.2, 0.8, 1.0, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.15, 0.22, 0.85)
        GameTooltip:Hide()
      end)
      btn:SetScript("OnClick", function()
        if ChatEdit_InsertLink then
          local _, link = GetItemInfo(item.id)
          if link then
            ChatEdit_InsertLink(link)
          end
        end
      end)
    elseif match.type == "dungeon" then
      local d = match.data
      local foreverTag = d.isForever and " |cffe6cc80[Forever Raid/Dungeon]|r" or ""
      btn.Title:SetText("|cffffd100" .. d.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. d.recLevel .. ")|r")
      btn.Sub:SetText("|cff71d5ffZone:|r " .. d.zone .. " |cff71d5ffBosses:|r " .. (d.bosses or "Various"))

      btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.2, 0.4, 0.95)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(d.name, 1, 0.82, 0)
        GameTooltip:AddLine("Level: " .. d.recLevel .. " (" .. d.zone .. ")", 1, 1, 1)
        if d.coords and d.coords ~= "" then
          GameTooltip:AddLine("Entrance Coords: " .. d.coords, 0.2, 1, 0.2)
        end
        if d.strategy and d.strategy ~= "" then
          GameTooltip:AddLine(" ")
          GameTooltip:AddLine("Tactical Strategy:", 0, 0.7, 1)
          GameTooltip:AddLine(d.strategy, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.15, 0.22, 0.85)
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

  local yOffset = -4
  for i, d in ipairs(sorted) do
    local btn = content.Buttons[i]
    if not btn then
      btn = CreateFrame("Button", nil, content, "BackdropTemplate")
      btn:SetSize(514, 52)
      btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })
      btn:SetBackdropColor(0.1, 0.15, 0.22, 0.85)

      local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -8)
      btn.Title = titleText

      local subText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
      subText:SetWidth(490)
      subText:SetJustifyH("LEFT")
      btn.Sub = subText

      content.Buttons[i] = btn
    end

    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

    local foreverTag = d.isForever and " |cffe6cc80[Forever]|r" or ""
    btn.Title:SetText("|cffffd100" .. d.name .. "|r" .. foreverTag .. " |cff20ff20(Lvl " .. d.recLevel .. ")|r")
    btn.Sub:SetText("|cff71d5ffZone:|r " .. d.zone .. " |cff71d5ffEntrance:|r " .. (d.coords or "N/A"))

    btn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.2, 0.3, 0.45, 0.95)
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:AddLine(d.name, 1, 0.82, 0)
      GameTooltip:AddLine("Level: " .. d.recLevel .. " | Zone: " .. d.zone, 1, 1, 1)
      if d.coords and d.coords ~= "" then
        GameTooltip:AddLine("Coords: " .. d.coords, 0.2, 1, 0.2)
      end
      if d.strategy and d.strategy ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tactics: " .. d.strategy, 0.7, 0.8, 1, true)
      end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.1, 0.15, 0.22, 0.85)
      GameTooltip:Hide()
    end)

    btn:Show()
    yOffset = yOffset - 58
  end
  content:SetHeight(math.max(450, math.abs(yOffset) + 20))
end

function FG:ToggleCodex()
  if not FG.CodexWindow then
    FG:CreateCodexWindow()
  end
  if FG.CodexWindow:IsShown() then
    FG.CodexWindow:Hide()
  else
    FG.CodexWindow:Show()
    FG:PopulateCodexResults("")
    FG:PlaySparkSound("shimmer")
  end
end

function FG:OpenCodexWithSearch(query)
  if not FG.CodexWindow then
    FG:CreateCodexWindow()
  end
  FG.CodexWindow:Show()
  if ForeverGuideSearchBox then
    ForeverGuideSearchBox:SetText(query or "")
  end
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

  -- Background Circle
  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(25, 25)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("TOPLEFT", 2, -4)

  -- The Blue Spark Icon
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetTexture("Interface\\CHARACTERFRAME\\UI-Player-Status")
  icon:SetTexCoord(0.15, 0.40, 0.15, 0.40)
  icon:SetVertexColor(0.2, 0.85, 1.0, 1.0)
  icon:SetPoint("CENTER", 0, 0)
  btn.Icon = icon

  -- Minimap Tracking Border Overlay
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

  btn:SetScript("OnDragStart", function(self)
    self.isDragging = true
  end)

  btn:SetScript("OnDragStop", function(self)
    self.isDragging = false
  end)

  btn:SetScript("OnUpdate", function(self)
    if self.isDragging then
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cx, cy = cx / scale, cy / scale
      local angle = math.deg(math.atan2(cy - my, cx - mx))
      ForeverGuideDB.minimap.minimapPos = angle
      UpdatePosition(angle)
    end
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
    GameTooltip:AddLine("|cff00bfffForever Guide|r", 1, 1, 1)
    GameTooltip:AddLine("|cff71d5ff<Left-Click>|r Toggle Codex Window", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Right-Click>|r Toggle Blue Spark Companion", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("|cff71d5ff<Drag>|r Move around minimap", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  btn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  UpdatePosition(ForeverGuideDB.minimap.minimapPos or 215)
  FG.MinimapButton = btn
end

--------------------------------------------------------------------------------
-- Event Dispatcher
--------------------------------------------------------------------------------
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

EventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    ForeverGuideDB = ForeverGuideDB or {}
    for k, v in pairs(DEFAULT_CONFIG) do
      if ForeverGuideDB[k] == nil then
        ForeverGuideDB[k] = v
      end
    end

    FG:CreateSparkFrame()
    FG:CreateMinimapButton()

    print("|cff00bfffForever Guide (The Blue Spark)|r v1.0.0 loaded! Type |cff71d5ff/spark|r or click the spark to open.")

  elseif event == "ZONE_CHANGED_NEW_AREA" then
    if FG.SparkFrame and FG.SparkFrame:IsShown() then
      FG:PlaySparkSound("pulse")
      -- Ambient spark pulse flash
      if FG.SparkFrame.Aura then
        FG.SparkFrame.Aura:SetVertexColor(0.4, 0.9, 1.0, 1.0)
        C_Timer.After(1.2, function()
          if FG.SparkFrame and FG.SparkFrame.Aura then
            FG.SparkFrame.Aura:SetVertexColor(0.1, 0.7, 1.0, 0.75)
          end
        end)
      end
    end

  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Combat Auto-fade
    if ForeverGuideDB.combatFade and FG.SparkFrame then
      FG.SparkFrame:SetAlpha(0.15)
    end

  elseif event == "PLAYER_REGEN_ENABLED" then
    if ForeverGuideDB.combatFade and FG.SparkFrame then
      FG.SparkFrame:SetAlpha(1.0)
    end
  end
end)
