--[=====[
[[SND Metadata]]
author: baanderson40
version: 1.3.1
description: |
  Support via https://ko-fi.com/baanderson40
  Features:
  - Automatically jump if you get stuck while moving
  - Switch between jobs when EXP or class score goals are met (based on ICE settings)
  - Pause missions once the Lunar Credits limit is reached and spend them on Gamba
  - Optionally wait at random spot for a set time before moving
  - Automatically turn in research points for relic
plugin_dependencies:
- ICE
configs:
  Jump if stuck:
    description: Makes the character jump if it has been stuck in the same spot for too long.
    default: false
  Jobs:
    description: |
      A list of jobs to cycle through when EXP or class score thresholds are reached,
      depending on the settings configured in ICE.
      Enter short or full job name and press enter. One job per line.
      -- Enable equip job command in Simple Tweaks and leave it as the default. --
      Leave blank to disable job cycling.
    default: []
  Lunar Credits Limit:
    description: |
      Maximum number of Lunar Credits before missions will pause for Gamba.
      Match this with "Stop at Lunar Credits" in ICE to synchronize behavior.
      -- Enable Gamba under Gamble Wheel in ICE settings. --
      Set to 0 to disable the limit.
    default: 0
    min: 0
    max: 10000
  Report Failed Missions:
    description: |
      Enable to report missions that failed to reach scoreing tier.
    default: false
  EX+ 4hr Timed Missions:
    description: |
      Enable to swap crafting jobs to the current EX+ 4hr long timed mission job.
      ARM -> GSM -> LTW -> WVR -> CRP -> BSM -> repeat
    default: false
  EX+ 2hr Timed Missions:
    description: |
      Enable to swap crafting jobs to the current EX+ 2hr long timed mission job.
      LTW -> WVR -> ALC -> CUL -> ARM -> GSM -> repeat
    default: false
  Delay Moving Spots:
    description: |
      Number of minutes to remain at one spot before moving randomly to another.
      Use 0 to disable automatic spot movement.
    default: 0
    min: 0
    max: 1440
  Process Retainers Ventures:
    description: |
      Pause cosmic missions when retainers’ ventures are ready.
      -- Doesn't return to Sinus moon after leaving --
      Set to N/A to disable.
    default: "N/A"
    is_choice: true
    choices: ["N/A","Glassblowers' Beacon (Pharnna)", "Moongate Hub (Sinus)", "Inn", "Gridania", "Limsa Lominsa", "Ul'Dah"]
  Research Turnin:
    description: |
      Enable to automatically turn in research for relic.
    default: false
  Use Alt Job:
    description: |
      Enable to use WAR during turning in research for relic. 
      Doesn't work if the tool is saved to the gear set. 
    default: false
  Relic Jobs:
    description: |
      A list of jobs to cycle through when relic tool is completed.
      Don't include the starting/current job. Start the list with the next intended job. 
      Enter short or full job name and press enter. One job per line.
      -- Enable equip job command in Simple Tweaks and leave it as the default. --
      Leave blank to disable job cycling.
    default: []
[[End Metadata]]
--]=====]

--[[
********************************************************************************
*                                  Changelog                                   *
********************************************************************************
    -> 1.3.1 Adjustments for relic turn-in due to failed mission reporting
    -> 1.3.0 Released failed mission reporting
    -> 1.2.1 Fixed EX+ enabled automatically
    -> 1.2.0 Release job swapping support for EX+ timed missions for crafters
    -> 1.1.4 Added support for retainer processing off of the moon
    -> 1.1.3 Adjusted speed/timing for relic turn-in & added Alt job for turn-in
    -> 1.1.2 Updates related to relic turnin and retainer processing
    -> 1.1.1 Added additonal addon for relic excahnge and cycling research UI window
    -> 1.1.0 Added ability to turn in research for relic
    -> 1.0.8 Fixed meta data config settings
    -> 1.0.7 Fixed a typo for Moongate Hub in retainer processing
    -> 1.0.6 Added Retainer ventrues processing
    -> 1.0.5 Removed types from config settings
    -> 1.0.4 Improved Job cycling logic
    -> 1.0.3 Added random locations to move between with delay timer
    -> 1.0.2 Improved stuck detection
    -> 1.0.1 Added Gamba support
    -> 1.0.0 Initial Release
]]

-- Imports
import("System.Numerics") -- leave this alone....

--[[
********************************************************************************
*                            Advance User Settings                             *
********************************************************************************
]]


loopDelay  =  1           -- Controls how fast the script runs; lower = faster, higher = slower (in seconds per loop)
cycleLoops = 100          -- How many loop iterations to run before cycling to the next job
moveOffSet = 5            -- Adds a random offset to spot movement time, up to ±5 minutes.
spotRadius = 3            -- Defines the movement radius; the player will move within this distance when selecting a new spot

