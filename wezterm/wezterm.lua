-- Wezterm API
local wezterm = require('wezterm')

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

-- if os.getenv('WEZTERM_QUAKE_MODE') == '1' then
--   config.window_decorations = 'NONE'
-- end

return config

