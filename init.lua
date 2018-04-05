local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

pcall(require, "luarocks.loader")
local logging = require('log4l')

return function (config)
	local obj = {}
	obj.start = function()
		-- Operate on config.programs
	end
	obj.logger = logging.new(config.log.handler, config.log.settings)
	return obj
end
