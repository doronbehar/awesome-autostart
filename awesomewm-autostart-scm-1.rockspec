package = "awesomewm-autostart"
version = "scm-1"
source = {
	url = "git://github.com/doronbehar/awesome-autostart",
}
description = {
	summary = "Enhanced autostart for AwesomeWM",
	homepage = "https://github.com/doronbehar/awesome-autostart",
	license = "Apache v2.0"
}
supported_platforms = {
	"linux"
}
dependencies = {
	"lua >= 5.2",
	"logger",
	"luaposix"
}
build = {
	type = "builtin",
	modules = {
		autostart = "init.lua"
	}
}
