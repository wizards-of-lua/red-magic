-- red-magic/giantspruce.lua

-- /lua require('red-magic.giantspruce').start()

local module = ...
require 'mickkay.wol.Spell'
local pkg = {}

local ASYNC_EVENT = module..".async.event"
local REQUIRED_ITEMS = {"sapling","dye"}
local REQUIRED_SIGIL = {
--[[
  { 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 2, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 2 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0 }
]]--
  { 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 2, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 2 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
  { 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2 }
}

local handle
local beam
local disc

local checkRune
local log

function pkg.handler()
  local handler = {
    requiredItems = REQUIRED_ITEMS,
    handle = function(data)
      local canHandle = false
      local countSapling = 0
      local countBone = 0
      for _,item in pairs(data.items) do
        if item.id == "sapling" and item.damage == 1 then
          countSapling = countSapling + item.count
        end
        if item.id == "dye" and item.damage == 15 then
          countBone = countBone + item.count
        end
      end
--      log("found "..countSapling.." saplings and "..countBone.." bone meal")
      if countSapling >= 5 and countBone >= 64 then canHandle = true end
      if canHandle then
        Events.fire(ASYNC_EVENT,data)
--        log(module.." cast")
      end
      return canHandle
    end
  }
  return handler
end

function pkg.start()
  --log("started")
  spell:singleton(module)
  local queue = Events.collect(ASYNC_EVENT)
  while true do
    local event = queue:next()
    handle(event.data)
  end
end

function handle(data)
  --log("checking rune")
  if checkRune(data.positions.redstone_ore[1], data.positions, REQUIRED_SIGIL) == false then
    return
  end

  --log("building tree")
  local c = data.positions.redstone_ore[1] + Vec3(0.5, 0, 0.5)

  local d = 15
  local h = 32
  local e = 8

  local o
  local t = c + Vec3(0, h, 0)
  local b = Blocks.get('log'):withData({variant='spruce',axis='none'})

  o = c + Vec3( 0,-1, 0)
  beam(o,t,b)
  o = c + Vec3( 1, 0, 0)
  beam(o,t,b)
  o = c + Vec3(-1, 0, 0)
  beam(o,t,b)
  o = c + Vec3( 0, 0, 1)
  beam(o,t,b)
  o = c + Vec3( 0, 0,-1)
  beam(o,t,b)

  local i, r
  for i = 2, 7 do
    r = 9
    o = c + Vec3( 0, i*4, 0)
    t = o + Vec3( r-i, 0, 0)
    beam(o,t,b)
    t = o + Vec3( -(r-i), 0, 0)
    beam(o,t,b)
    t = o + Vec3( 0, 0, r-i)
    beam(o,t,b)
    t = o + Vec3( 0, 0, -(r-i))
    beam(o,t,b)
    if i < 6 then
      t = o + Vec3( 0.7*(r-i), 0, 0.7*(r-i))
      beam(o,t,b)
      t = o + Vec3(-0.7*(r-i), 0, 0.7*(r-i))
      beam(o,t,b)
      t = o + Vec3( 0.7*(r-i), 0,-0.7*(r-i))
      beam(o,t,b)
      t = o + Vec3(-0.7*(r-i), 0,-0.7*(r-i))
      beam(o,t,b)
    end
  end

  b = Blocks.get('leaves'):withData({variant='spruce'})

  for i = h, 6, -1 do
    o = c + Vec3( 0, i, 0)
    r = (37-i)/4
    if i < 8 then r = i end
    disc(o, r, b)
  end

end

function beam(origin, target, block)

	local delta = target - origin
	local distance = delta:magnitude()
	delta = delta * (1 / distance)

	local pos = origin
	for i = 1, distance-1 do
		pos = pos + delta
		spell.pos = pos
    spell.block = block
	end

end

function disc(origin, radius, block)

	local radius_sqr0 = (radius-1) * (radius-1) - 1
	local radius_sqr1 = radius * radius - 1
	local corner = origin + Vec3(radius, radius, radius)

	local x, y, z, delta, distance_sqr

	local y = origin.y
	for x = origin.x, corner.x do
		for z = origin.z, corner.z do

			local delta = Vec3(x, y, z) - origin
			local distance_sqr = (delta.x * delta.x) + (delta.z * delta.z)

			if distance_sqr <= radius_sqr1 then
  			spell.pos = Vec3(x, y, z); if spell.block.material.solid == false then spell.block = block end
  			spell.pos = origin + Vec3(-delta.x, 0,  delta.z) if spell.block.material.solid == false then spell.block = block end
  			spell.pos = origin + Vec3( delta.x, 0, -delta.z) if spell.block.material.solid == false then spell.block = block end
  			spell.pos = origin + Vec3(-delta.x, 0, -delta.z) if spell.block.material.solid == false then spell.block = block end
  		end

		end
	end

end

function checkRune(center, blocks, pattern)
  local w = #pattern
  local h = #pattern[1]
  local center = center + Vec3(-9,0,-9)

  local sigil = {}

  for x = 1, w do
    sigil[x] = {}
    for z = 1, h do
      sigil[x][z] = 0
    end
  end

  local i, r
  
  if blocks.redstone_wire then
    for i = 1, #blocks.redstone_wire do
      r = blocks.redstone_wire[i] - center
      if 1 <= r.x and r.x <= w and 1 <= r.z and r.z <= h then
        sigil[r.x][r.z] = 1
      end
    end
  end
  if blocks.redstone_torch then
    for i = 1, #blocks.redstone_torch do
      r = blocks.redstone_torch[i] - center
      if 1 <= r.x and r.x <= w and 1 <= r.z and r.z <= h then
        sigil[r.x][r.z] = 2
      end
    end
  end

--  log(str(sigil))

  local x, z
  local valid = true

  for x = 1, w do
    for z = 1, h do
      if sigil[x][z] ~= pattern[x][z] then
        valid = false
      end
    end
  end

  return valid
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