if Svc.ClientState.TerritoryType == 1237 then -- Sinus 
    SpotPos = {
        Vector3(9.521,1.705,14.300),            -- Summoning bell
        Vector3(8.870, 1.642, -13.272),         -- Cosmic Fortunes
        Vector3(-9.551, 1.705, -13.721),        -- Starward Standings
        Vector3(-12.039, 1.612, 16.360),        -- Cosmic Research
        Vector3(7.002, 1.674, -7.293),          -- Cosmic Fortunes inside loop
        Vector3(5.471, 1.660, 5.257),           -- Inside loop Summoning bell
        Vector3(-6.257, 1.660, 6.100),          -- Inside loop Cosmic Research
        Vector3(-5.919, 1.660, -5.678),         -- Inside loop Starward Standings
}
elseif Svc.ClientState.TerritoryType == 1291 then --Phaenna
    SpotPos = {
        Vector3(355.522, 52.625, -409.623), -- Summoning bell
        Vector3(353.649, 52.625, -403.039), -- Credit Exchange
        Vector3(356.086, 52.625, -434.961), -- Cosmic Fortunes
        Vector3(330.380, 52.625, -436.684), -- Starward Standings
        Vector3(319.037, 52.625, -417.655), -- Mech Ops
    }
end


--[[
********************************************************************************
*                       Don't touch anything below here                        *
********************************************************************************
]]

-- Config veriables
JumpConfig      = Config.Get("Jump if stuck")
JobsConfig      = Config.Get("Jobs")
LimitConfig     = Config.Get("Lunar Credits Limit")
FailedConfig    = Config.Get("Report Failed Missions")
Ex4TimeConfig   = Config.Get("EX+ 4hr Timed Missions")
Ex2TimeConfig   = Config.Get("EX+ 2hr Timed Missions")
MoveConfig      = Config.Get("Delay Moving Spots")
RetainerConfig  = Config.Get("Process Retainers Ventures")
ResearchConfig  = Config.Get("Research Turnin")
AltJobConfig    = Config.Get("Use Alt Job")
RelicJobsConfig = Config.Get("Relic Jobs")

-- Veriables
Run_script        = true
lastPos           = nil
totalJobs         = JobsConfig.Count
totalRelicJobs    = RelicJobsConfig.Count
reportCount       = 0
cycleCount        = 0
jobCount          = 0
lunarCredits      = 0
lunarCycleCount   = 0
lastSpotIndex     = nil
lastMoveTime      = nil
offSet            = nil
minRadius         = .5
SelectedBell      = nil
ClassScoreAll     = {}

 CharacterCondition = {
    normalConditions                   = 1, -- moving or standing still
    mounted                            = 4, -- moving
    crafting                           = 5,
    gathering                          = 6,
    casting                            = 27,
    occupiedInQuestEvent               = 32,
    occupied33                         = 33,
    occupiedMateriaExtractionAndRepair = 39,
    executingCraftingAction            = 40,
    preparingToCraft                   = 41,
    executingGatheringAction           = 42,
    betweenAreas                       = 45,
    jumping48                          = 48, -- moving
    occupiedSummoningBell              = 50,
    mounting57                         = 57, -- moving
    unknown85                          = 85, -- Part of gathering
}

--Position Information
SinusGateHub = Vector3(0,0,0)
PhaennaGateHub = Vector3(340.721, 52.864, -418.183)

SummoningBell = {
    {zone = "Inn", aethernet = "Inn", position = nil},
    {zone = "Glassblowers' Beacon (Pharnna)", aethernet = nil, position = Vector3(358.380, 52.625, -409.429)},
    {zone = "Moongate Hub (Sinus)", aethernet = nil, position = Vector3(9.870, 1.685, 14.865)},
    {zone = "Gridania", aethernet = "Leatherworkers' guild", position = Vector3(171.008, 15.488, -101.488)},
    {zone = "Limsa Lominsa", aethernet = "Limsa Lominsa", position = Vector3(-123.888, 17.990, 21.469)},
    {zone = "Ul'Dah", aethernet = "Sapphire Avenue Exchange", position = Vector3(148.913, 3.983, -44.205)},
}

if RetainerConfig ~= "N/A" then
    for _, bell in ipairs(SummoningBell) do
        if bell.zone == RetainerConfig then
            SelectedBell = bell
            break
        end
    end
end

--TerritoryType
SinusTerritory = 1237
PhaennaTerritory = 1291

--NPC information
SinusCreditNpc = {name = "Orbitingway", position = Vector3(18.845, 2.243, -18.906)}
SinusResearchNpc = {name = "Researchingway", position = Vector3(-18.906, 2.151, 18.845)}
PhaennaCreditNpc = {name = "Orbitingway", position = Vector3(358.816, 53.193, -438.865)}
PhaennaResearchNpc = {name = "Researchingway", position = Vector3(321.218, 53.193, -401.236)}

--Timed mission jobs
exJobs4H = {
  [0]  = {"ARM"},   -- 00:00–03:59
  [4]  = {"GSM"},   -- 04:00–07:59
  [8]  = {"LTW"},   -- 08:00–11:59
  [12] = {"WVR"},   -- 12:00–15:59
  [16] = {"CRP"},   -- 16:00–19:59
  [20] = {"BSM"},   -- 20:00–23:59
}

