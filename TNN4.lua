function RangeManager()
  local ranges = {
      ["easy_range"] = { ['spawner'] = SPAWN:New("Easy Range"),
                         ['zone'] = ZONE:New("Easy Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Blue,
                         ['label'] = "Easy",
                         ['latlong'] = '41 50\' 46" N   41 46\' 51" E',
                         ['mgrs'] = '37T GG 32306 36033'
                       },
      ["medium_range"] = { ['spawner'] = SPAWN:New("Medium Range"),
                         ['zone'] = ZONE:New("Medium Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Orange,
                         ['label'] = "Medium",
                         ['latlong'] = '42 10\' 40" N   42 28\' 54" E',
                         ['mgrs'] = '38T KM 92029 72577'
                       },
      ["hard_range"] = { ['spawner'] = SPAWN:New("Hard Range"),
                         ['zone'] = ZONE:New("Hard Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Red,
                         ['label'] = "Hard",
                         ['latlong'] = '42 45\' 33" N 42 1\' 52" E',
                         ['mgrs'] = '38T KN 57013 38373'
                       },
  }

  function SpawnRange(self, range)
    pcall(function() self.Ranges[range]['group']:Destroy() end)
    MESSAGE:New(self.Ranges[range]['label'] .. " Range is respawning.",10,"Range Respawns"):ToAll()
    SCHEDULER:New(nil,function()self.Ranges[range]['group'] = self.Ranges[range]['spawner']:ReSpawn()end,{},2,1000,0,11)
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
    for unitid,unitdata in pairs(range['group']:GetUnits()) do
      unitdata:HandleEvent(EVENTS.Dead)
      function unitdata:OnEventDead(EventData)
        success,schedulerid = pcall(function() SCHEDULER:Remove(range['scheduler_id']) end)
        scheduler,s_id = SCHEDULER:New(nil,RangeManager.SpawnRange,{RangeManager, range_name},600,1200,0,601)
        range['scheduler_id'] = s_id
      end
    end
  end)
end

rangeManager = RangeManager()
rangeManager:SpawnRange('easy_range')
rangeManager:SpawnRange('medium_range')
rangeManager:SpawnRange('hard_range')
SCHEDULER:New(nil,function()CreateRangeRadioMenus(rangeManager)end,{},3,1000,0,21)
SCHEDULER:New(nil,function()SetupRangeRespawn(rangeManager)end,{},4,1000,0,21)
