-- This AddOn counts the number of player kills since login and calculates kills per hour.
------------------------------------------------------------------------------------------
local playerKillStatsFrame = CreateFrame("Frame", "PlayerKillStatsFrame", UIParent)
local playerKillsText = playerKillStatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local killsPerHourText = playerKillStatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local startTimeText = playerKillStatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

local numKills = 0
local startTime = GetTime()


local function InitKillStatsFrames()
    playerKillStatsFrame:SetSize(128, 64)
    playerKillStatsFrame:SetPoint("CENTER")
    playerKillStatsFrame:EnableMouse(true)                                                -- Enable mouse interaction on the frame
    playerKillStatsFrame:SetMovable(true)                                                 -- Allow the frame to be moved
    playerKillStatsFrame:RegisterForDrag("LeftButton")                                    -- Allow the frame to be dragged with the left mouse button
    playerKillStatsFrame:SetScript("OnDragStart", playerKillStatsFrame.StartMoving)       -- Start moving the frame when dragging begins
    playerKillStatsFrame:SetScript("OnDragStop", playerKillStatsFrame.StopMovingOrSizing) -- Stop moving the frame when dragging stops
    playerKillStatsFrame:Show()

    playerKillsText:SetPoint("LEFT", 0, 0)
    playerKillsText:SetText("Honorable Kills: 0")

    killsPerHourText:SetPoint("LEFT", 0, -15)
    killsPerHourText:SetText("Kills per hour: 0")

    startTimeText:SetPoint("LEFT", 0, -30)
    startTimeText:SetText("Session Start: N/A") -- This will be updated when session starts
end


local function UpdateKillsPerHour()
    local currentTime = GetTime()
    local elapsedTime = currentTime - startTime
    local killsPerHour = math.floor(numKills / (elapsedTime / 3600))
    killsPerHourText:SetText("Kills per hour: " .. killsPerHour)
end


local function HandlePlayerEnteringWorldCommand(self)
    -- Reset the kill count when the player enters the world
    playerKillsText:SetText("Player Kills    : 0")
    numKills = 0
    startTime = GetTime()
    UpdateKillsPerHour()

    -- Start the timer to update the kills per hour value every second
    self:SetScript("OnUpdate", function(self, elapsed)
        UpdateKillsPerHour()
    end)

    local sessionStart = date("%H:%M")
    startTimeText:SetText("Session Start : " .. sessionStart)
end


local function HandleCombatLogEvent()
    local _, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags =
        CombatLogGetCurrentEventInfo()
    if combatEvent == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER and
            bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then
            numKills = numKills + 1
            playerKillsText:SetText("Player Kills    : " .. numKills)

            -- Announce the kill to group chat
            if EnableKillAnnounce then
                local killMessage = string.gsub(PlayerKillMessage, "Enemyplayername", destName)
                SendChatMessage(killMessage, "PARTY")
            end
        end
    end
end


local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        HandlePlayerEnteringWorldCommand(self)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLogEvent()
    end
end


local function RegisterEvents()
    playerKillStatsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillStatsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillStatsFrame:SetScript("OnEvent", OnEvent)
end


local function Main()
    RegisterEvents()
    InitKillStatsFrames()
end


Main()
