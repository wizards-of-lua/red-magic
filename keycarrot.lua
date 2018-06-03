-- red-magic/keycarrot.lua

-- /lua require('red-magic.keycarrot').start()
-- /lua require('red-magic.keycarrot').giveItem()

local module = ...
require "red-magic.wol.Spell"

local pkg = {}
local toggleDoor

function pkg.giveItem(entity,count)
  entity = entity or spell.owner
  count = count or 1
  local item = Items.get("golden_carrot");
  item:putNbt({tag= {
    display = {
      Name = "KeyCarrot",
      Lore = {"Leftclick to open irondoors"}
    },
    ench = { {id=999, lvl=1} }
  }});
  entity:dropItem(item,count)
end

function pkg.start()
  spell:singleton( module)
  Events.on("LeftClickBlockEvent","RightClickBlockEvent"):call(function(event)
    if event.item.displayName == "KeyCarrot" then
      if event.player.gamemode=="creative" or event.player.gamemode=="survival" then
        spell.pos=event.pos
        if spell.block.data.half=="upper" then
          spell:move("down")
        end
        if toggleDoor() then
          if event.player.gamemode=="creative" then
            event.canceled = true
          end
        end
      end
    end
  end)
end

function toggleDoor()
  if spell.block.name=="iron_door" then
    if spell.block.data.open then
      spell:execute("/playsound minecraft:block.iron_door.close master @a ~ ~ ~")
      spell.block = spell.block:withData( {
        open = false
      })
    else
       spell:execute("/playsound minecraft:block.iron_door.open master @a ~ ~ ~")
      spell.block = spell.block:withData( {
        open = true
      })
    end
    return true
  end
  return false
end

return pkg

