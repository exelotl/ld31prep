local Sound = {}

local sfx

function Sound.play(name, vol, pitch)
	vol = vol or 1
	pitch = pitch or 1
	if sfx and sfx[name] then
		local s = sfx[name]
		s:stop()
		s:setVolume(vol)
		s:setPitch(pitch)
		s:play()
	end
end

if love.audio then
	sfx = {
		MINE_BLOCK_1 = love.audio.newSource("assets/sfx/mine_block_1.wav", "static"),
		MINE_BLOCK_2 = love.audio.newSource("assets/sfx/mine_block_2.wav", "static"),
		MINE_BLOCK_3 = love.audio.newSource("assets/sfx/mine_block_3.wav", "static"),
		ITEM_PICKUP = love.audio.newSource("assets/sfx/item_pickup.wav", "static"),
	}
end

return Sound