exJobs2H = {
  [0]  = {"LTW"},   --00:00-02:59
  [4]  = {"WVR"},   --04:00-05:59
  [8]  = {"ALC"},   --08:00-09:59
  [12] = {"CUL"},   --12:00-13:59
  [16] = {"ARM"},   --16:00-17:59
  [20] = {"GSM"},   --20:00-21:59
}

function GetCharacterCondition(cond)
    return Svc.Condition[cond]
end

ALL_INVENTORIES = {
    InventoryType.Inventory1,
    InventoryType.Inventory2,
    InventoryType.Inventory3,
    InventoryType.Inventory4,
}

function is_busy()
    return Player.IsBusy or GetCharacterCondition(6) or GetCharacterCondition(26) or GetCharacterCondition(27) or
        GetCharacterCondition(45) or GetCharacterCondition(51) or GetCharacterCondition(32) or
        not (GetCharacterCondition(1) or GetCharacterCondition(4)) or
        (not IPC.vnavmesh.IsReady()) or IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()
end

ice_started = false

function set_ice(state)
    if state then
        yield("/ice start")
        ice_started = true
    else
        yield("/ice stop")
        ice_started = false
    end
end

function wait(duration)
    yield('/wait ' .. string.format("%.1f", duration))
end

function default(value, default_value)
    if value == nil then return default_value end
    return value
end

function wait_ready(max_wait, n_ready, stationary)
    stationary = default(stationary, true)
    n_ready = default(n_ready, 5)
    local ready_count = 0
    local p = Entity.Player.Position
    repeat
        wait(1)
        if is_busy() or (stationary and Vector3.Distance(p, Entity.Player.Position) > 1) then
            p = Entity.Player.Position
            ready_count = 0
        else
            ready_count = ready_count + 1
        end
    until ready_count >= n_ready
end

function StopScript(message, caller, ...)
    luanet.error(logify(message, ...))
end

function logify(first, ...)
    local rest = table.pack(...)
    local message = tostring(first)
    for i = 1, rest.n do
        message = message .. ' ' .. tostring(rest[i])
    end
    return message
end

function log(...)
    Svc.Chat:Print(logify(...))
end

function put_cosmic_tools()
    local min_tool = 49009
    local max_tool = 49063
    for _, source in ipairs(ALL_INVENTORIES) do
        local sourceinv = Inventory.GetInventoryContainer(source)
        if sourceinv == nil then
            StopScript("No inventory", source)
        else
            for item in luanet.each(sourceinv.Items) do
                if min_tool <= item.ItemId and item.ItemId <= max_tool then
                    log("Moving", item.ItemId)
                    item:MoveItemSlot(InventoryType.ArmoryMainHand)
                    wait(0)
                end
            end
        end
    end
end

function CallerName(string)
    string = default(string, true)
    return debug_info_tostring(debug.getinfo(3), string)
end

function debug_info_tostring(debuginfo, always_string)
    string = default(string, true)
    local caller = debuginfo.name
    if caller == nil and not always_string then
        return nil
    end
    local file = debuginfo.short_src:gsub('.*\\', '') .. ":" .. debuginfo.currentline
    return tostring(caller) .. "(" .. file .. ")"
end

function luminia_row_checked(table, id)
    local sheet = Excel.GetSheet(table)
    if sheet == nil then
        StopScript("Unknown sheet", CallerName(false), "sheet not found for", table)
    end
    local row = sheet:GetRow(id)
    if row == nil then
        StopScript("Unknown id", CallerName(false), "Id not found in excel data", table, id)
    end
    return row
end

function equip_classjob(classjob_abrev, update_after)
    log("Equiping:", classjob_abrev)
    update_after = default(update_after, false)
    classjob_abrev = classjob_abrev:upper()
    for gs in luanet.each(Player.Gearsets) do
        if luminia_row_checked("ClassJob", gs.ClassJob).Abbreviation == classjob_abrev then
            gearset_name = gs.Name
            repeat
                put_cosmic_tools()
                gs:Equip()
                wait_ready(10, 1)
            until Player.Gearset.Name == gearset_name
            log("Equiped:", classjob_abrev, "with", gs.Name)
            if update_after then
                Player.Gearset:Update()
            end
            return true
        end
    end
    log("No gearset for:", classjob_abrev)
    return false
end

--Helper Funcitons
function sleep(seconds)
    yield('/wait ' .. tostring(seconds))
end

function IsAddonReady(name)
    local a = Addons.GetAddon(name)
    return a and a.Ready
end

function IsAddonExists(name)
    local a = Addons.GetAddon(name)
    return a and a.Exists
end

function DistanceBetweenPositions(pos1, pos2)
  local distance = Vector3.Distance(pos1, pos2)
  return distance
end

