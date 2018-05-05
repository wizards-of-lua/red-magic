-- red-magic/wol/Spell.lua


function Spell:singleton(name)
  spell:execute('wol spell break byName "%s"', name)
  spell.name = name
end
