--[[ red-magic/startup.lua

Name:           Red Magic
Version:        1.0.0
Homepage:       https://github.com/wizards-of-lua/red-magic
Authors:        mickkay, bytemage, MrNickKay
Copyright:      2018, The Wizards of Lua
License:        GPL 3.0
Dependencies:   wol-1.12.2-2.0.2
                claiming-1.0.0 [https://github.com/wizards-of-lua/claiming] 

You can use this startup script to activate the Red Magic spell pack on your server.
Just execute it from your server's startup script, for example like this:

  spell:execute("/lua require('red-magic.startup')")
  
  
The Red Magic Spell Pack is dependent on the Claiming Spell Pack.
Please make sure to start the Claiming Spell Pack before you 
start this spell pack.

]]--

-- TODO Red Skull 
--spell:execute("/lua require('mickkay.redskull').start()")

-- Runes Spell
spell:execute([[
  /lua require('red-magic.runes').start( {
    require('red-magic.wallrune').handler(),
    require('red-magic.giantspruce').handler()
  })
]])

-- The Wall Rune
spell:execute("/lua require('red-magic.wallrune').start()")

-- The Giant Spruce Rune
spell:execute("/lua require('red-magic.giantspruce').start()")

-- The Hammer
spell:execute("/lua require('red-magic.hammer').start()")

-- The Lumber Axe
spell:execute("/lua require('red-magic.lumberaxe').start()")

-- The Magic Hoe
spell:execute("/lua require('red-magic.magichoe').start()")

-- The Magic Helmet
spell:execute("/lua require('red-magic.magichelmet').start()")

-- The Key Carrot
spell:execute("/lua require('red-magic.keycarrot').start()")

-- The Red Cauldron
spell:execute([[
  /lua local receipies = {
    { input = "golden_axe", 
      xp = 7,
      action = function(e)
        require("red-magic.lumberaxe").giveItem(e)
      end
    },
    { input = "golden_pickaxe",
      xp = 7,
      action = function(e)
        require("red-magic.hammer").giveItem(e)
      end
    },
    { input = "golden_pickaxe",
      xp = 7,
      action = function(e)
        require("red-magic.hammer").giveItem(e)
      end
    },
    { input = "golden_hoe",
      xp = 7,
      action = function(e)
        require("red-magic.magichoe").giveItem(e)
      end
    },
    { input = "golden_helmet",
      xp = 7,
      action = function(e)
        require("red-magic.magichelmet").giveItem(e)
      end
    },
    { input = "golden_carrot",
      xp = 7,
      action = function(e)
        require("red-magic.keycarrot").giveItem(e)
      end
    },
    { input = "chicken",
      xp = 1,
      action = function(e)
        spell:execute('/summon chicken ~0.5 ~0.5 ~0.5 {ActiveEffects:[{Id:25,Amplifier:5,Duration:20,ShowParticles:0b}]}')
      end
    }
  }
  print("receipies", str(receipies))
  require('red-magic.redcauldron').start(receipies)
]])

