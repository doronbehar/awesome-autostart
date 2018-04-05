return {
	programs = {
		{
			name = 'polybar',
			delay = 1,
			bin = {'/usr/bin/polybar', 'default'},
			respawn_on_awesome_restart = true
		},
		{
			name = 'gnubifftray',
			delay = 1,
			bin = {'/usr/bin/gnubiff', '--systemtray', '--noconfigure'},
			respawn_on_awesome_restart = true
		},
		{
			name = 'redshift',
			bin = {'/usr/bin/redshift-gtk'}
		},
		{
			name = 'xautolock',
			bin = {
				'/usr/bin/xautolock',
				'-time', '7',
				'-locker', 'xlock -mode blank',
				'-notify', '10',
				'-notifier', 'notify-send --app-name=xautolock --expire-time=10000 "xautolock will lock the computer in 10 seconds of inactivity"',
			}
		}
	},
	log = {
		handler = function (self, level, nessage) 
			-- a logger function that handles the current level
		end,
		settings = {
			-- a set of parameters that define the default settings of 
		}
	}
}
