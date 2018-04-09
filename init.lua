local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

pcall(require, "luarocks.loader")
local logger = require('logger')
local logger = logger(function(self, level, message)
	io.stdout:write(level .. "\t" .. message .. "\n")
	return true
end)
logger:setLevel('ERROR')

return function (config, logs_dir_path, pidfiles_dir_path)
	local logs = logs_dir_path or gears.filesystem.get_cache_dir() .. 'logs/'
	local tmp = pidfiles_dir_path or os.getenv('XDG_RUNTIME_DIR') .. '/awesome/autostart/' .. os.getenv('XDG_SESSION_ID') .. '/'
	if gears.filesystem.make_directories(logs) then
		logger:debug('Creating directories for logs: ' .. logs)
	else
		logger:fatal('Couldn\'t create directories for logs, check the permissions and existence of ' .. logs )
		return
	end
	if gears.filesystem.make_directories(tmp) then
		logger:debug('Creating directories for pid files: ' .. tmp)
	else
		logger:fatal('Couldn\'t create directories for logs, check the permissions and existence of ' .. logs )
		return
	end
	program = {}
	for i = 1,#config do
		program[i] = {}
		program[i].log_fp = logs .. config[i].name .. '.log'
		logger:debug('The log file path of ' .. config[i].name .. ' is: ' .. program[i].log_fp)
		program[i].pid_fp = tmp .. config[i].name .. '.pid'
		logger:debug('The pid file path of ' .. config[i].name .. ' is: ' .. program[i].pid_fp)
		program[i].spawn = function()
			local pid = awful.spawn.with_line_callback(config[i].bin, {
				stdout = function(line)
					program[i].log = io.open(program[i].log_fp, 'a')
					program[i].log:write(line, '\n')
				end,
				stderr = function(line)
					program[i].log = io.open(program[i].log_fp, 'a')
					program[i].log:write(line, '\n')
				end,
				exit = function(reason, code)
					if reason == 'exit' then
						logger:warn(config[i].name .. ' exited with code: ' .. code)
					elseif reason == 'signal' then
						logger:warn(config[i].name .. ' exited because it recieved signal ' .. code)
					else
						logger:warn(config[i].name .. ' exited with unknown reason: ' .. code)
					end
					if os.remove(program[i].pid_fp) then
						logger:debug('Succesfully removed pid file for ' .. config[i].name)
					else
						logger:warn('Failed to remove pid file for ' .. config[i].name, {err = true})
					end
				end
			})
			program[i].pid = io.open(program[i].pid_fp, 'w')
			program[i].pid:write(pid)
			program[i].pid:close()
		end
	end
	for i = 1,#config do
		if config[i].delay then
			spawn_this = function()
				logger:debug('Creating timer for configured with delay autostart program ' .. config[i].name)
				program[i].timer = gears.timer({
					timeout = config[i].delay,
					callback = program[i].spawn,
					single_shot = true
				})
				program[i].timer:start()
			end
		else
			spawn_this = program[i].spawn
		end
		if gears.filesystem.file_readable(program[i].pid_fp) then
			if config[i].respawn_on_awesome_restart == true then
				program[i].pid = io.open(program[i].pid_fp, 'r')
				local pid = program[i].pid:read("*n")
				logger:debug('pid of ' .. config[i].name .. ' is: ' .. pid)
				if awesome.kill(pid, awesome.unix_signal['SIGTERM']) then
					os.remove(program[i].pid_fp)
				else
					logger:info('killing ' .. config[i].name .. ' failed' )
				end
				spawn_this()
			end
		else
			spawn_this()
		end
	end
end
