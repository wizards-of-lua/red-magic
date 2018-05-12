-- red-magic/wol/Vec3.lua

function Vec3:coords()
  return math.floor(self.x) .. ' ' .. math.floor(self.y) .. ' ' .. math.floor(self.z)
end

