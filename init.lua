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
	ret.spawn = function(prog, pid_fp)
		if prog.delay then
			ret.logger:debug('Creating timer for configured with delay autostart program ' .. prog.name)
			local timer = gears.timer({
				timeout = prog.delay,
				callback = function()
					prog.delay = false
					ret.spawn(prog, pid_fp)
				end,
				single_shot = true
			})
			timer:start()
		else
			local pid = awful.spawn.with_line_callback(prog.bin, {
				stdout = function(line)
					ret.logger:info(prog.name .. ':' .. line)
				end,
				stderr = function(line)
					ret.logger:error(prog.name .. ':' .. line)
				end,
				exit = function(reason, code)
					if reason == 'exit' then
						ret.logger:warn(prog.name .. ' exited with code: ' .. code)
					elseif reason == 'signal' then
						ret.logger:warn(prog.name .. ' exited because it recieved signal ' .. code)
					else
						ret.logger:warn(prog.name .. ' exited with unknown reason: ' .. code)
					end
					if os.remove(pid_fp) then
						ret.logger:debug('Succesfully removed pid file for ' .. prog.name)
					else
						ret.logger:warn('Failed to remove pid file for ' .. prog.name)
					end
				end
			})
			if type(pid) == "string" then
				ret.logger:fatal(pid)
				return pid
			end
			local pid_file = io.open(pid_fp, 'w')
			pid_file:write(pid)
			pid_file:close()
			awesome.connect_signal("exit", function(reason_restart)
				local pid_file = io.open(pid_fp, 'r')
				local pid = pid_file:read("*n")
				ret.logger:debug('pid of ' .. prog.name .. ' is: ' .. pid)
				-- usefull only when having patch:
				-- https://github.com/awesomeWM/awesome/commit/b3311674d2073a0fdea35f033dcc06d6373d4873.patch
				if awesome.kill(-pid, awesome.unix_signal['SIGTERM']) then
					pid_file:close()
					if os.remove(pid_fp) then
						ret.logger:debug('Succesfully removed pid file for ' .. prog.name)
					else
						ret.logger:warn('Failed to remove pid file for ' .. prog.name)
					end
				else
					ret.logger:info('killing ' .. prog.name .. '(pid ' .. pid .. ') failed' )
				end
				if reason_restart and prog.respawn_on_awesome_restart then
					ret.spawn(prog, pid_fp)
				end
			end)
		end
	end
	ret.run_all = function()
		for i = 1,#config.programs do
			local pid_fp = config.programs[i].pid_fp or config.pids_path .. config.programs[i].name .. '.pid'
			ret.logger:debug('The pid file path of ' .. config.programs[i].name .. ' is: ' .. pid_fp)
			ret.spawn(config.programs[i], pid_fp)
		end
	end
	return ret
end

return autostart