function HasPlugin(name)
    for plugin in luanet.each(Svc.PluginInterface.InstalledPlugins) do
        if plugin.InternalName == name and plugin.IsLoaded then
            return true
        end
    end
    return false
end

local function JumpReset()
  lastPos, jumpCount = nil, 0
end

function GetRandomSpotAround(radius, minDist)
    minDist = minDist or 0
    if #SpotPos == 0 then return nil end
    if #SpotPos == 1 then
        lastSpotIndex = 1
        return SpotPos[1]
    end
    local spotIndex
    repeat
        spotIndex = math.random(1, #SpotPos)
    until spotIndex ~= lastSpotIndex
    lastSpotIndex = spotIndex
    local center = SpotPos[spotIndex]
    local u = math.random()
    local distance = math.sqrt(u) * (radius - minDist) + minDist
    local angle = math.random() * 2 * math.pi
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance
    return Vector3(center.X + offsetX, center.Y, center.Z + offsetZ)
end

function RetrieveClassScore()
    classScoreAll = {}
    if not IsAddonExists("WKSScoreList") then
        yield("/callback WKSHud true 18")
        sleep(.5)
    end
    local scoreAddon = Addons.GetAddon("WKSScoreList")
    local dohRows = {2, 21001, 21002, 21003, 21004, 21005, 21006, 21007}
    for _, dohRows in ipairs(dohRows) do
        local nameNode  = scoreAddon:GetNode(1, 2, 7, dohRows, 4)
        local scoreNode = scoreAddon:GetNode(1, 2, 7, dohRows, 5)
        if nameNode and scoreNode then
            table.insert(classScoreAll, {
                className  = string.lower(nameNode.Text),
                classScore = scoreNode.Text
            })
        end
    end
    local dolRows = {2, 21001, 21002}
    for _, dolRows in ipairs(dolRows) do
        local nameNode  = scoreAddon:GetNode(1, 8, 13, dolRows, 4)
        local scoreNode = scoreAddon:GetNode(1, 8, 13, dolRows, 5)
        if nameNode and scoreNode then
            table.insert(classScoreAll, {
                className  = string.lower(nameNode.Text),
                classScore = scoreNode.Text
            })
        end
    end
    for i, entry in ipairs(classScoreAll) do
        if Player.Job.Name == entry.className then
            currentScore = entry.classScore
            break
        end
    end
    return currentScore
end

function toNumber(s)
    if type(s) ~= "string" then return tonumber(s) end
    s = s:match("^%s*(.-)%s*$")
    s = s:gsub(",", "")
    return tonumber(s)
end

function RetrieveRelicResearch()
    if IsAddonExists("WKSToolCustomize") then
        repeat
            yield("/callback WKSToolCustomize true -1")
            sleep(.5)
        until not IsAddonReady("WKSToolCustomize")
        sleep(.5)
    end
    if Svc.Condition[CharacterCondition.crafting]
       or Svc.Condition[CharacterCondition.gathering]
       or IsAddonExists("WKSMissionInfomation") then
        return 0
    end
    yield("/callback WKSHud true 15")
    repeat
        sleep(.1)
    until IsAddonReady("WKSToolCustomize")
    local res = inner_RetrieveRelicResearch()
    if IsAddonExists("WKSToolCustomize") then
        repeat
            yield("/callback WKSToolCustomize true -1")
            sleep(.5)
        until not IsAddonReady("WKSToolCustomize")
    end
    log("Relic Research:", res)
    return res
end

function inner_RetrieveRelicResearch()
    local ToolAddon = Addons.GetAddon("WKSToolCustomize")
    local rows = {4, 41001, 41002, 41003, 41004, 41005, 41006, 41007}
    local checked = 0
    for _, row in ipairs(rows) do
        local currentNode = ToolAddon:GetNode(1, 55, 68, row, 4, 5)
        local requiredNode = ToolAddon:GetNode(1, 55, 68, row, 4, 7)
        if not currentNode or not requiredNode then break end
        local current  = toNumber(currentNode.Text)
        local required = toNumber(requiredNode.Text)
        if current == nil or required == nil then break end
        if required == 0 then return 1 end --Relic complete
        if current < required then return 0 end --Phase not done
        checked = checked + 1
    end
    return (checked > 0) and 2 or 0  -- 2 = phase complete
end

function getEorzeaHour()
  local et = os.time() * 1440 / 70
  return math.floor((et % 86400) / 3600)
end

function currentexJobs4H()
    local h = getEorzeaHour()
    local slot = math.floor(h / 4) * 4
    local jobs = exJobs4H[slot]
    return jobs and jobs[1] or nil
end

function currentexJobs2H()
    local h = getEorzeaHour()
    local slot = math.floor(h / 2) * 2
    local jobs = exJobs2H[slot]
    return jobs and jobs[1] or nil
end

--Worker Funcitons
function ShouldJump()
  if not Player.IsMoving then JumpReset(); return end
  local pos = Svc.ClientState.LocalPlayer.Position
  if not lastPos then lastPos = pos; jumpCount = 0; return end
  if DistanceBetweenPositions(pos, lastPos) >= 4 then
    JumpReset(); return
  end
  jumpCount = (jumpCount or 0) + 1
  if jumpCount >= 5 then
    yield("/gaction jump")
    Dalamud.Log("[Cosmic Helper] Position hasn't changed; jumping")
    JumpReset()
  end
end

function ShouldRelic()
    local research = RetrieveRelicResearch()
    if research == 0 then
        if not ice_started then
            Dalamud.Log("[Cosmic Helper] Starting ICE")
            set_ice(true)
            sleep(2)
            set_ice(true)
        end
        return
    elseif research == 1 then
        jobCount = jobCount + 1
        if jobCount == totalRelicJobs then
            Dalamud.Log("[Cosmic Helper] End of job list reached. Exiting script.")
            yield("/echo [Cosmic Helper] End of job list reached. Exiting script.")
            Run_script = false
            return
        end
        Dalamud.Log("[Cosmic Helper] Swapping to -> " .. RelicJobsConfig[jobCount])
        yield("/echo [Cosmic Helper] Swapping to -> " .. RelicJobsConfig[jobCount])
        local waitcount = 0
        while IsAddonReady("WKSMissionInfomation") do
            sleep(.1)
            waitcount = waitcount + 1
            if waitcount % 50 == 1 then
                Dalamud.Log("[Cosmic Helper] Waiting for mission to swap")
            end
        end
        set_ice(false)
        equip_classjob(RelicJobsConfig[jobCount])
        return
    elseif research == 2 then
        if not IPC.TextAdvance.IsEnabled() then
            yield("/at enable")
            EnabledAutoText = true
        end
        Dalamud.Log("[Cosmic Helper] Research level met!")
        yield("/echo [Cosmic Helper] Research level met!")
        local waitcount = 0
        while IsAddonReady("WKSMissionInfomation") do
            sleep(.1)
            waitcount = waitcount + 1
            Dalamud.Log("[Cosmic Helper] Waiting for mission to move")
            if waitcount >= 20 then
                yield("/echo [Cosmic Helper] Waiting for mission to move.")
                waitcount = 0
            end
        end
        Dalamud.Log("[Cosmic Helper] Stopping ICE")
        set_ice(false)
        curPos = Svc.ClientState.LocalPlayer.Position
        if Svc.ClientState.TerritoryType == SinusTerritory then
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            IPC.vnavmesh.PathfindAndMoveTo(SinusResearchNpc.position, false)
            Dalamud.Log("[Cosmic Helper] Moving to Research bunny")
            sleep(1)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, SinusResearchNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] Near Research bunny. Stopping vnavmesh.")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            IPC.vnavmesh.PathfindAndMoveTo(PhaennaResearchNpc.position, false)
            Dalamud.Log("[Cosmic Helper] Moving to Research bunny")
            sleep(1)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, PhaennaResearchNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] Near Research bunny. Stopping vnavmesh.")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        end
        CurJob = Player.Job
        sleep(.1)
        if AltJobConfig then equip_classjob("war") end
        local e = Entity.GetEntityByName(SinusResearchNpc.name)
        if e then
            Dalamud.Log("[Cosmic Helper] Targetting: " .. SinusResearchNpc.name)
            e:SetAsTarget()
            e:Interact()
        end
        while not IsAddonReady("SelectString") do
            sleep(.1)
        end
        yield("/callback SelectString true 0")
        while not IsAddonReady("SelectIconString") do
            sleep(.1)
        end
        StringId = CurJob.Id - 8
        yield("/callback SelectIconString true " .. StringId)
        while not IsAddonReady("SelectYesno") do
            sleep(.1)
        end
        yield("/callback SelectYesno true 0")
        while IsAddonReady("SelectYesno") do
            sleep(.1)
        end
        if AltJobConfig then equip_classjob(CurJob.Abbreviation, true) end
        if CurJob.IsCrafter then
            aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
            IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
            Dalamud.Log("[Cosmic Helper] Moving to random spot " .. tostring(aroundSpot))
            lastMoveTime = os.time()
            sleep(2)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                    Dalamud.Log("[Cosmic Helper] Near random spot. Stopping vnavmesh")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        end
        if EnabledAutoText then
            yield("/at disable")
            EnabledAutoText = false
        end
    end
