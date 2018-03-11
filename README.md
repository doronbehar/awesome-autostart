## Awesome WM autostart module

> autostart made easy

We all know Awesome WM is a window manager and no more. What this module strives to accomplish is to provide a comfortable way to manage applications which should be started automatically when one opens a new `awesome` session.

Usually, what most users want is to define a list of system tray applications that should be started when running `startx`. Most people are satisfied with putting those shell commands in `~/.xprofile` but this has some drawbacks:

- No notifications when a program exits unexpectedly.
- The `STDOUT` of the programs is naturally printed in the tty from which `startx` was invoked, therefor - no native support for log files
- If one just restarts `awesome`, there is no solution with `~/.xprofile` for applications which need a consistent system tray handler and you want them to restart with `awesome`. (More details in [Usage](#Usage))

### Installation

Clone the repository to your awesome configuration directory.

### Usage

Import the module to your `rc.lua`:

```lua
local autostart = require('autostart')
-- ...
-- Whenever you wish, invoke the function `autostart` with your `autostart_config` object.
-- Usually, it is recommended to do so after defining all the tags, tasklist and widgets in `rc.lua`.

autostart_config = {
  -- ... More details on configuration latter ...
}

autostart(autostart_config)
```

### Configuration

A configuration for each autostart program is needed for two scenarios:

- A program needed to run with `awesome` exits when there is no system tray handler (like `awesome`'s widget `wibox.widget.systray()`). Here are some examples (tested on my machine, YMMV):
  * `gnubiff`
  * `polybar` - Sometimes prints weird things after awesome restarts.
* A program needs to be started in delay (I know you can `sleep` in your `~/.xprofile` but `awesome-autostart` strives to solve this as well more elegantly).

Here is an example of a autostart object to put in the array `autostart_config`:
```lua
{
	name = 'polybar', -- Used when creating log files, don't put here spaces or other special characters
	delay = 1, -- start in delay after awesome (re)starts
	bin = {'/usr/bin/polybar', 'default'}, -- array (or just a string) of a command and it's arguments to run for this autostart entry
	respawn_on_awesome_restart = true -- if set to true, this entry will be started with `awesome`'s restarts
}
```
A full example of a configuration file is included in the repository. You can copy it to `config.lua`, edit it and use it like this:

```lua
autostart(require('autostart/config'))
```
