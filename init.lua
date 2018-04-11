local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

pcall(require, "luarocks.loader")
local Logger = require('logger')

local inspect = require('inspect')

local autostart = {}
autostart.new = function(config)
	local ret = {}
	if type(config) ~= 'table' then
		config = {}
	end
	-- Setting must values for config object through __index metatable value.
	setmetatable(config, {
		__index = {
			programs = {
				{
					name = 'non',
					bin = {'/bin/echo', 'no autostart program was configured!'},
					respawn_on_awesome_restart = true
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
	ret.logger = Logger(config.log.handler, config.log.settings)
	if gears.filesystem.make_directories(config.pids_path) then
		ret.logger:debug('Creating directories for pid files: ' .. config.pids_path)
	else
		ret.logger:fatal('Couldn\'t create directories for logs, check the permissions and existence of ' .. config.log.dir_path)
		return nil, 'Couldn\'t create directories for logs, check the permissions and existence of ' .. config.log.dir_path
	end
	ret.run = function(prog)
		local logger
		if type(prog.log) == 'table' then
			logger = Logger(prog.log.handler, prog.log.settings)
		else
			logger = ret.logger
		end
		local pid_fp = prog.pid_fp or config.pids_path .. prog.name .. '.pid'
		logger:debug('The pid file path of ' .. prog.name .. ' is: ' .. pid_fp)
		prog.spawn = function()
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
					if os.remove(pid_fp) then
						logger:debug('Succesfully removed pid file for ' .. prog.name)
					else
						logger:warn('Failed to remove pid file for ' .. prog.name)
					end
				end
			})
			local pid_file = io.open(pid_fp, 'w')
			pid_file:write(pid)
			pid_file:close()
		end
		if prog.delay then
			prog.spawn_this = function()
				logger:debug('Creating timer for configured with delay autostart program ' .. prog.name)
				prog.timer = gears.timer({
					timeout = prog.delay,
					callback = prog.spawn,
					single_shot = true
				})
				prog.timer:start()
			end
		else
			prog.spawn_this = prog.spawn
		end
		if gears.filesystem.file_readable(pid_fp) then
			if prog.respawn_on_awesome_restart == true then
				local pid_file = io.open(pid_fp, 'r')
				local pid = pid_file:read("*n")
				logger:debug('pid of ' .. prog.name .. ' is: ' .. pid)
				if awesome.kill(pid, awesome.unix_signal['SIGTERM']) then
					os.remove(pid_fp)
				else
					logger:info('killing ' .. prog.name .. ' failed' )
				end
				prog.spawn_this()
			end
		else
			logger:error('The pid file of ' .. prog.name .. ' was not found!')
			prog.spawn_this()
		end
	end
	ret.run_all = function()
		for i = 1,#config.programs do
			ret.run(config.programs[i])
		end
	end
	return ret
end

return autostart
