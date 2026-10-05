-- Serpantinum config with the same keybinds as your own Hyprland config (config2).
local mainMod = _G.mainMod or "SUPER"
local terminal = _G.terminal or "kitty"
local fileManager = "dolphin"
local msg = function(args) return hl.dsp.exec_cmd("serpantinum msg " .. args) end

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Core (same as config2)
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + w", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("serpantinum lock"), { locked = true })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("serpantinum lock"), { repeating = true, locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("serpantinum lock"), { locked = true })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(terminal .. " --title claude claude"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/bp-record.sh"))

-- Launcher / wallpaper / screenshot: your keys, Serpantinum's versions
hl.bind(mainMod .. " + SPACE", msg("toggle launcher"))
hl.bind(mainMod .. " + R", msg("toggle wallpaper"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum screenshot"))

-- Scratchpad workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces, mouse move/resize
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Serpantinum panels that your keys no longer cover: free keys, or Super + Alt
hl.bind(mainMod .. " + C", msg("toggle clipboard"))
hl.bind(mainMod .. " + B", msg("toggle system"))
hl.bind(mainMod .. " + H", msg("toggle guide"))
hl.bind(mainMod .. " + ALT + M", msg("toggle music"))
hl.bind(mainMod .. " + ALT + S", msg("toggle calendar"))
hl.bind(mainMod .. " + ALT + N", msg("toggle network"))
hl.bind(mainMod .. " + ALT + V", msg("toggle volume"))
hl.bind(mainMod .. " + ALT + A", msg("toggle autohide"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("serpantinum reload"))
hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd("firefox"))

-- Print screen keys
hl.bind("Print", hl.dsp.exec_cmd("serpantinum screenshot"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("serpantinum screenshot --edit"), { locked = true })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("serpantinum screenshot --full"), { locked = true })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("serpantinum screenshot --full --edit"), { locked = true })

-- Media / volume / brightness (Serpantinum's, so you get its on-screen display)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("serpantinum brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("serpantinum brightness raise"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("serpantinum volume mic-toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("serpantinum volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("serpantinum volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("serpantinum volume raise"), { repeating = true, locked = true })

-- Workspaces: Super + 1-0 (Serpantinum's workspace handling)
for i = 1, 10 do
  local ws = tostring(i)
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws .. " move"))
end

-- >>> your infinite-desktop keybinds (same as config2)
hl.bind(mainMod .. " + Z", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + X", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("python3 ~/scripts/floating_tile_toggle.py"))
for _, d in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(mainMod .. " + " .. d, hl.dsp.exec_cmd("python3 ~/scripts/navigate_windows.py " .. d))
  hl.bind(mainMod .. " + ALT + " .. d, hl.dsp.exec_cmd("python3 ~/scripts/move_window_tiled.py " .. d))
  hl.bind(mainMod .. " + SHIFT + " .. d, hl.dsp.exec_cmd("python3 ~/scripts/move_window.py " .. d), { repeating = true })
  hl.bind(mainMod .. " + CTRL + " .. d, hl.dsp.exec_cmd("python3 ~/scripts/resize_window.py " .. d), { repeating = true })
end
-- <<< infinite-desktop
