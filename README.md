# nvim-minimax

## Introduction

This is the Neovim setup based on ['nvim-minimax'](https://nvim-mini.org/MiniMax/). Most of the
library modules are from the ['mini.nvim'](https://nvim-mini.org/mini.nvim/) modules.

## Setup

The setup is simple - clone to `$HOME/.config/nvim` folder and then execute:

```
    nvim --headless "+lua vim.pack.update(nil, { force=true} )" "+qa"
```

Alternatively, if you still wish to preserve the earlier nvim setup, then clone to `$HOME/.config/minimax` folder and then execute:

```
    NVIM_APPNAME=minimax nvim --headless "+lua vim.pack.update(nil, { force=true} )" "+qa"
```
