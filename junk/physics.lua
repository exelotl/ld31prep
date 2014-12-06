local Physics = oo.class()

function Physics:init(entity, layer, mode, modeParam)
	self.entity = entity
	self.layer = layer
	self.mode = mode or "any"
	self.modeParam = modeParam
	self.types = {}
	self.velX, self.velY = 0, 0
	self.accX, self.accY = 0, 0
	self.maxVelX, self.maxVelY = 99999, 99999
	self.dragX, self.dragY = 0, 0
	self.bounce = 0
	self.moveX, self.moveY = 0, 0
end

function Physics:update(dt)
	if self.accX == 0 then
		if self.velX < 0 then
			self.velX = math.min(self.velX + self.dragX*dt, 0)
		elseif self.velX > 0 then
			self.velX = math.max(self.velX - self.dragX*dt, 0)
		end
	else
		self.velX = self.velX + self.accX*dt
	end
	if self.velX < -self.maxVelX then
		self.velX = -self.maxVelX
	elseif self.velX > self.maxVelX then
		self.velX = self.maxVelX
	end
	
	if self.accY == 0 then
		if self.velY < 0 then
			self.velY = math.min(self.velY + self.dragY*dt, 0)
		elseif self.velY > 0 then
			self.velY = math.max(self.velY - self.dragY*dt, 0)
		end
	else
		self.velY = self.velY + self.accY*dt
	end
	if self.velY < -self.maxVelY then
		self.velY = -self.maxVelY
	elseif self.velY > self.maxVelY then
		self.velY = self.maxVelY
	end
	
	self:moveBy(self.velX*dt, self.velY*dt)
end

local function sign(n)
  return n>0 and 1 or n<0 and -1 or 0
end

-- Thanks Chevy!
function Physics:moveBy(x, y)
	local e = self.entity
	self.moveX, self.moveY = self.moveX+x, self.moveY+y
	x, y = math.floor(self.moveX+0.5), math.floor(self.moveY+0.5)
	self.moveX, self.moveY = self.moveX-x, self.moveY-y
	if x ~= 0 then
		if e:collide(self.layer, e.x+x, e.y, self.mode, self.modeParam) then
			if e:collide(self.layer, e.x-x, e.y, self.mode, self.modeParam) then
				e.flags.stuck = true
			end
			local sign = sign(x)
			while x ~= 0 do
				if e:collide(self.layer, e.x+sign, e.y, self.mode, self.modeParam) then
					self:collideX()
					break
				end
				e.x = e.x + sign
				x = x - sign
			end
		else
			e.x = e.x + x
		end
	end
	if y ~= 0 then
		if e:collide(self.layer, e.x, e.y+y, self.mode, self.modeParam) then
			local sign = sign(y)
			while y ~= 0 do
				if e:collide(self.layer, e.x, e.y+sign, self.mode, self.modeParam) then
					self:collideY()
					break
				end
				e.y = e.y + sign
				y = y - sign
			end
		else
			e.y = e.y + y
		end
	end
end

function Physics:collideX()
	self.velX = sign(self.velX) * -self.bounce
end

function Physics:collideY()
	self.velY = sign(self.velY) * -self.bounce
end

return Physics