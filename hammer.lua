-- red-magic/hammer.lua

-- /lua require("red-magic.hammer").start()
-- /lua require("red-magic.hammer").giveItem()
local module = ...
require "red-magic.wol.Spell"

local pkg = {}
local tryHarvest
local log
local addDamage
local accept = {}
accept["stone"] = true
accept["coal_ore"] = true
accept["iron_ore"] = true
accept["diamond_ore"] = true
accept["gold_ore"] = true
accept["lapis_ore"] = true
accept["redstone_ore"] = true
accept["emerald_ore"] = true
accept["cobblestone"] = true
accept["sandstone"] = true
accept["quartz_ore"] = true
accept["netherrack"] = true
accept["nether_brick"] = true
accept["red_nether_brick"] = true
accept["stonebrick"] = true
accept["stained_hardened_clay"] = true
accept["prismarine"] = true
accept["end_stone"] = true
accept["magma"] = true
accept["lit_redstone_ore"] = true

function pkg.giveItem(entity,count)
  entity = entity or spell.owner
  count = count or 1
  local item = Items.get("golden_pickaxe")
  item:putNbt( {
    tag= {
      MagicItem = "Hammer",
      ench= {{id=999, lvl=1}}
    }
  })
  item.displayName = "Hammer"
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
      if item.nbt and item.nbt.tag and item.nbt.tag.MagicItem == "Hammer" then
        lastClickedFace[event.player.name] = event.face
      else
        lastClickedFace[event.player.name] = nil
      end
    end
    if event.name == "BlockBreakEvent" then
      local face = lastClickedFace[event.player.name]
      local pos = event.pos
      if face and accept[event.block.name] then
        --addDamage("Hammer")
        spell:execute([[
          lua require('%s').hit(Vec3(%s,%s,%s),'%s')
        ]], module, pos.x, pos.y, pos.z, face)
      end
    end
  end
end

function pkg.hit(pos,face)
  spell.pos = pos
  if face == "up" or face == "down" then
    spell:move("left")
    spell:move("back")
    for z=1,3 do
      for x=1,3 do
        tryHarvest()
        spell:move("right")
      end
      spell:move("left",3)
      spell:move("forward")
    end
  elseif face == "north" or face == "south" then
    spell:move("east")
    spell:move("down")
    for y=1,3 do
      for x=1,3 do
        tryHarvest()
        spell:move("west")
      end
      spell:move("east",3)
      spell:move("up")
    end
  else
    spell:move("south")
    spell:move("down")
    for y=1,3 do
      for x=1,3 do
        tryHarvest()
        spell:move("north")
      end
      spell:move("south",3)
      spell:move("up")
    end
  end
end

function addDamage(magicName)
  local item = spell.owner.mainhand
  if item and item.nbt and item.nbt.tag and item.nbt.tag.MagicItem == magicName then
    item.damage = item.damage + 1
  end
end

function tryHarvest() 
  if accept[spell.block.name] then 
    spell:execute([[/setblock ~ ~ ~ air 0 destroy]])
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
