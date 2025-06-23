local E = select(2, ...):unpack()

local ObjectPoolMixin = {}

function ObjectPoolMixin:OnLoad(creationFunc, resetterFunc, initializeFunc)
	self.creationFunc = creationFunc
	self.resetterFunc = resetterFunc
	self.initializeFunc = initializeFunc

	self.allObjects = {}
	self.activeObjects = {}
	self.inactiveObjects = {}
	self.numAllObjects = 0
	self.numActiveObjects = 0
end

function ObjectPoolMixin:Acquire()
	local numInactiveObjects = #self.inactiveObjects
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects]
		self.activeObjects[obj] = true
		self.numActiveObjects = self.numActiveObjects + 1
		self.inactiveObjects[numInactiveObjects] = nil
		return obj, false
	end

	local newObj = self.creationFunc(self)
	if self.initializeFunc then
		self.initializeFunc(self, newObj)
	end
	self.activeObjects[newObj] = true
	self.numActiveObjects = self.numActiveObjects + 1

	self.allObjects[newObj] = true
	self.numAllObjects = self.numAllObjects + 1
	return newObj, true
end

function ObjectPoolMixin:Release(obj)
	assert(self.activeObjects[obj])

	self.inactiveObjects[#self.inactiveObjects + 1] = obj
	self.activeObjects[obj] = nil
	self.numActiveObjects = self.numActiveObjects - 1
	if self.resetterFunc then
		self.resetterFunc(self, obj)
	end
end

function ObjectPoolMixin:ReleaseAll()
	for obj in pairs(self.activeObjects) do
		self:Release(obj)
	end
end

function ObjectPoolMixin:HideAll()
	for obj in pairs(self.activeObjects) do
		obj:Hide()
	end
end

function ObjectPoolMixin:EnumerateActive()
	return pairs(self.activeObjects)
end

function ObjectPoolMixin:GetNextActive(current)
	return (next(self.activeObjects, current))
end

function ObjectPoolMixin:GetNumActive()
	return self.numActiveObjects
end

function ObjectPoolMixin:EnumerateInactive()
	return ipairs(self.inactiveObjects)
end

function ObjectPoolMixin:EnumerateAll()
	return pairs(self.allObjects)
end

function ObjectPoolMixin:GetNumAll()
	return self.numAllObjects
end

function E:CreateObjectPool(creationFunc, resetterFunc)
	local objectPool = CreateFromMixins(ObjectPoolMixin)
	objectPool:OnLoad(creationFunc, resetterFunc)
	return objectPool
end

local FramePoolMixin = Mixin({}, ObjectPoolMixin)

local function FramePoolFactory(framePool)
	return CreateFrame(framePool.frameType, nil, framePool.parent, framePool.frameTemplate)
end

function FramePoolMixin:OnLoad(frameType, parent, frameTemplate, resetterFunc, initializeFunc)
	ObjectPoolMixin.OnLoad(self, FramePoolFactory, resetterFunc, initializeFunc)
	self.frameType = frameType
	self.parent = parent
	self.frameTemplate = frameTemplate
end

local function FramePool_Hide(framePool, frame)
	frame:Hide()
end

local function FramePool_HideAndClearAnchors(framePool, frame)
	frame:Hide()
	frame:ClearAllPoints()
end

function E:CreateFramePool(frameType, parent, frameTemplate, resetterFunc, initializeFunc)
	local framePool = CreateFromMixins(FramePoolMixin)
	framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or FramePool_HideAndClearAnchors, initializeFunc)
	return framePool
end
