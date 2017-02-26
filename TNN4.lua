function RangeManager()
  local ranges = {
      ["easy_range"] = { ['spawner'] = SPAWN:New("Easy Range"):InitLimit(20,0),
                         ['zone'] = ZONE:New("Easy Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Blue,
                         ['label'] = "Easy",
                         ['latlong'] = '41 50\' 46" N   41 46\' 51" E',
                         ['mgrs'] = '37T GG 32306 36033'
                       },
      ["medium_range"] = { ['spawner'] = SPAWN:New("Medium Range"):InitLimit(22,0),
                         ['zone'] = ZONE:New("Medium Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Orange,
                         ['label'] = "Medium",
                         ['latlong'] = '42 10\' 40" N   42 28\' 54" E',
                         ['mgrs'] = '38T KM 92029 72577'
                       },
      ["hard_range"] = { ['spawner'] = SPAWN:New("Hard Range"):InitLimit(30,0),
                         ['zone'] = ZONE:New("Hard Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Red,
                         ['label'] = "Hard",
                         ['latlong'] = '42 45\' 33" N 42 1\' 52" E',
                         ['mgrs'] = '38T KN 57013 38373'
                       },
      ["ship_range_easy"] = { ['spawner'] = SPAWN:New("Ship Range Easy"):InitLimit(30,0),
                         ['zone'] = ZONE:New("Ship Range Easy"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Green,
                         ['label'] = "Easy Ship",
                         ['latlong'] = '41 29\' 38" N 41 11\' 31" E',
                         ['mgrs'] = '38T KN 57013 38373'
                       },
      ["ship_range_medium"] = { ['spawner'] = SPAWN:New("Ship Range Medium"):InitLimit(30,0),
                         ['zone'] = ZONE:New("Ship Range Medium"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Green,
                         ['label'] = "Medium Ship",
                         ['latlong'] = '41 29\' 38" N 41 11\' 31" E',
                         ['mgrs'] = '38T KN 57013 38373'
                       }
  }

  function SpawnRange(self, range)
    env.info("Starting range spawn: " .. range)
    MESSAGE:New(self.Ranges[range]['label'] .. " Range is respawning.",10,"Range Respawns"):ToAll()
    pcall(function()
        self.Ranges[range]['group']:Destroy()
        env.info("Destroyed range " .. self.Ranges[range]['label'])
     end)
    env.info("Scheduling ReSpawn")
    if self.Ranges[range]['scheduler_id'] then
      SCHEDULER:Remove(self.Ranges[range]['scheduler_id'])
    end
    
    self.Ranges[range]['scheduler_id'] = nil
    SCHEDULER:New(nil,function()self.Ranges[range]['group'] = self.Ranges[range]['spawner']:Spawn()end,{},5)
    env.info("Respawn scheduled")
  end

  function ForEachRange(self, fn)
    for idx, range in pairs(self.Ranges) do
      fn(idx, range)
    end
  end

  return { SpawnRange = SpawnRange,
    Ranges = ranges,
    ForEachRange = ForEachRange }
end

function DroneManager()
  local drones = {
    ['easy_drones'] = {
      ['spawners'] = {SPAWN:New('Easy Drones 1'):InitLimit(2,0):InitRepeat(),
                      SPAWN:New('Easy Drones 2'):InitLimit(2,0):InitRepeat(),
                      SPAWN:New('Easy Drones 3'):InitLimit(2,0):InitRepeat()},
      ['zone'] = ZONE:New('Easy Drones'),
      ['label'] = "Easy Air-to-Air Drones"
    },
    ['medium_drones'] = {
      ['spawners'] = {SPAWN:New('Medium Drones 1'):InitLimit(2,0):InitRepeat(),
                      SPAWN:New('Medium Drones 2'):InitLimit(2,0):InitRepeat()},
      ['zone'] = ZONE:New('Medium Drones'),
      ['label'] = "Medium Air-to-Air Drones"
    },
    ['hard_drones'] = {
      ['spawners'] = {SPAWN:New('Hard Drones 1'):InitLimit(2,0):InitRepeat(),
                      SPAWN:New('Hard Drones 2'):InitLimit(2,0):InitRepeat()},
      ['zone'] = ZONE:New('Hard Drones'),
      ['label'] = "Hard Air-to-Air Drones"
    }
  }

  function SpawnDrones(self, drones)
    env.info("Trying to spawn drone: " .. drones)
    self.Drones[drones]['groups'] = {}
    env.info("Cleared group array for " .. drones)
    for idx,spawner in ipairs(self.Drones[drones]['spawners']) do
      local spawned_group = spawner:Spawn()
      env.info("Attempted spawning of " .. drones)
      if spawned_group then
        env.info("Spawned a group for " .. drones)
        table.insert(self.Drones[drones]['groups'],spawned_group)
        
        if drones ~= 'easy_drones' then
          env.info("Got something with smarts")
          local AICapZone = AI_CAP_ZONE:New( self.Drones[drones]['zone'], 5000, 7000, 500, 780, "BARO")
          AICapZone:SetControllable( spawned_group )
          AICapZone:SetEngageRange( 30480 )
          AICapZone:__Start( 1 )
        else
          env.info("Got something with dumbs")
          spawned_group:OptionROEHoldFire()
          spawned_group:OptionROTNoReaction()
        end
      end
    end
  end

  function ForEachDrones(self, fn)
    for idx, drones in pairs(self.Drones) do
      fn(idx, drones)
    end
  end

  return { SpawnDrones = SpawnDrones,
           Drones = drones,
           ForEachDrones = ForEachDrones }
end

function RangeSmoke(range)
  range.zone:SmokeZone(range.smoke_color, 4)
end

function CreateRangeRadioMenus(RangeManager)
  env.info("setting up radios")
  
  local range_manager = RangeManager
  SET_CLIENT:New():FilterCoalitions("blue"):FilterStart():ForEachClient(function(client)
      client:Alive(function(client)
        local ranges_parent_menu = MENU_CLIENT:New(client, "Ranges")
        range_manager:ForEachRange(function(range_name, range)
          local range_parent_menu = MENU_CLIENT:New(client, range.label, ranges_parent_menu)
          
          MENU_CLIENT_COMMAND:New(client, "Start Smoke", range_parent_menu, RangeSmoke, range)
          MENU_CLIENT_COMMAND:New(client, "Respawn", range_parent_menu, rangeManager.SpawnRange, rangeManager, range_name)
          MENU_CLIENT_COMMAND:New(client, "Get Bearing And Range", range_parent_menu, SendBearingToRangeMessageToClient, client, range)
        end)  
      end)
  end)
end

function SetupRangeRespawn(RangeManager)
  RangeManager:ForEachRange(function(range_name, range)
    SCHEDULER:New(nil,function()
      env.info("Checking units in range " .. range_name)
      local alive_units = 0
      local total_units = range['group']:GetInitialSize()
      for unitid, unitdata in pairs(range['group']:GetUnits()) do
        if unitdata:IsAlive() then
          alive_units = alive_units + 1
        end
      end
      
      env.info("Found " .. alive_units .. " alive units out of " .. total_units .. " total")
      
      if alive_units == 0 then
        RangeManager:SpawnRange(range_name)
        env.info("Sent request for respawn")
      elseif alive_units ~= total_units and range['scheduler_id'] == nil then
        env.info('Scheduling Respawn for ' .. range_name)
        scheduler,s_id = SCHEDULER:New(nil,RangeManager.SpawnRange,{RangeManager, range_name},600,nil,0,nil)
        range['scheduler_id'] = s_id
      end
      
    end,{},0,10)
  end)
end

function SetupTankers()
  local spawn_tkr_1 = SPAWN:New('Tanker 1'):InitLimit(1,0):InitRepeat()
  local spawn_tkr_2 = SPAWN:New('Tanker 2'):InitLimit(1,0):InitRepeat()
  
  SCHEDULER:New(nil,function()
     local tnk1 = spawn_tkr_1:Spawn()
     local tnk2 = spawn_tkr_2:Spawn()
     
     if tnk1 then
       env.info("Spawned Tanker 1")
       MESSAGE:New("Respawned US Tanker",10,"Respawns"):ToAll()
     end
     
     if tnk2 then
       env.info("Spawned Tanker 2")
       MESSAGE:New("Respawned RUS Tanker",10,"Respawns"):ToAll()
     end
  end,{},0,120,0.3,nil)
end


function SetupAWACS()
  local spawn_awacs_1 = SPAWN:New('AWACS 1'):InitLimit(1,0):InitRepeat()
  local spawn_awacs_2 = SPAWN:New('AWACS 2'):InitLimit(1,0):InitRepeat()
  
  SCHEDULER:New(nil,function()
     local awacs1 = spawn_awacs_1:Spawn()
     local awacs2 = spawn_awacs_2:Spawn()
     
     if awacs1 then
       env.info("Spawned AWACS1")
       MESSAGE:New("Respawned USA AWACS South",10,"Respawns"):ToAll()
     end
     
     if awacs2 then
       env.info("Spawned AWACS2")
       MESSAGE:New("Respawned RUS AWACS North",10,"Respawns"):ToAll()
     end
  end,{},0,120,0.3,nil)
end

rangeManager = RangeManager()
rangeManager:SpawnRange('easy_range')
rangeManager:SpawnRange('medium_range')
rangeManager:SpawnRange('hard_range')
rangeManager:SpawnRange('ship_range_easy')
rangeManager:SpawnRange('ship_range_medium')

function SendBearingToRangeMessageToClient(client, range)
  local messageText = "Bearing and distance to %range_name% is: %BRTEXT%"
  messageText = string.gsub(messageText, "%%range_name%%", range.label)
  messageText = string.gsub(messageText, "%%BRTEXT%%", GetBearingAndRangeText(client:GetVec2(), range.zone:GetVec2()))

  local message = MESSAGE:New(messageText,MessageDuration,MessageCategory):ToClient(client)
end

function GetBearingAndRangeText(first_vec2, second_vec2)
    local positionable1_vec3 = POINT_VEC3:NewFromVec2(first_vec2, 0)
    
    local positionable2_vec3 = POINT_VEC3:NewFromVec2(second_vec2, 0)

    local angle_degrees, distance = GetBearingAndRange(positionable1_vec3, positionable2_vec3)
  
    local distance_unit = ''
    if positionable1_vec3:IsMetric() then
      distance = UTILS.Round(distance / 1000, 2)
      distance_unit = 'km'
    else
      distance = UTILS.Round(UTILS.MetersToNM(dsitance), 2)
      distance_unit = 'nm'
    end    
    local s = string.format( '%03d', angle_degrees ) .. ' for ' .. distance .. distance_unit
    return s
end

function GetBearingAndRange(positionable1_vec3, positionable2_vec3)
    local direction_vec3 = positionable1_vec3:GetDirectionVec3(positionable2_vec3)
    local angle_degrees = UTILS.Round(UTILS.ToDegree(positionable1_vec3:GetDirectionRadians(direction_vec3)), 0)
    local distance = positionable1_vec3:Get2DDistance(positionable2_vec3)
    
    return angle_degrees, distance
end

rangeManager = RangeManager()
rangeManager:ForEachRange(function(range_name, _range)
  rangeManager:SpawnRange(range_name)
end)

droneManager = DroneManager()
SCHEDULER:New(nil,function()
  droneManager:SpawnDrones('easy_drones')
  droneManager:SpawnDrones('medium_drones')
  droneManager:SpawnDrones('hard_drones')
end,{},10,150,0, nil)

SCHEDULER:New(nil,function()CreateRangeRadioMenus(rangeManager)end,{},10,nil,0)
SCHEDULER:New(nil,function()SetupRangeRespawn(rangeManager)end,{},10,nil,0)
SetupTankers()
SetupAWACS()
