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
  }

  function SpawnRange(self, range)
    MESSAGE:New(self.Ranges[range]['label'] .. " Range is respawning.",10,"Range Respawns"):ToAll()
    pcall(function()
        self.Ranges[range]['group']:Destroy()
        env.info("Destroyed range " .. self.Ranges[range]['label'])
     end)
    SCHEDULER:New(nil,function()self.Ranges[range]['group'] = self.Ranges[range]['spawner']:ReSpawn()end,{},2,nil,0,nil)
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
    pcall(function() 
      for group_name,group in pairs(self.Drones[drones]['groups']) do 
        --group:Destroy()
      end
    end)
    
    self.Drones[drones]['groups'] = {}
    
    SCHEDULER:New(nil,function()
        for idx,spawner in ipairs(self.Drones[drones]['spawners']) do
          local spawned_group = spawner:Spawn()
          if spawned_group ~= nil then
            env.info("Name of spawned group: " .. spawned_group.GroupName)
            table.insert(self.Drones[drones]['groups'],spawned_group)
            local AICapZone = AI_CAP_ZONE:New( self.Drones[drones]['zone'], 5000, 7000, 500, 780, "BARO")
            AICapZone:SetControllable( spawned_group )
            AICapZone:SetEngageRange( 30480 )
            AICapZone:__Start( 1 )
          end
        end
      end,
      {},5,nil,0,nil)
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
  local ranges_parent_menu = MENU_MISSION:New("Ranges")
  local range_manager = RangeManager
  range_manager:ForEachRange(function(range_name, range)
    local range_parent_menu = MENU_MISSION:New(range.label, ranges_parent_menu)
    MENU_MISSION_COMMAND:New("Start Smoke", range_parent_menu, RangeSmoke, range)
    MENU_MISSION_COMMAND:New("Respawn", range_parent_menu, rangeManager.SpawnRange, rangeManager, range_name)
  end)
end

function SetupRangeRespawn(RangeManager)
  RangeManager:ForEachRange(function(range_name, range)
    SCHEDULER:New(nil,function()
      local alive_units = 0
      for unitid, unitdata in pairs(range['group']:GetUnits()) do
        if unitdata:IsAlive() then
          alive_units = alive_units + 1
        end
      end
      
      if alive_units == 0 then
        success,schedulerid = pcall(function() SCHEDULER:Remove(range['scheduler_id']) end)
        RangeManager:SpawnRange(range_name)
      end
      
    end,{},0,10,0,nil)
    
    for unitid,unitdata in pairs(range['group']:GetUnits()) do
      unitdata:HandleEvent(EVENTS.Dead)
      function unitdata:OnEventDead(EventData)
        success,schedulerid = pcall(function() SCHEDULER:Remove(range['scheduler_id']) end)
        scheduler,s_id = SCHEDULER:New(nil,RangeManager.SpawnRange,{RangeManager, range_name},600,nil,0,nil)
        range['scheduler_id'] = s_id
      end
    end
  end)
end


rangeManager = RangeManager()
rangeManager:SpawnRange('easy_range')
rangeManager:SpawnRange('medium_range')
rangeManager:SpawnRange('hard_range')

droneManager = DroneManager()
SCHEDULER:New(nil,function()
  droneManager:SpawnDrones('easy_drones')
  droneManager:SpawnDrones('medium_drones')
  droneManager:SpawnDrones('hard_drones')
end,{},10,10,0, nil)

SCHEDULER:New(nil,function()CreateRangeRadioMenus(rangeManager)end,{},10,nil,0)
SCHEDULER:New(nil,function()SetupRangeRespawn(rangeManager)end,{},10,nil,0)

