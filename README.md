# TNN
Tuesday Night Noob training map

## Ranges
### Current Ranges
Easy - Stationary targets that do not return fire.

### Adding new ranges to TNN
1. Open TNN 4_1.miz in the DCS mission editor
2. Add new group of units and give them a name representing them (Easy range is "Easy Range", for example)
3. Add a new zone encompassing your range, and give it the same name as your range.
4. Save the Map
5. Open TNN4.lua in your favorite editor.
6. Add a new entry to the ranges table with your range's details:
 For example, if your new range was "Medium Range"
     ```lua
         local ranges = {
             ["easy_range"] = { ['spawner'] = SPAWN:New("Easy Range"),
                                ['zone'] = ZONE:New("Easy Range"),
                                ['type'] = 'ground',
                                ['smoke_color'] = SMOKECOLOR.Blue,
                                ['label'] = "Easy"
                              }, -- Comma from the last one
             ["medium_range"] = {  ['spawner'] = SPAWN:New("Medium Range"), -- Spawner used to respawn your range.
                                 ['zone'] = ZONE:New("Medium Range"),     -- Zone used to determine location of the range.
                                 ['type'] = 'ground',                     -- Type of range
                                 ['smoke_color'] = SMOKECOLOR.Red,        -- Smoke color to surround it with if called for.
                                 ['label'] = "Medium"                     -- Label to use in radio calls or other UI components.
                                }
                        }
    ```
7. Done!
