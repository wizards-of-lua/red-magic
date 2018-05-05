-- red-magic/lumberaxe.lua

-- /lua require("red-magic.lumberaxe").start()
-- /lua require("red-magic.lumberaxe").giveItem()
local module = ...
require "red-magic.wol.Spell"

local pkg = {}
local log
local addDamage

function pkg.giveItem(entity,count)
  entity = entity or spell.owner
  count = count or 1
  local item = Items.get("golden_axe")
  item:putNbt( {
    tag= {
      MagicItem = "Lumberaxe",
      ench= {{id=999, lvl=1}}
    }
  })
  item.displayName = "Lumberaxe"
  entity:dropItem(item,count)
end

function pkg.start()
  spell:singleton( module)
  local lastClickedFace = {}
  local queue = Events.collect("BlockBreakEvent","LeftClickBlockEvent")
  while true do
    local event = queue:next()
    if event.name == "LeftClickBlockEvent" then
      local item = event.item
      if item.nbt and item.nbt.tag and item.nbt.tag.MagicItem == "Lumberaxe" then
        lastClickedFace[event.player.name] = event.face
      else
        lastClickedFace[event.player.name] = nil
      end
    end
    if event.name == "BlockBreakEvent" then
      local face = lastClickedFace[event.player.name]
      local pos = event.pos
      if face and event.block.name == "log" then
        --addDamage("Lumberaxe")
        spell:execute([[
          lua require('%s').hit(Vec3(%s,%s,%s),'%s')
        ]], module, pos.x, pos.y+1, pos.z, face)
      end
    end
  end
end

function addDamage(magicName)
  local item = spell.owner.mainhand
  if item and item.nbt and item.nbt.tag and item.nbt.tag.MagicItem == magicName then
    item.damage = item.damage + 1
  end
end

function pkg.hit(pos,face)
  spell.pos = pos
  while spell.block.name == "log" do
    spell:execute([[/setblock ~ ~ ~ air 0 destroy]])
    spell:move("up")
    sleep(2)
  end
end


-- Logs the given message into the chat
function log(message, ...)
  local n = select('#', ...)
  if n>0 then
    message = string.format(message, ...)
  end
  spell:execute("say %s", message)
end

return pkg
