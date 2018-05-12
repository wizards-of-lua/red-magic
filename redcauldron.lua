-- red-magic/redcauldron.lua 

-- /lua require("red-magic.redcauldron").start(receipies)

local module = ...
require "red-magic.wol.Spell"
require "red-magic.wol.Vec3"

local pkg = {}
local RED_CAULDRON_EVENT = module..".event"
local log
local isBelowCauldron
local isNearLitRedstone
local payXP
local isEnchanted
local transformItem
local repairItem
-- see https://www.minecraftforum.net/forums/minecraft-java-edition/creative-mode/366933-noteblock-pitches-for-playsound
local notes={c=0.7,d=0.8,e=0.9,f=0.95,g=1.05}
local playsound

function pkg.start(receipies)
  if not receipies then
    error("missing receipies")
  end
  spell:singleton(module)
  local startPos = spell.pos
  local queue = Events.collect("LeftClickBlockEvent","RightClickBlockEvent",RED_CAULDRON_EVENT)
  while true do
    local event = queue:next()
    if event.name == RED_CAULDRON_EVENT then
      local e = event.data.droppedItem
      local pos = event.data.pos
      --log("e.item.id = %s, pos=%s", e.item.id, pos)
      for _,r in pairs(receipies) do
        if r.input == e.item.id then
          if not isEnchanted(e.item) then
            transformItem(pos, e, r.xp, function() 
              r.action(e)
            end)
          else
            repairItem(pos, e)
          end
        end
      end
    else
      spell.pos = event.pos
      if "lit_redstone_ore"==spell.block.name then
        if isBelowCauldron(spell.pos) then
          spell:move("up")
          spell.pos = spell.pos:floor()
          spell:execute([[
            /lua require("%s").startRedCauldron()
          ]], module)
        end
      end
    end
    spell.pos = startPos
  end
end

function pkg.startRedCauldron()
  spell:singleton("red-cauldron-"..spell.pos:coords())
  while true do
    if not isAboveLitRedstone(spell.pos) then
      return
    end
    if spell.block.name ~= "cauldron" then
      return
    end
    if spell.block.data.level > 0 then
      for i=1,10 do
        spell:execute([[
          /particle reddust ~0.%s ~1.1 ~0.%s 0 0 0 1 0
        ]], math.random(2,8), math.random(2,8))
        sleep(2)
      end
      local entities = Entities.find("@e[dx=0,dy=0,dz=0,type=item]")
      for i,entity in pairs(entities) do
        --log("%s = %s", i, e.item.id)
        if type(entity) == "DroppedItem" then 
          Events.fire(RED_CAULDRON_EVENT, {droppedItem = entity, pos=spell.pos})
        end
      end
    end
  end
end

function repairItem(pos, entity)
  local s = spell.pos
  spell.pos = pos
  if entity.item and entity.item.damage > 0 then
    local items = Entities.find("@e[dx=0,dy=0,dz=0,type=item]")
    local nuggets = {}
    local count = 0
    for _,i in pairs(items) do
      if i.item.id == "gold_nugget" then
        count = count + i.item.count
        table.insert(nuggets,i)
      end
    end
    local price = math.min(entity.item.damage,count)
    local topay = price
    while topay > 0 do
      local nugget = table.remove(nuggets,1)
      if not nugget then
        break
      end
      if nugget.item.count > topay then
        nugget.item.count = nugget.item.count - topay
        topay = 0
      else
        topay = topay - nugget.item.count
        nugget:kill()
      end
    end
    if topay > 0 then
      -- paranoid check
      price = price - topay
    end
    local points = price
    local pitch = 2.0 - entity.item.damage*0.025
    while entity.item.damage > 0 and points > 0 do
      points = points - 1
      entity.item.damage = entity.item.damage - 1
      pitch = pitch + 0.025
      playsound(pitch)
      sleep(1)
    end
    if entity.item.damage == 0 then
      sleep(10)
      playsound(notes.c)
      playsound(notes.e)
      playsound(notes.g)
    end
  end
  entity.motion = Vec3(0,0.3,0)
  spell.pos = s
end

function transformItem(pos, entity, cost, action)
  local s = spell.pos
  spell.pos = pos
  local payed = false
  for i=1,entity.item.count do
    if payXP(cost) then
      payed = true
      action()
      playsound(notes.c)
      playsound(notes.e)
      playsound(notes.g)
      sleep(1)
    end
  end
  if payed then
    entity:kill()
    spell.block = spell.block:withData({level=spell.block.data.level-1}) 
  end
  spell.pos = s
end

function isEnchanted(item)
  return item.nbt and item.nbt.tag and item.nbt.tag.ench and #item.nbt.tag.ench > 0
end

function isBelowCauldron(pos)
  local s = spell.pos
  spell.pos = pos
  spell:move("up")
  local result = spell.block.name == "cauldron"
  spell.pos = s
  return result
end

function isAboveLitRedstone(pos)
  local s = spell.pos
  spell.pos = pos
  spell:move("down")
  local result = spell.block.name == "lit_redstone_ore"
  spell.pos = s
  return result
end

function playsound(pitch)
  spell:execute([[
      /playsound minecraft:block.note.pling block @a ~ ~ ~ 1 %s
  ]], pitch)
end

function payXP(amount)
  local player = Entities.find("@p")[1]
  local xp = player.nbt.XpLevel
  if xp < amount then
    return false
  end
  if player then
    spell:execute([[
      /xp -%sL %s
    ]],amount,player.name)
  end
  return true
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