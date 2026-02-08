local _, private = ...
local data_handler = {}
private.DataHandler = data_handler

local data_managers = {}

function data_handler.RegisterDataManager(name, data_manager)
  data_managers[name] = data_manager
end

function data_handler.GetDataProvider(name)
  local data_manager = data_managers[name]
  return data_manager.get_data_provider()
end
