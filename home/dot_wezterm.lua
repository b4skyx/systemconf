-- WezTerm config. On Windows it lives in %USERPROFILE%\.wezterm.lua and is
-- applied by a native Windows chezmoi (never from inside WSL).
local wezterm = require("wezterm")
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Alternative shells (Windows), e.g. config.default_prog = fish
local gitbash = { wezterm.home_dir .. "/AppData/Local/Programs/Git/bin/bash.exe", "-i", "-l" }
local fish = { "C:/tools/cygwin/bin/fish.exe", "-i", "-l" }
local bash = { "C:/tools/cygwin/bin/bash.exe", "-i", "-l" }
local zsh = { "C:/tools/cygwin/bin/zsh.exe", "-i", "-l" }

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.color_scheme = "nord"
-- config.font = wezterm.font_with_fallback({
-- 	"Comic Code",
-- 	"Liga SFMono Nerd Font",
-- })
config.set_environment_variables = {
	CHERE_INVOKING = "1",
}

-- Windows: open WSL by default (openSUSE-Tumbleweed if present, else the first distro)
if is_windows then
	local preferred = "WSL:openSUSE-Tumbleweed"
	local first
	for _, dom in ipairs(wezterm.default_wsl_domains()) do
		first = first or dom.name
		if dom.name == preferred then
			first = preferred
			break
		end
	end
	if first then
		config.default_domain = first
	end
end

config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = false
config.font_size = 14
config.check_for_updates = false
return config
