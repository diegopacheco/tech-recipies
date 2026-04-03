# Lazy Vim (neo-vim) Configurations

To install neo-vim via LazyVim do:
```bash
# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

nvim
```
More on: https://www.lazyvim.org/installation

## 1. Make neo-tree always open on the current file path

First install neo-tree. Open nvim and run:
```bash
:Lazy install nvim-neo-tree/neo-tree.nvim
```
Restart nvim.

Then add the following configuration to your `init.lua` file.

Open init.lua config
```bash
vim ~/.config/nvim/init.lua
```

Add this:
```lua
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("Neotree filesystem reveal_force_cwd")
  end,
})
```
Restart nvim.

## 2. Install Copilot in neo-vim

Run:
```bash
:Lazy install github/copilot.vim
~/.config/nvim/lua/plugins/copilot.lua
```
Add
```lua
return {
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = { enabled = false },
      panel = { enabled = false },
    })
  end,
  dependencies = {
    "zbirenbaum/copilot-cmp",
  },
}
```
Restart nvim.

Then run:
```bash
:Copilot auth
:Copilot status
```