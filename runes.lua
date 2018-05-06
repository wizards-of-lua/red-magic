--red-magic/runes.lua

-- /lua require('red-magic.runes').dummy()
-- /lua require('red-magic.runes').start()
--[[
 Starting this spell with one simple rune handler:
 
    local handler = {
      requiredItems = {"stone","grass"},
      handle = function(data) 
        print(str(data.itemTypeCounts))
        print(str(data.positions))
        print(str(data.items))
      end
    }
    
    require('red-magic.runes').start( {handler} )
 ]]--

local module = ...
require "red-magic.wol.Spell"

local pkg = {}

local REDSTONE_ORE = Blocks.get("redstone_ore")
local REDSTONE_WIRE = Blocks.get("redstone_wire")
local REDSTONE_TORCH = Blocks.get("redstone_torch")
local BLOCK_PLACE_EVENT = "BlockPlaceEvent"
local CALLBACK_EVENT = module..".callback.event"
local MAX_BLOCKS = 128
local handleCallback
local shouldCallHandler
local handleBlockPlace
local checkRunes
local collectItems
local itemsOf
local countItems
local burst
local selectBlocks
local matchesBlock
local isRedstoneRune
local playFailSound
local sameY
local breakBlockAt
local log

local runeHandlers

function pkg.dummy()
  spell:execute([[
    /lua 
    local handler1 = require('red-magic.wallrune').handler();
    local handler2 = require('bytemage.giantspruce').handler()
    require('red-magic.runes').start( {handler1,handler2} )
  ]])
end

function pkg.start( aRuneHandlers)
  spell:singleton(module)
  runeHandlers = aRuneHandlers or {}
  local queue = Events.collect(BLOCK_PLACE_EVENT,CALLBACK_EVENT)
  while true do
    local event = queue:next()
    if event.name == CALLBACK_EVENT then
      handleCallback(event)
    end
    if event.name == BLOCK_PLACE_EVENT then
      if event.block.name == REDSTONE_ORE.name then
        handleBlockPlace(event)
      end
    end
  end
end

function pkg.matches(set, elements)
  for _,e in pairs(elements) do
    if not set[e] then
      return false
    end
  end
  return true
end

function handleCallback(event)
  --log("Callback! %s", str(event.data))
  for _,handler in pairs(runeHandlers) do
    if shouldCallHandler(handler, event.data.itemTypeCounts) then
      local done = handler.handle(event.data)
      if done then
        return
      end
    end
  end
  playFailSound()
end

function shouldCallHandler(handler, itemTypeCounts)
  if handler.requiredItems then
    return pkg.matches(itemTypeCounts, handler.requiredItems)  
  end
  if handler.accepts then
    return handler.accepts(itemTypeCounts)
  end
  error("Handler has no 'requiredItems' field and no 'accepts' function")
end

function handleBlockPlace(event)
  spell.pos = event.pos
  spell:execute([[
    /lua require('%s').checkRunes()
  ]], module)
end

function pkg.checkRunes(pos)
  pos = pos or spell.pos:floor()
  local sel = selectBlocks(pos, MAX_BLOCKS, cross, isRedstoneRune())
  
  local positionsByType = {}
  for _,pos in pairs(sel) do
    spell.pos = pos
    local blkType = spell.block.name
    local entries = positionsByType[blkType]
    if not entries then
      entries = {}
      positionsByType[blkType] = entries
    end
    table.insert(entries,pos)
  end
  
  local count = #(positionsByType[REDSTONE_WIRE.name] or {}) + #(positionsByType[REDSTONE_TORCH.name] or {})
  
  local itemEntities = {}
  if count > 0 then
    for _,pos in pairs(sel) do
      spell.pos = pos
      collectItems(itemEntities)
    end
    for _,item in pairs(itemEntities) do
      burst(item)
    end
    
    for i,pos in pairs(sel) do
      breakBlockAt(pos)
      if i%5==0 then
        sleep(1)
      end
    end
    
    local items=itemsOf(itemEntities)
    local itemTypeCounts = countItems(items)
    local data = {
      positions = positionsByType,
      items     = items,
      itemTypeCounts = itemTypeCounts
    }
    Events.fire(CALLBACK_EVENT, data)
  end
end

function itemsOf(itemEntities)
  local result = {}
  for _,entity in pairs(itemEntities) do
    table.insert(result,entity.item)
  end
  return result
end

function countItems(items)
  local result = {}
  for _,item in pairs(items) do
    result[item.id] = (result[item.id] or 0) + item.count
  end
  return result
end


function collectItems(resultItems)
  local es = Entities.find("@e[type=item,r=2]")
  for i,item in pairs(es) do
    table.insert(resultItems,item)
    item:kill()
  end
end

function burst(item)
  local origin = spell.pos
  spell.pos = item.pos
  local pitch = math.random()*2.0
  spell:execute([[
      /playsound minecraft:block.cloth.break block @a ~ ~ ~ 1 %s
    ]], pitch)
  spell:execute([[
    /particle smoke ~ ~0.5 ~ 0 0 0 0.03 5
  ]])
  spell.pos = origin
end

local callCount_breakBlockAt = -1
function breakBlockAt(pos)
  callCount_breakBlockAt = callCount_breakBlockAt + 1
  local s = spell.pos
  spell.pos = pos
  --spell:execute([[/setblock ~ ~ ~ air 0 destroy]])
  if callCount_breakBlockAt % 3 == 0 then
    local pitch = math.random()*2.0
    spell:execute([[
      /playsound minecraft:ui.toast.out block @a ~ ~ ~ 10 %s
    ]], pitch)
  end
  spell:execute([[
    /particle smoke ~ ~0.5 ~ 0 0 0 0.03 5
  ]])
  spell:execute([[/setblock ~ ~ ~ air 0]])
  spell.pos = s
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

function cross(pos)
  return {
    Vec3(pos.x+1, pos.y, pos.z),
    Vec3(pos.x-1, pos.y, pos.z),
    Vec3(pos.x+1, pos.y, pos.z+1),
    Vec3(pos.x-1, pos.y, pos.z-1),
    Vec3(pos.x+1, pos.y, pos.z-1),
    Vec3(pos.x-1, pos.y, pos.z+1),
    Vec3(pos.x, pos.y, pos.z+1),
    Vec3(pos.x, pos.y, pos.z-1),
    Vec3(pos.x, pos.y+1, pos.z),
    Vec3(pos.x, pos.y-1, pos.z),
    Vec3(pos.x, pos.y-1, pos.z+1),
    Vec3(pos.x, pos.y-1, pos.z-1),
    Vec3(pos.x-1, pos.y-1, pos.z),
    Vec3(pos.x+1, pos.y-1, pos.z),
    Vec3(pos.x, pos.y+1, pos.z+1),
    Vec3(pos.x, pos.y+1, pos.z-1),
    Vec3(pos.x-1, pos.y+1, pos.z),
    Vec3(pos.x+1, pos.y+1, pos.z)
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

function isRedstoneRune()
  return function(pos)
    spell.pos = pos
    return (spell.block.name==REDSTONE_WIRE.name and spell.block.data.power>0)
           or (spell.block.name==REDSTONE_ORE.name) 
           or (spell.block.name==REDSTONE_TORCH.name)
  end
end

function playFailSound()
  for i=1,5 do
    local pitch = math.random()*2
    spell:execute([[
      /playsound minecraft:block.glass.break block @a ~ ~ ~ 5 %s
    ]], pitch)
    spell:execute([[
      /playsound minecraft:block.note.guitar block @a ~ ~ ~ 10 %s
    ]], pitch)
    sleep(1)
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