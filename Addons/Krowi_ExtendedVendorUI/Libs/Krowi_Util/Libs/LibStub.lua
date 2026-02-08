---@diagnostic disable: undefined-global

local libStubMajor, libStubMinor = 'LibStub', 2
local LibStub = _G[libStubMajor]
if LibStub and LibStub.minor >= libStubMinor then return end

LibStub = LibStub or {
	libs = {},
	minors = {}
}
_G[libStubMajor] = LibStub
LibStub.minor = libStubMinor

function LibStub:NewLibrary(major, minor)
	assert(type(major) == 'string', 'Bad argument #2 to \'NewLibrary\' (string expected)')
	minor = assert(tonumber(string.match(minor, '%d+')), 'Bad argument #3 to \'NewLibrary\' (version must either be a number or contain a number)')

	local oldminor = self.minors[major]
	if oldminor and oldminor >= minor then return nil end

	self.minors[major], self.libs[major] = minor, self.libs[major] or {}
	return self.libs[major], oldminor
end

function LibStub:GetLibrary(major, silent)
	if not self.libs[major] and not silent then
		error(('Cannot find a library instance of %q.'):format(tostring(major)), 2)
	end

	return self.libs[major], self.minors[major]
end

function LibStub:IterateLibraries() return pairs(self.libs) end

setmetatable(LibStub, { __call = LibStub.GetLibrary })