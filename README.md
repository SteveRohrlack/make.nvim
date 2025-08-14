# make.nvim

a simple make wrapper for quick access to Makefile targets

✔ lets you run your Makefile targets from anywhere in your project

✔ notifies you about result

✔ comes with bells🔔 and whistles📯

## usage:

```
:Make <tab>
```

or open a Makefile and place the cursor somewhere near a target:

```
:MakeNearest
```

## install

you'll need treesitter and the "make" parser for this plugin to work

### lazy

```lua
{
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "make",
    },
  },
}
```

```lua
{
  "steverohrlack/make.nvim",
  cmd = {
    "Make",
    "MakeNearest",
  },
  ft = "make",
  dependencies = {
    "plenary.nvim",
  },
  opts = {},
}
```
