Battery status for Chromebooks using UPower.

Requires upower:
```
apt install upower
```

Install plugin with Lazy:
```
return {
  "git@github.com:coreyb-git/upower.nvim",
  dependencies = {
    "rcarriga/nvim-notify"
  },
  opts = {
    --enabled = false,
  },
}
```

To use with Lualine add the component:
```
lualine_z = {
  { "upower" }, -- combined icon and text
  -- or,
  { "upower_icon" },
  -- or,
  { "upower_text" },
},
```
