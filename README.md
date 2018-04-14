# Awesome WM autostart module

> autostart made easy

### Motivation

[Awesome WM](http://awesomewm.org/) is a window manager and no more. This module strives to provide a comfortable way to manage applications which should be started automatically when one opens a new `awesome` session.

Usually, what most users want is to define a list of system tray applications that should be started when running `startx`. Most people are satisfied with putting those shell commands in `~/.xprofile` but this has some drawbacks:

- No notifications when a program exits unexpectedly.
- The `STDOUT` of the programs is naturally printed in the tty from which `startx` was invoked, meaning there's no native support for log files / desktop notifications for messages which those programs usually print to the tty's `STDERR`.
- With `~/.xprofile`, if you restart `awesome`, there is no way to tell an applications which need a consistent system tray handler you want to restart it **together** with `awesome` and perhaps even after a small delay. (More details about this specific problem and it's solution  in [Usage](#Usage))

### Installation

I recommend most people to just clone it to your `awesome` configuration dir (usually `~/.config/awesome`) and it should be usable right after you configure it as explained in more details later on. There is one dependency though which is [`lua-logger`](https://github.com/doronbehar/lua-logger) so **Remember to [install](https://github.com/doronbehar/lua-logger#installation) it as well and keep it updated as long as you keep updating this repo as well.**

### Usage

Import the module to your `rc.lua`:

```lua
local Autostart = require('autostart')
-- ...
-- Whenever you wish, invoke the function `autostart` with your `autostart_config` table.
-- Usually, it is recommended to do so after defining all the tags, tasklist and widgets in `rc.lua`.

autostart_config = {
  -- ... More details on configuration latter ...
}

local autostarter = Autostart(autostart_config)
autostarter.run_all()
```

### Configuration

#### Abstract

First of all, the configuration consists of two sections and it can look like:

```lua
return {
  programs = {
    -- array of a table for each program as explaind later on
  }
  log = {
    handler = function (self, level, message) 
      -- a logger function that handles the log info and outputs it to the
      -- console, the desktop session or to a file, your choice.
      -- If you don't feel creative enough to create something usefull here,
      -- you can check the examples in the repositories dir `examples/`.
    end,
    settings = {
      -- a set of parameters that define the default settings of the logger table
      -- More detailes later on..
    }
  }
}
```

#### Configuring Programs
A configuration for each autostart program is needed for two scenarios:

- A program needed to run with `awesome` exits when there is no system tray handler (like `awesome`'s widget `wibox.widget.systray()`). Here are some examples (tested on my machine, YMMV):
  * `gnubiff`
  * `polybar` - Sometimes prints weird things after awesome restarts.
* A program needs to be started in delay (I know you can `sleep` in your `~/.xprofile` but `awesome-autostart` strives to solve this as well more elegantly).
* A program needs to run and quit but you want still to know if it exited with non-zero value.

Here is an example of a `programs` table to put in `autostart_config` table to give as an argument to `autostart()`:

```lua
programs = {
  name = 'polybar', -- Used when creating log files, don't put here spaces or other special characters
  delay = 1, -- start in delay after awesome (re)starts
  bin = {'/usr/bin/polybar', 'default'}, -- array (or just a string) of a command and it's arguments to run for this autostart entry
  respawn_on_awesome_restart = true -- if set to true, this entry will be started with `awesome`'s restarts
}
```

Here is another example of program with the `oneshot` variable set to `true`:

```lua
{
  name = 'xradnr-fix',
  bin = {'/usr/bin/xrandr', '--output', 'HDMI1', '--left-of', 'VGA1'},
  oneshot = true -- Specifies that this autstart program should not be expected to run continuously
}
```

#### Configuring the `log`

The `autostart` module depends on a library I forked which is now called [lua-logger](http://github.com/doronbehar/lua-logger). The `log` table's `handler` function and the `settings` table are meant to become the input of the Logger constructor as explained [here](http://github.com/doronbehar/lua-logger#usage).

The `log` table should consist of a function called `handler` and a `settings` table. They both correspond to what the

##### The `settings` table

See [lua-logger/README.md#configuration](http://github.com/doronbehar/lua-logger#configuration)

##### The `handler` function

See [lua-logger/README.md#the-appender-function](http://github.com/doronbehar/lua-logger#the-appender-function)

### Recommended usage

A full example of a configuration file is included in the repository. You can copy, edit it and write it `autostart/config.lua`. It will be ignored by the `autostart` repo and you can put this in your AwesomeWM's `rc.lua`:

```lua
local autostarter = autostart(require('autostart/config'))
autostarter.run()
```

It is recommended to put this right after all the widgets, the tags and the `tasklist` are set.

Later on, you can bind keys to raise or lower the logging level with this functions:

```lua
autostarter.logger.levels.raise()
autostarter.logger.levels.lower()
```
