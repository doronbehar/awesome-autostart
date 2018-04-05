# Awesome WM autostart module

> autostart made easy

### Intro

We all know Awesome WM is a window manager and no more. What this module strives to accomplish is to provide a comfortable way to manage applications which should be started automatically when one opens a new `awesome` session.

Usually, what most users want is to define a list of system tray applications that should be started when running `startx`. Most people are satisfied with putting those shell commands in `~/.xprofile` but this has some drawbacks:

- No notifications when a program exits unexpectedly.
- The `STDOUT` of the programs is naturally printed in the tty from which `startx` was invoked, therefor - no native support for log files
- If one just restarts `awesome`, there is no solution with `~/.xprofile` for applications which need a consistent system tray handler and you want them to restart with `awesome`. (More details in [Usage](#Usage))

### Installation

This module can be cloned to your `awesome` configuration dir and be used right after you configure it as explained in more details later on. It consists of a submodule called `log4l` so **Remember to initialize and update the submodule found in the repo as well**, more info about git submodules here:

[https://git-scm.com/book/en/v2/Git-Tools-Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

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

local autostarter = autostart(autostart_config)
autostarter.run()
```

### Configuration

#### Abstract

First of all, the configuration consists of two sections and it can look like:

```lua
return {
  programs = {
    -- list of programs objects as explaind later on
  }
  log = {
    handler = function (self, level, message) 
      -- a logger function that handles the log info and outputs it to the
      -- console, the desktop session or to a file, be creative!
      -- If you don't feel creative enough to create something usefull here,
      -- you can check the examples in the repositories dir `examples/`.
    end,
    settings = {
      -- a set of parameters that define the default settings of the logger object
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

Here is an example of a `programs` object to put in `autostart_config` object to give as an argument to `autostart()`:
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

The `log` object is meant to be used with a library which was originally called `lualogging` but I forked it and now it is called `log4l`. It is available as a submodule in this repo so don't forget to initialize it and update it along with updates to `autostart` as well.

The `log` object consists of a function called `handler` and a `settings` object.

##### The `settings` object

<!-- TODO -->

##### The `handler` function

Receives the `self` object, the current log level and the message to display.

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
