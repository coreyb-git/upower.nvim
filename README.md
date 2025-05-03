Battery status for Chromebooks that can use UPower to get status reports.

Requires upower:
```
apt install upower
```

Install plugin with Lazy:
```
return {
	{
		"git@github.com:coreyb-git/upower.nvim",
		opts = {
				--enabled = false,
		},
	},
}
```
To use with Lualine add this component:
```
lualine_z = {
	{ "upower" }, -- combined icon and text
    -- or,
    { "upower_icon" },
    -- or,
    { "upower_text" },

},
```
