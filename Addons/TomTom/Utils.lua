--[[--------------------------------------------------------------------------
--  TomTom - A navigational assistant for World of Warcraft
----------------------------------------------------------------------------]]

local addonName, addon = ...

local twopi = math.pi * 2

function addon:ColorGradient(perc, ...)
	local num = select("#", ...)
	local hexes = type(select(1, ...)) == "string"

	if perc == 1 then
		return select(num-2, ...), select(num-1, ...), select(num, ...)
	end

	num = num / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2
	r1, g1, b1 = select((segment*3)+1, ...), select((segment*3)+2, ...), select((segment*3)+3, ...)
	r2, g2, b2 = select((segment*3)+4, ...), select((segment*3)+5, ...), select((segment*3)+6, ...)

	if not r2 or not g2 or not b2 then
		return r1, g1, b1
	else
		return r1 + (r2-r1)*relperc,
		g1 + (g2-g1)*relperc,
		b1 + (b2-b1)*relperc
	end
end

function addon:GetSpriteRotateTexCoordsResolver(texW, texH, frameW, frameH, cols, rows, numFrames, paddingH, paddingV)
    -- Create a closure for texcoords resolution
    if not numFrames then
       numFrames = cols * rows
    end

    paddingH = paddingH or 0
    paddingV = paddingV or 0

    return function(angle)
        local cell = floor(angle / twopi * numFrames + 0.5) % numFrames
        local column = cell % cols
        local row = math.floor(cell  / cols)

        local left = ((column * frameW) + paddingH) / texW
        local right = (((column + 1) * frameW) - paddingH) / texW
        local top = ((row * frameH) + paddingV) / texH
        local bottom = (((row + 1) * frameH) + paddingV) / texH
        return left, right, top, bottom
    end
end

function addon:GetSpriteAnimationTexCoordsResolver(texW, texH, frameW, frameH, cols, rows, numFrames)
    -- Create a closure for texcoords resolution
    if not numFrames then
       numFrames = cols * rows
    end

    return function(cell)
        -- Clamp the cell to the limit and return the clamped value
        cell = cell % numFrames

        local column = cell % cols
        local row = math.floor(cell  / cols)

        local left = (column * frameW) / texW
        local right = ((column + 1) * frameW) / texW
        local top = (row * frameH) / texH
        local bottom = ((row + 1) * frameH) / texH
        return left, right, top, bottom, cell
    end
end
