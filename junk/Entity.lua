local Signal = require "Signal"
local Mask = require "comps.Mask"

local Entity = oo.class()

local collideLayer, collideLayers

function Entity:init(x, y)
	self.x = x or 0
	self.y = y or 0
	self.stage = nil
	self.layer = 1
	self.active = true
	self.visible = true
	self.components = {}
	self.flags = {}
	self.data = {}
	self.mask = nil -- collision component
	self.graphics = nil -- rendering component
end

function Entity:callComponents(str, ...)
	for i, c in ipairs(self.components) do
		c[str](c, ...)
	end
end

function Entity:add(stage)
end
function Entity:remove(stage)
end
function Entity:update()
end
function Entity:draw()
end

function Entity:collide(layer, x, y, mode, modeParam)
	x, y, self.x, self.y = self.x, self.y, x, y
	local f = Mask.collideModes[mode] or Mask.collideModes.any
	local e
	if type(layer == "number") then
		e = collideLayer(f, self.stage, self.mask, layer, modeParam)
	else
		e = collideLayers(f, self.stage, self.mask, layer, modeParam)
	end
	self.x, self.y = x, y
	return e
end

function collideLayer(f, stage, mask, layer, modeParam)
	for _, e in ipairs(stage.layers[layer]) do
		if f(mask, e, modeParam) then
			return e
		end
	end
end

function collideLayers(f, stage, mask, layers, modeParam)
	for _, l in ipairs(layers) do
		for _, e in ipairs(stage.layers[l]) do
			if f(mask, e, modeParam) then
				return e
			end
		end
	end
end

return Entity