end

function ShouldRetainer()
    if IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() then
        local waitcount = 0
        while IsAddonExists("WKSMissionInfomation") do
            sleep(.2)
            waitcount = waitcount + 1
            Dalamud.Log("[Cosmic Helper] Waiting for mission to process retainers")
            if waitcount >= 15 then
                yield("/echo [Cosmic Helper] Waiting for mission to process retainers")
                waitcount = 0
            end
        end
        Dalamud.Log("[Cosmic Helper] Stopping ICE")
        set_ice(false)
        if SelectedBell.zone == "Moongate Hub (Sinus)" then
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
        elseif SelectedBell.zone == "Glassblowers' Beacon (Pharnna)" then
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
        else
            IPC.Lifestream.ExecuteCommand(SelectedBell.aethernet)
            Dalamud.Log("[Cosmic Helper] Moving to " .. tostring(SelectedBell.aethernet))
            sleep(2)
        end
        while Svc.Condition[CharacterCondition.betweenAreas]
            or Svc.Condition[CharacterCondition.casting]
            or Svc.Condition[CharacterCondition.betweenAreasForDuty]
            or IPC.Lifestream.IsBusy() do
            sleep(.5)
        end
        sleep(2)
        if SelectedBell.position ~= nil then
            IPC.vnavmesh.PathfindAndMoveTo(SelectedBell.position, false)
            Dalamud.Log("[Cosmic Helper] Moving to summoning bell")
            sleep(2)
        end
        while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, SelectedBell.position) < 3 then
                Dalamud.Log("[Cosmic Helper] Close enough to summoning bell")
                IPC.vnavmesh.Stop()
                break
            end
        end
        while Svc.Targets.Target == nil or Svc.Targets.Target.Name:GetText() ~= "Summoning Bell" do
            Dalamud.Log("[Cosmic Helper] Targeting summoning bell")
            yield("/target Summoning Bell")
            sleep(1)
        end
        if not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            Dalamud.Log("[Cosmic Helper] Interacting with summoning bell")
            while not IsAddonReady("RetainerList") do
                yield("/interact")
                sleep(1)
            end
            if IsAddonReady("RetainerList") then
                Dalamud.Log("[Cosmic Helper] Enable AutoRetainer")
                yield("/ays e")
                sleep(1)
            end
        end
        while IPC.AutoRetainer.IsBusy() do
            sleep(1)
        end
        sleep(2)
        if IsAddonExists("RetainerList") then
            Dalamud.Log("[Cosmic Helper] Closing RetainerList window")
            yield("/callback RetainerList true -1")
            sleep(1)
        end
        if Svc.ClientState.TerritoryType == SinusTerritory then
            aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
            IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
            Dalamud.Log("[Cosmic Helper] Moving to random spot " .. tostring(aroundSpot))
            sleep(1)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                    Dalamud.Log("[Cosmic Helper] Near random spot. Stopping vnavmesh")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
            Dalamud.Log("[Cosmic Helper] Start ICE")
            set_ice(true)
            sleep(2)
            set_ice(true)
            return
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then
            aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
            IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
            Dalamud.Log("[Cosmic Helper] Moving to random spot " .. tostring(aroundSpot))
            sleep(1)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                    Dalamud.Log("[Cosmic Helper] Near random spot. Stopping vnavmesh")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
            Dalamud.Log("[Cosmic Helper] Start ICE")
            set_ice(true)
            sleep(2)
            set_ice(true)
            return
        else
            Dalamud.Log("[Cosmic Helper] Teleport to Cosmic")
            yield("/li Cosmic")
            sleep(3)
        end
        local cosmicCount = 0
        while not Svc.ClientState.TerritoryType ~= SinusTerritory
            and Svc.ClientState.TerritoryType ~= PhaennaTerritory do
            if not IPC.Lifestream.IsBusy() then
                    cosmicCount = cosmicCount + 1
                    if cosmicCount >=  20 then
                        Dalamud.Log("[Cosmic Helper] Failed to teleport to Cosmic. Trying agian.")
                        yield("/echo [Cosmic Helper] Failed to teleport to Cosmic. Trying agian.")
                        yield("/li Cosmic")
                        cosmicCount = 0
                    end
            else
                cosmicCount = 0
            end
            sleep(.5)
        end
        if Svc.ClientState.TerritoryType == SinusTerritory
            or Svc.ClientState.TerritoryType == PhaennaTerritory then
            while Svc.Condition[CharacterCondition.betweenAreas]
               or Svc.Condition[CharacterCondition.casting]
               or Svc.Condition[CharacterCondition.occupied33] do
                sleep(.5)
            end
            Dalamud.Log("[Cosmic Helper] Stellar Return")
            yield('/gaction "Duty Action"')
            sleep(5)
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            Dalamud.Log("[Cosmic Helper] Start ICE")
            set_ice(true)
            sleep(2)
            set_ice(true)
        end
    end
