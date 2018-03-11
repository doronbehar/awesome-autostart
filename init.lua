local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

pcall(require, "luarocks.loader")
local logging = require('logging')
local logger = logging.new(function(self, level, message)
	io.stdout:write(logging.prepareLogMsg(logPattern, os.date(), level, message))
	return true
end)

return function (config, verbosity, logs_dir_path, pidfiles_dir_path)
	local logs = logs_dir_path or gears.filesystem.get_cache_dir() .. 'logs/'
	local tmp = pidfiles_dir_path or os.getenv('XDG_RUNTIME_DIR') .. '/awesome/autostart/' .. os.getenv('XDG_SESSION_ID') .. '/'
	if gears.filesystem.make_directories(logs) then
		if verbosity == 2 then
			logger:debug('Creating directories for logs: ' .. logs)
		end
	else
		logger:fatal('Couldn\'t create directories for logs, check the permissions and existence of ' .. logs )
		return
	end
	if gears.filesystem.make_directories(tmp) then
		if verbosity == 2 then
			logger:debug('Creating directories for pid files: ' .. tmp)
		end
	else
		logger:fatal('Couldn\'t create directories for logs, check the permissions and existence of ' .. logs )
		return
	end
	program = {}
	for i = 1,#config do
		program[i] = {}
		program[i].log_fp = logs .. config[i].name .. '.log'
		if verbosity == 2 then
			logger:debug('The log file path of ' .. config[i].name .. ' is: ' .. program[i].log_fp)
		end
		program[i].pid_fp = tmp .. config[i].name .. '.pid'
		if verbosity == 2 then
			logger:debug('The pid file path of ' .. config[i].name .. ' is: ' .. program[i].pid_fp)
		end
		program[i].spawn = function()
			local pid = awful.spawn.with_line_callback(config[i].bin, {
				stdout = function(line)
					program[i].log = io.open(program[i].log_fp, 'a')
					program[i].logger:write(line, '\n')
				end,
				stderr = function(line)
					program[i].log = io.open(program[i].log_fp, 'a')
					program[i].logger:write(line, '\n')
				end,
				exit = function(reason, code)
					if reason == 'exit' then
						logger:info(config[i].name .. ' exited with code: ' .. code)
					elseif reason == 'signal' then
						logger:info(config[i].name .. ' exited because it recieved signal ' .. code)
					else
						logger:info(config[i].name .. ' exited with unknown reason: ' .. code)
					end
					if os.remove(program[i].pid_fp) then
						if verbosity == 2 then
							logger:debug('Succesfully removed pid file for ' .. config[i].name)
						end
					else
						logger:info('Failed to remove pid file for ' .. config[i].name, {err = true})
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
				if verbosity == 2 then
					logger:debug('Creating timer for configured with delay autostart program ' .. config[i].name)
				end
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
				if verbosity == 2 then
					logger:debug('pid of ' .. config[i].name .. ' is: ' .. pid)
				end
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
