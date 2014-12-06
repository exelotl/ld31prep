local Component = require "comps.Component"

-- Masks are components that handle collision detection
-- Subclasses must have a static 'handlers' table with functions to check for collision against other masks
local Mask = oo.class(Component)

Mask.collideModes = {}

function Mask:init(entity)
	Component.init(self, entity)
	assert(self.handlers)
end

function Mask:collide(mask)
	if self.handlers[mask.type] then
		return self.handlers[mask.type](self, mask)
	end
	if mask.handlers[self.type] then
		return mask.handlers[self.type](mask, self)
	end
	return false
end

function Mask.collideModes:any(e)
	return e ~= self.entity and self:collide(e.mask)
end

function Mask.collideModes:flag(e, flag)
	return e.flags[flag]
	   and e ~= self.entity
	   and self:collide(e.mask)
end

function Mask.collideModes:allFlags(e, flags)
	for _, flag in ipairs(flags) do
		if not e.flags[flag] then
			return false
		end
	end
	return e ~= self.entity and self:collide(e.mask)
end

function Mask.collideModes:anyFlags(e, flags)
	for _, flag in ipairs(flags) do
		if e.flags[flag] then
			return e ~= self.entity and self:collide(e.mask)
		end
	end
	return false
end

function Mask.collideModes:custom(e, func)
	if e ~= self.entity and self:collide(e.mask) then
		return func(self.entity, e)
	end
end

return Mask