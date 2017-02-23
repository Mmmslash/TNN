function RangeManager()
  local ranges = {
      ["easy_range"] = { ['spawner'] = SPAWN:New("Easy Range"),
                         ['zone'] = ZONE:New("Easy Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Blue,
                         ['label'] = "Easy"
                       }
  }

  function SpawnRange(self, range)
    self.Ranges[range]['group'] = self.Ranges[range]['spawner']:ReSpawn()
    return self.Ranges[range]['group']
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

rangeManager = RangeManager()
CreateRangeRadioMenus(rangeManager)
