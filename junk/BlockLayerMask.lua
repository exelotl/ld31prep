local Mask = require "comps.Mask"

local BlockLayerMask = oo.class(Mask, {
	type = "BlockLayerMask",
	handlers = {}
})

function BlockLayerMask:init(blockLayerEntity, world)
	Mask.init(self, blockLayerEntity)
	self.world = world
	self.antiStick = {}
end

function BlockLayerMask:update()
	--for str, n in pairs(self.antiStick) do
	--	self.antiStick[str] = n >= 0 and n-1 or nil
	--end
end

function BlockLayerMask.handlers:Hitbox(box)
	local e = box.entity
	local left = e.x + box.x
	local top = e.y + box.y
	local right = left + box.width
	local bottom = top + box.height
	left, top = math.floor((left-1)/TILE_SIZE) + 1, math.floor((top-1)/TILE_SIZE) + 1
	right, bottom = math.floor((right-1)/TILE_SIZE) + 1, math.floor((bottom-1)/TILE_SIZE) + 1
	
	for x=left, right do
		for y=top, bottom do
			if self.world:getBlockState(x, y) ~= 0 and not self.antiStick[x.."_"..y] then
				--if e.flags.stuck and e.physics and e.physics.velX ~= 0 then
				--	e.flags.stuck = false
				--	self:disableArea(left, right, top, bottom, e)
				--end
				return true
			end
		end
	end
	return false
end

function BlockLayerMask:disableArea(left, right, top, bottom, e)
	for x=left, right do
		for y=top, bottom do
			self.antiStick[x.."_"..y] = e
		end
	end
end

return BlockLayerMask