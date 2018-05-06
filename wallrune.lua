-- red-magic/wallrune.lua

-- /lua require('red-magic.wallrune').start()

local module = ...
require 'red-magic.wol.Spell'
local pkg = {}

local ASYNC_EVENT = module..".async.event"
local REQUIRED_ITEMS = {"stone","stone_shovel"}
local REDSTONE_WIRE = Blocks.get("redstone_wire")
local REDSTONE_TORCH = Blocks.get("redstone_torch")
local COBBLESTONE = Blocks.get("cobblestone")
local SUPPORTED_BLOCKS = { stone='stone', cobblestone='cobblestone', stonebrick='stonebrick', sandstone='sandstone'}
local STONE_MAP = {
  [0] = Blocks.get("stone"),
  [1] = Blocks.get("stone"):withData({variant="granite"}),
  [2] = Blocks.get("stone"):withData({variant="smooth_granite"}),
  [3] = Blocks.get("stone"):withData({variant="diorite"}),
  [4] = Blocks.get("stone"):withData({variant="smooth_diorite"}),
  [5] = Blocks.get("stone"):withData({variant="andesite"}),
  [6] = Blocks.get("stone"):withData({variant="smooth_andesite"})
}
local STONEBRICK_MAP = {
  [0] = Blocks.get("stonebrick"),
  [1] = Blocks.get("stonebrick"):withData({variant="mossy_stonebrick"}),
  [2] = Blocks.get("stonebrick"):withData({variant="cracked_stonebrick"}),
  [3] = Blocks.get("stonebrick"):withData({variant="chiseled_stonebrick"})
}
local SANDSTONE_MAP = {
  [0] = Blocks.get("sandstone"),
  [1] = Blocks.get("sandstone"):withData({variant="chiseled_sandstone"}),
  [2] = Blocks.get("sandstone"):withData({variant="smooth_stonebrick"}),
}

local handle
local filterPositions
local getBlockFor
local placeBlockEffecs
local append
local containsAllKeys
local containsAnyKeys
local log

function pkg.handler()
  local handler = {
    --requiredItems = REQUIRED_ITEMS,
    accepts = function(itemTypeCounts)
      --log("accepts")
      return containsAnyKeys(itemTypeCounts, SUPPORTED_BLOCKS)
    end,
    handle = function(data) 
      --log("inside %s.handler", module)
      local canHandle = true -- check here if we can do this
      if canHandle then
        Events.fire(ASYNC_EVENT,data)
      end
      return canHandle
    end
  }
  return handler
end

function pkg.start()
  spell:singleton(module)
  local queue = Events.collect(ASYNC_EVENT)
  while true do
    local event = queue:next()
    --log("inside event loop of "..module)
    handle(event.data)
  end
end

function handle(data)
  --log("handle %s", str(data.itemTypeCounts))
  local count = 0
  for _,v in pairs(SUPPORTED_BLOCKS) do
    count = count + (data.itemTypeCounts[v] or 0)
  end
  --log("count=%s", count)
  
  local positions = filterPositions(data.positions)
  
  local k,pos
  local ymap = {}
  
  for _,item in pairs(data.items) do
    if count < 0 then
      break
    end
    if SUPPORTED_BLOCKS[item.id] then
      for i=1,item.count do
        if count <= 0 then
          break
        end
        k,pos = next(positions,k)
        if not k then
          k,pos = next(positions,k) 
        end
        
        local ykey = pos:floor():tostring()
        local y = ymap[ykey] or pos.y
        spell.pos = Vec3(pos.x, y, pos.z)
        
        placeBlockEffecs()
        sleep(1)
        spell.block = getBlockFor(item)
        ymap[ykey] = y + 1
        count = count - 1
      end
    end
  end
end

function getBlockFor(item)
  --log("getBlockFor() item=%s %s",item.id, item.damage)
  if item.id == "stone" then
    return STONE_MAP[item.damage]
  end
  if item.id == "cobblestone" then
    return COBBLESTONE
  end
  if item.id == 'sandstone' then
    return SANDSTONE_MAP[item.damage]
  end
  if item.id == 'stonebrick' then
    return STONEBRICK_MAP[item.damage]
  end
  error("Unexpected item: %s", item.id)
end

function filterPositions(map)
  local result = {}
  append(result, map[REDSTONE_TORCH.name])
  append(result, map[REDSTONE_WIRE.name])
  return result
end

function append(list, other)
  for _,v in pairs(other) do
    table.insert(list, v)
  end
  return list
end

function placeBlockEffecs()
  local pitch = math.random()*2
  spell:execute([[
    /playsound minecraft:block.stone.place block @a ~ ~ ~ 8 %s
  ]], pitch)
  spell:execute([[
    /particle blockcrack ~0.5 ~1 ~0.5 0.4 0.4 0.4 0 10 normal @a 4
  ]])
end

function containsAllKeys(set, elements)
  for _,e in pairs(elements) do
    if not set[e] then
      return false
    end
  end
  return true
end

function containsAnyKeys(set, elements)
  for _,e in pairs(elements) do
    if set[e] then
      return true
    end
  end
  return false
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