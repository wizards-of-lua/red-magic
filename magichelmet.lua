-- red-magic/magichelmet.lua

-- TODO add damage to helmet at every use

-- /lua require("red-magic.magichelmet").start()
-- /lua require("red-magic.magichelmet").giveItem()
local module = ...
require "mickkay.wol.Spell"

local pkg = {}
local VISUALIZER_MODULE= 'claiming.claimvisualizer'
local CLAIMING_SPELL_NAME = 'claiming.claiming'

local ITEM_CODE = "Magic Helmet"
local ITEM_DISPLAY_NAME = "Magic Helmet"
local DURABILITY = 77
local USE_DELAY = 20*4

local log
local getMagicItem
local isMagicItemNbt
local addDamage
local getHelmetNbt
local lastUsed = {}

function pkg.giveItem(entity,count)
  entity = entity or spell.owner
  count = count or 1
  local item = Items.get("golden_helmet")
  item:putNbt( {
    tag= {
      MagicItem = ITEM_CODE,
      ench= {{id=999, lvl=1}}
    }
  })
  item.displayName = ITEM_DISPLAY_NAME
  entity:dropItem(item,count)
end

function pkg.start()
  spell:singleton( module)
  local claiming = require(CLAIMING_SPELL_NAME).get()
  if not claiming then
    error("Can't find claiming spell")
  end

  local queue = Events.collect("SwingArmEvent")
  while true do
    local event = queue:next()
    local player = event.player
    if not lastUsed[player.name] or lastUsed[player.name] + USE_DELAY < Time.gametime then
      
      local helmetNbt = getHelmetNbt(player)
      if helmetNbt and isMagicItemNbt(helmetNbt) then
      --local item = getMagicItem(player)
      --if item then
        local center = claiming:getNearestClaim(player)
        if center then
          local width = claiming:getWidth()
          spell:execute([[
            lua require('%s').showBorders('%s', Vec3(%s,%s,%s),%s)
          ]], VISUALIZER_MODULE, player.name, center.x, center.y, center.z, width)
          lastUsed[player.name] = Time.gametime
        --addDamage(item,1)
        end
      end
    end
  end
end

function pkg.stop()
  spell:singleton(module)
end

function getMagicItem( player)
  local item = player.mainhand
  if item and isMagicItemNbt(item.nbt) then
    --log("item.damage=%s",item.damage)
    if item.damage > DURABILITY then
      player.mainhand = nil
      item = nil
    end
    return item
  else
    return nil
  end
end

function isMagicItemNbt( nbt)
  return nbt and nbt.tag and nbt.tag.MagicItem == ITEM_CODE
end

function addDamage(item, amount)
  item.damage = item.damage + 1
end

function getHelmetNbt(player)
  local inventory=player.nbt.Inventory
  if inventory ~= nil then
    for _,inv in pairs(inventory) do
      if inv.Slot==103 then
        return inv
      end
    end
  end
  return nil
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