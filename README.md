# make.nvim

a simple make wrapper that adds completion for make targets

comes with bells🔔 and whistles📯

## usage:

```
:Make <tab>
```

## install

### lazy

```
return {
  "steverohrlack/make.nvim",
  cmd = "Make",
  dependencies = {
    "plenary.nvim",
  },
  opts = {},
}
```
