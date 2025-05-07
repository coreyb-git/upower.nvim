Battery status for Chromebooks using UPower.

NOTE:  UPower only updates every 30 seconds, so there is a delay of up to 30 seconds between the real and reported value in NeoVim.  The reported battery time remaining also varies wildly based on the computer usage at the time of the update - I've tried to mitigate this by averaging the values over a small number of samples to smooth-out the variations.

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
  opts = {},
}
```

To use with Lualine add the component "upower", or "upower_icon", or "upower_text":
```
lualine_z = {
  { "upower" }, -- combined icon and text
  -- or,
  { "upower_icon" },
  -- or,
  { "upower_text" },
},
```