end

function ShouldCredit()
    if lunarCredits >= LimitConfig and Svc.Condition[CharacterCondition.normalConditions] and not Player.IsBusy then
        if not IPC.TextAdvance.IsEnabled() then
            yield("/at enable")
            EnabledAutoText = true
        end
        Dalamud.Log("[Cosmic Helper] Lunar credits: " .. tostring(lunarCredits) .. "/" .. LimitConfig .. " Going to Gamba!")
        yield("/echo Lunar credits: " .. tostring(lunarCredits) .. "/" .. LimitConfig .. " Going to Gamba!")
        curPos = Svc.ClientState.LocalPlayer.Position
        if Svc.ClientState.TerritoryType == SinusTerritory then
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            IPC.vnavmesh.PathfindAndMoveTo(SinusCreditNpc.position, false)
            Dalamud.Log("[Cosmic Helper] Moving to Gamba bunny")
            sleep(1)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, SinusCreditNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] Near Gamba bunny. Stopping vnavmesh.")
                    IPC.vnavmesh.Stop()
                end
            end
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            IPC.vnavmesh.PathfindAndMoveTo(PhaennaCreditNpc.position, false)
            Dalamud.Log("[Cosmic Helper] Moving to Gamba bunny")
            sleep(1)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, PhaennaCreditNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] Near Gamba bunny. Stopping vnavmesh.")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        end
        local e = Entity.GetEntityByName(SinusCreditNpc.name)
        if e then
            Dalamud.Log("[Cosmic Helper] Targetting: " .. SinusCreditNpc.name)
            e:SetAsTarget()
        end
        if Entity.Target and Entity.Target.Name == SinusCreditNpc.name then
            Dalamud.Log("[Cosmic Helper] Interacting: " .. SinusCreditNpc.name)
            Entity.Target:Interact()
            sleep(1)
        end
        while not IsAddonReady("SelectString") do
            sleep(1)
        end
        if IsAddonReady("SelectString") then
            yield("/callback SelectString true 0")
            sleep(1)
        end
        while not IsAddonReady("SelectString") do
            sleep(1)
        end
        if IsAddonReady("SelectString") then
            yield("/callback SelectString true 0")
            sleep(1)
        end
        while Svc.Condition[CharacterCondition.occupiedInQuestEvent] do
            sleep(1)
            Dalamud.Log("[Cosmic Helper] Waiting for Gamba to finish")
        end
        if not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
            job = Player.Job
            if job.IsCrafter then
                aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
                IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
                Dalamud.Log("[Cosmic Helper] Moving to random spot " .. tostring(aroundSpot))
                lastMoveTime = os.time()
                sleep(1)
            end
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                    Dalamud.Log("[Cosmic Helper] Near random spot. Stopping vnavmesh")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
            if EnabledAutoText then
                yield("/at disable")
                EnabledAutoText = false
            end
            Dalamud.Log("[Cosmic Helper] Starting ICE")
            set_ice(true)
            sleep(2)
            set_ice(true)
        end
    end
