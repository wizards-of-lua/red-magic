-- red-magic/magichoe.lua.lua

-- /lua require("red-magic.magichoe").start()
-- /lua require("red-magic.magichoe").giveItem()
local module = ...
require "red-magic.wol.Spell"

local pkg = {}
local addDamage
local breakBlockAt
local tryPlant
local selectBlocks
local sameY
local matchesBlock
local log
local MAX_AREA = 128
local seeds = {wheat="wheat_seeds",carrots="carrot",potatoes="potato",beetroots="beetroot",nether_wart="nether_wart"}

function pkg.giveItem(entity,count)
  entity = entity or spell.owner
  count = count or 1
  local item = Items.get("golden_hoe")
  item:putNbt( {
    tag= {
      MagicItem = "Magic Hoe",
      ench= {{id=999, lvl=1}}
    }
  })
  item.displayName = "Magic Hoe"
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
      if item.nbt and item.nbt.tag and item.nbt.tag.MagicItem == "Magic Hoe" then
        lastClickedFace[event.player.name] = event.face
      else
        lastClickedFace[event.player.name] = nil
      end
    end
    if event.name == "BlockBreakEvent" then
      local face = lastClickedFace[event.player.name]
      local pos = event.pos
      local name = event.block.name
      -- log("broke %s",event.block.name)
      if face and seeds[name] then
        spell:execute([[
          lua require('%s').hit(Vec3(%s,%s,%s),'%s','%s')
        ]], module, pos.x, pos.y, pos.z, face, name)
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

function pkg.hit(pos,face,blocktype)
  spell.pos = pos
  local sel = selectBlocks(pos, MAX_AREA, sameY, matchesBlock(Blocks.get(blocktype)))
  for _,pos in pairs(sel) do
    breakBlockAt(pos)
    sleep(1)
    tryPlant(pos,blocktype)
  end
end

function breakBlockAt(pos)
  local s = spell.pos
  spell.pos = pos
  spell:execute([[/setblock ~ ~ ~ air 0 destroy]])
  spell.pos = s
end

function tryPlant(pos,blocktype)
  spell.pos = pos
  local seedType = seeds[blocktype]
  if seedType then
    local es = Entities.find("@e[type=item,r=5]")
    for i,e in pairs(es) do
      -- log("%s=%s", i, e.item.id)
      if e.item.id == seedType then
        e.item.count = e.item.count - 1
        if e.item.count <=0 then
          e:kill()
        end
        spell:execute([[/setblock ~ ~ ~ %s]], blocktype)
        break
      end
    end
  end
end

-- Selects a list of block positions
function selectBlocks(start, maxsel, funcNeighbors, funcMatcher)
  local original = spell.pos
  local result   = {}
  local selected = 0
  local done     = {}
  local todo     = {}
  table.insert(todo,start)
  while next(todo) do
    local pos  = table.remove(todo,1)
    --log("pos=%s",pos)
    local pkey = pos:tostring()
    if not done[pkey] then
      table.insert(result,pos)
      done[pkey] = true
      selected   = selected+1
      if selected > maxsel then
        --error("Can't select more than %s blocks!", maxsel)
        break
      end
      local neighbors = funcNeighbors(pos)
      for i,npos in pairs(neighbors) do
        local nkey = npos:tostring()
        if not done[nkey] then
          local matches = funcMatcher(npos)
          if matches then
            table.insert(todo,npos)
          end
        end
      end
    end
  end
  spell.pos = original
  return result
end

function sameY(pos)
  return {
    Vec3(pos.x+1, pos.y, pos.z),
    Vec3(pos.x-1, pos.y, pos.z),
    Vec3(pos.x, pos.y, pos.z+1),
    Vec3(pos.x, pos.y, pos.z-1)
  }
end

function matchesBlock(block)
  return function(pos)
    spell.pos = pos
    -- TODO also compare data
    --log("matches? %s == %s", spell.block.name, block.name)
    return spell.block.name==block.name
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
