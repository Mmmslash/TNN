function SpawnManager()
  local spawns = {
      ["easy_range"] = { ['spawner'] = SPAWN:New("Easy Range"), 
                         ['zone'] = ZONE:New("Easy Range"),
                         ['type'] = 'ground',
                         ['smoke_color'] = SMOKECOLOR.Blue
                       }
  }
  
  function SpawnGroup(self, group)
    self.Spawns[group]['group'] = self.Spawns[group]['spawner']:ReSpawn()
    return self.Spawns[group]['group']
  end
  
  return { SpawnGroup = SpawnGroup,
           Spawns = spawns }
end

spawnManager = SpawnManager()

function RangeSmoke(difficulty)
  ZONE:New(difficulty .. " Range"):SmokeZone(SMOKECOLOR.Blue, 4)
end

function AddRangeSmokeRadioMenus()
  local smoke_parent_menu = MENU_MISSION:New("Smoke")
  local difficulties = {"Easy"} 
  for idx, difficulty in ipairs(difficulties) do
    MENU_MISSION_COMMAND:New(difficulty,smoke_parent_menu,RangeSmoke,difficulty)
  end
end

function AddRangeRespawnRadioMenus()
  local smoke_parent_menu = MENU_MISSION:New("Smoke")
  local difficulties = {"Easy"} 
  for idx, difficulty in ipairs(difficulties) do
    MENU_MISSION_COMMAND:New(difficulty,smoke_parent_menu,RangeSmoke,difficulty)
  end
end

AddRangeSmokeRadioMenus()
AddRangeRespawnRadioMenus()