end

wasntCrafting = 0

function ShouldReport()
    curJob = Player.Job
    if IsAddonExists("WKSMissionInfomation") and curJob.IsCrafter then
        wasntCrafting = 0
        if IsAddonExists("WKSRecipeNotebook") and Svc.Condition[CharacterCondition.normalConditions] and not IsAddonExists("Materialize") then
            reportCount = reportCount + 1
            if reportCount >= 10 then
                while IsAddonExists("WKSRecipeNotebook") and Svc.Condition[CharacterCondition.normalConditions] do
                    set_ice(false)
                    yield("/callback WKSMissionInfomation true 11")
                    Dalamud.Log("[Cosmic Helper] Reporting failed mission.")
                    yield("/echo [Cosmic Helper] Reporting failed mission.")
                end
                reportCount = 0
            end
        else
            reportCount = 0
        end
    else
        wasntCrafting = wasntCrafting + 1
        reportCount = 0
    end
    if wasntCrafting >= 10 and wasntCrafting%10 == 0 then
        set_ice(false)
        sleep(2)
        set_ice(true)
    end
end

function ShouldExTime()
    CurJob = Player.Job.Abbreviation
    if Ex4TimeConfig then
        Cur4ExJob = currentexJobs4H()
        if Cur4ExJob and CurJob ~= Cur4ExJob then
            local waitcount = 0
            while IsAddonExists("WKSMissionInfomation") do
                sleep(.1)
                waitcount = waitcount + 1
                if waitcount >= 10 then
                    Dalamud.Log("[Cosmic Helper] Waiting for mission to end to swap to EX+ job.")
                    yield("/echo [Cosmic Helper] Waiting for mission to end to swap to EX+ job.")
                    waitcount = 0
                    ShouldReport()
                end
            end
            Dalamud.Log("[Cosmic Helper] Stopping ICE")
            set_ice(false)
            sleep(1)
            yield("/echo Current EX+ time: " .. getEorzeaHour() .. " swapping to " .. Cur4ExJob)
            equip_classjob(Cur4ExJob)
            sleep(1)
            set_ice(true)
            Dalamud.Log("[Cosmic Helper] Starting ICE")
        end
    elseif Ex2TimeConfig then
        Cur2ExJob = currentexJobs2H()
        if Cur2ExJob and CurJob ~= Cur2ExJob then
            local waitcount = 0
            while IsAddonExists("WKSMissionInfomation") do
                sleep(.1)
                waitcount = waitcount + 1
                if waitcount >= 50 then
                    Dalamud.Log("[Cosmic Helper] Waiting for mission to end to swap to EX+ job.")
                    yield("/echo [Cosmic Helper] Waiting for mission to end to swap to EX+ job.")
                    waitcount = 0
                end
            end
            Dalamud.Log("[Cosmic Helper] Stopping ICE")
            set_ice(false)
            sleep(1)
            yield("/echo Current EX+ time: " .. getEorzeaHour() .. " swapping to " .. Cur2ExJob)
            equip_classjob(Cur2ExJob)
            sleep(1)
            set_ice(true)
            Dalamud.Log("[Cosmic Helper] Starting ICE")
        end
    end
