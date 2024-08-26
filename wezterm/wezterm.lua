-- Wezterm API
local wezterm = require('wezterm')
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font('CaskaydiaCove Nerd Font')
config.font_size = 16

-- -- For example, changing the color scheme:
-- local oneHalfDarkTheme = wezterm.color.get_builtin_schemes()['OneHalfDark']
-- oneHalfDarkTheme.background = {
--   background = {
--     {
--       source = {
--         Color = '#282c34',
--       },
--       opacity = 0.85,
--     }
--   }
-- }
-- config.color_schemes = {
--   OneHalfDark = oneHalfDarkTheme,
--   -- TransparentBackground = {
--   --   background = {
--   --     {
--   --       source = {
--   --         Color = '#282c34',
--   --       },
--   --       opacity = 0.85,
--   --     }
--   --   }
--   -- }
-- }

config.color_scheme = 'OneHalfDark'
config.window_background_opacity = 0.85
-- config.background = {
--   {
--     source = {
--       Color = '#282c34',
--     },
--     opacity = 0.85,
--   }
-- }

-- Enable if using environment variable instead of command line arguments
-- if os.getenv('WEZTERM_QUAKE_MODE') == '1' then
--   config.window_decorations = 'NONE'
-- end

if wezterm.gui then
  local insert_key = function (mode, key_config)
    table.insert(
      mode,
      key_config
    )
  end

  -- copy mode overrides
  local copy_mode = wezterm.gui.default_key_tables().copy_mode
  local copy_mode_overrides = {
    -- sane default arrow key word navigation
    { key = 'RightArrow', mods = 'CTRL', action = act.CopyMode('MoveForwardWord') },
    { key = 'LeftArrow', mods = 'CTRL', action = act.CopyMode('MoveBackwardWord') }
  }
  for _, key in ipairs(copy_mode_overrides) do
    insert_key(copy_mode, key)
  end

  -- add overrides
  config.key_tables = {
    copy_mode = copy_mode
  }

  -- update key events (no mode)
  config.keys = {
    { key = 'M', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },
    { key = 'L', mods = 'ALT|SHIFT', action = act.ClearScrollback('ScrollbackOnly') },
    { key = 'K', mods = 'CTRL|SHIFT', action = act.ScrollByPage(-1) },
    { key = 'J', mods = 'CTRL|SHIFT', action = act.ScrollByPage(1) },
  }
end

if os.getenv('IS_STEAMDECK') == 'true' then
  -- Enable scroll bar for scrolling with pointer only like steam deck
  config.enable_scroll_bar = true
end

return config

