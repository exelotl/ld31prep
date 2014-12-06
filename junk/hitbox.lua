local Hitbox = oo.class({
	type = "Hitbox",
	handlers = {}
})

function Hitbox:init(entity, x, y, w, h)
	self.entity = entity
	self.x = x
	self.y = y
	self.width = w
	self.height = h
end

function Hitbox.handlers:Hitbox(mask)
	local left, top = self.entity.x + self.x, self.entity.y + self.y
	local eLeft, eTop = mask.entity.x + mask.x, mask.entity.y + mask.y
	return left + self.width > eLeft
	   and top + self.height > eTop
	   and left < eLeft + mask.width
	   and top < eTop + mask.height
end

return Hitbox