end

function ShouldMove()
    if LimitConfig > 0 and lunarCredits >= LimitConfig then
        return
    end
    if lastMoveTime == nil then
        lastMoveTime = os.time()
        return
    end
    if offSet == nil then
        offSet = math.random(-moveOffSet, moveOffSet)
    end
    local interval = math.max(1, MoveConfig + offSet)
    if os.time() - lastMoveTime >= interval * 60 then
        local waitcount = 0
        while IsAddonExists("WKSMissionInfomation") do
            sleep(.1)
            waitcount = waitcount + 1
            Dalamud.Log("[Cosmic Helper] Waiting for mission to move")
            if waitcount >= 10 then
                yield("/echo [Cosmic Helper] Waiting for mission to move.")
                waitcount = 0
            end
        end
        Dalamud.Log("[Cosmic Helper] Stopping ICE")
        set_ice(false)
        curPos = Svc.ClientState.LocalPlayer.Position
        if Svc.ClientState.TerritoryType == SinusTerritory then
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] Stellar Return")
                yield('/gaction "Duty Action"')
                sleep(5)
            end
        end
        while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
            sleep(.5)
        end
        aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
        IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
        Dalamud.Log("[Cosmic Helper] Moving to random spot " .. tostring(aroundSpot))
        sleep(1)
        while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
            sleep(.2)
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                Dalamud.Log("[Cosmic Helper] Near random spot. Stopping vnavmesh")
                IPC.vnavmesh.Stop()
                break
            end
        end
        set_ice(true)
        Dalamud.Log("[Cosmic Helper] Starting ICE")
        lastMoveTime = os.time()
        offSet = nil
    end
end

function ShouldCycle()
    if LimitConfig > 0 and lunarCredits >= LimitConfig then
        return
    end
    if Svc.Condition[CharacterCondition.normalConditions] then
        if (IsAddonExists("WKSMission")
        or IsAddonExists("WKSMissionInfomation")
        or IsAddonExists("WKSReward")
        or Player.IsBusy) then
            cycleCount = 0
            return
        else
            cycleCount = cycleCount + 1
            Dalamud.Log("[Cosmic Helper] Job Cycle ticks: " .. cycleCount)
        end
    end
    if cycleCount > 0 and cycleCount % 20 == 0 then
            yield("/echo [Cosmic Helper] Job Cycle ticks: " .. cycleCount .. "/" .. cycleLoops)
    end
    if cycleCount >= cycleLoops then
        if jobCount == totalJobs then
            Dalamud.Log("[Cosmic Helper] End of job list reached. Exiting script.")
            yield("/echo [Cosmic Helper] End of job list reached. Exiting script.")
            Run_script = false
            return
        end
        Dalamud.Log("[Cosmic Helper] Swapping to -> " .. JobsConfig[jobCount])
        yield("/echo [Cosmic Helper] Swapping to -> " .. JobsConfig[jobCount])
        equip_classjob(JobsConfig[jobCount])
        sleep(2)
        Dalamud.Log("[Cosmic Helper] Starting ICE")
        set_ice(true)
        jobCount = jobCount + 1
        cycleCount = 0
    end
end


--Plugin Check
local job = Player.Job
if not job.IsCrafter and MoveConfig > 0 then
    yield("/echo [Cosmic Helper] Only crafters should move. Script will continue.")
    MoveConfig = 0
end
if Ex4TimeConfig and Ex2TimeConfig then
    yield("/echo [Cosmic Helper] Having both EX+ timed missions enabled is not supported. The script will continue with only doing the EX+ 4HR missions.")
    Ex2TimeConfig = false
end

if ResearchConfig then
    log("Starting with class", RelicJobsConfig[0])
    equip_classjob(RelicJobsConfig[0])
end

yield("/echo Cosmic Helper started!")

--Main Loop
while Run_script do
    if IsAddonExists("WKSHud") then
        lunarCredits = Addons.GetAddon("WKSHud"):GetNode(1, 15, 17, 3).Text:gsub("[^%d]", "")
        lunarCredits = tonumber(lunarCredits)
    end
    if JumpConfig then
        ShouldJump()
    end
    if ResearchConfig then
        ShouldRelic()
    end
    if RetainerConfig ~= "N/A" then
        ShouldRetainer()
    end
    if LimitConfig > 0 then
        ShouldCredit()
    end
    if FailedConfig then
        ShouldReport()
    end
    if Ex2TimeConfig or Ex4TimeConfig then
        ShouldExTime()
    end
    if MoveConfig > 0 then
        ShouldMove()
    end
    if totalJobs > 0 then
        ShouldCycle()
    end
    sleep(loopDelay)
end
