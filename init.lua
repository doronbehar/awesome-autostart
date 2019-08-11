local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local basename = require('posix.libgen').basename
-- * for debugging
--local inspect = require('pl.import_into')().pretty.write

pcall(require, "luarocks.loader")
-- https://gitlab.com/doronbehar/lua-logger
local Logger = require('logger')

local Autostart = {}
function Autostart:new(config)
	if type(config) ~= 'table' then
		config = {}
	end
	setmetatable(config, {
		__index = {
			programs = {
				{
					bin = {'/bin/echo', 'no autostart program was configured!'},
				}
			},
			log = {
				handler = function(self, level, message)
					io.stdout:write(level .. '\t' .. message .. '\n')
				end,
			},
			pids_path = os.getenv('XDG_RUNTIME_DIR') .. '/awesome/autostart/' .. os.getenv('XDG_SESSION_ID') .. '/'
		}
	})
	o = {
		config = config,
		logger = Logger(config.log.handler, config.log.settings),
		-- table that will save pid
		pids = {}
	}
	setmetatable(o, self)
	self.__index = self
	return o
end
function Autostart:spawn(prog)
	if not prog.name then
		if type(prog.bin) == "table" then
			prog.name = basename(prog.bin[1])
		elseif type(prog.bin) == "string" then
			prog.name = basename(prog.bin)
		end
	end
	local logger
	if prog.log then
		setmetatable(prog.log, {
			__index = self.config.log
		})
		logger = Logger(prog.log.handler, prog.log.settings)
	else
		logger = self.logger
	end
	if prog.delay then
		logger:debug('Creating timer for configured with delay autostart program ' .. prog.name)
		local timer = gears.timer({
			timeout = prog.delay,
			callback = function()
				prog.delay = false
				self:spawn(prog)
			end,
			single_shot = true
		})
		return timer:start()
	end
	if self.pids[prog.name] then
		return "pid for such a program already exists: " .. tostring(self.pids[prog.name])
	end
	local pid = awful.spawn.with_line_callback(prog.bin, {
		stdout = function(line)
			logger:info(prog.name .. ':' .. line)
		end,
		stderr = function(line)
			logger:error(prog.name .. ':' .. line)
		end,
		exit = function(reason, code)
			if reason == 'exit' then
				logger:warn(prog.name .. ' exited with code: ' .. code)
			elseif reason == 'signal' then
				logger:warn(prog.name .. ' exited because it recieved signal ' .. code)
			else
				logger:warn(prog.name .. ' exited with unknown reason: ' .. code)
			end
			self.pids[prog.name] = nil
		end
	})
	if type(pid) == "string" then
		logger:fatal(pid)
		return pid
	end
	-- otherwise, we save the pid in our self.pids table
	self.pids[prog.name] = pid
	awesome.connect_signal("exit", function(reason_restart)
		logger:debug('pid of ' .. prog.name .. ' is: ' .. self.pids[prog.name])
		-- usefull only when having patch:
		-- https://github.com/awesomeWM/awesome/commit/b3311674d2073a0fdea35f033dcc06d6373d4873.patch
		if awesome.kill(-self.pids[prog.name], awesome.unix_signal['SIGTERM']) then
			logger:debug('Succesfully killed ' .. prog.name)
		else
			logger:info('killing ' .. prog.name .. '(pid ' .. pid .. ') failed' )
		end
	end)
end
function Autostart:is_running(name)
	return self.pids[name]
end
function Autostart:kill_by_name(name)
	return awesome.kill(-self.pids[name], awesome.unix_signal['SIGTERM'])
end
function Autostart:run_all()
	for _, prog in ipairs(self.config.programs) do
		self:spawn(prog)
	end
end

return Autostart
