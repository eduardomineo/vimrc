# Vim development environment

A practical Ubuntu-oriented Vim setup built around NERDTree, FZF, ripgrep, coc.nvim (with Volar for Vue), Fugitive, GitGutter, Airline, and Glow.

The leader key is Space. The configuration treats a Vim tab as a workspace containing a NERDTree panel and a file window. FZF launched from NERDTree is deliberately routed to the file window.

## Requirements

Install the basic tools:

```bash
sudo apt update
sudo apt install git npm ripgrep vim-nox
```

Install [Glow](https://github.com/charmbracelet/glow) using its Ubuntu installation instructions if it is not available from your configured repositories.

Use a Vim build with job/channel, terminal, popup-window, and timer support. Coc.nvim needs the first two; the rest serve Glow, GitGutter, and FZF's preview scrolling:

```bash
vim --version
```

Inside Vim, useful checks are:

```vim
:echo has('job')
:echo has('channel')
:echo has('terminal')
:echo has('popupwin')
:echo has('timers')
```

A powerline-compatible Nerd Font is recommended for Airline and vim-devicons.

## Installation

Clone this repository and link the configuration:

```bash
git clone <repository-url> ~/.config/vimrc
mv ~/.vimrc ~/.vimrc.backup  # only if a vimrc already exists
ln -s ~/.config/vimrc/vimrc ~/.vimrc
```

Install Vundle:

```bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
```

Vundle has no equivalent of vim-plug's `branch` option, so it clones coc.nvim's default `master` branch — TypeScript source only, no prebuilt `build/index.js`. Vundle's clone is also shallow (`--depth=1`) and does not fetch other branches, so a plain `git checkout release` can fail with "pathspec did not match." Fetch and track the prebuilt `release` branch explicitly:

```bash
cd ~/.vim/bundle/coc.nvim
git config --add remote.origin.fetch '+refs/heads/release:refs/remotes/origin/release'
git fetch origin
git switch --track origin/release
```

This only needs to be done once: `:PluginUpdate` runs `git pull` on whichever branch is currently checked out, and the tracking set up above means that stays `release`.

### Coc.nvim extensions

`vimrc` declares the required extensions in `g:coc_global_extensions` (`coc-tsserver`, `coc-pyright`, `coc-clangd`), so coc installs anything missing the first time Vim starts after `:PluginInstall`. This needs network access; once installed, extensions are cached under `~/.config/coc/extensions` and startup no longer touches the network.

To install or reinstall manually:

```vim
:CocInstall coc-tsserver coc-pyright coc-clangd
```

## Vue completion with Volar

coc-tsserver handles JavaScript and TypeScript natively, but Vue single-file components require Volar. This configuration expects it under `~/.local/share/vue-language-server`.

Install a compatible Volar 2.x release and TypeScript 5:

```bash
npm install --allow-git=all --prefix ~/.local/share/vue-language-server \
  '@vue/language-server@^2.0.0' 'typescript@^5.0.0'
```

The `--allow-git=all` permission applies only to this invocation. Volar 2.x has an Emmet parser dependency hosted on GitHub; do not enable Git dependencies globally merely for this installation.

Verify it:

```bash
~/.local/share/vue-language-server/node_modules/.bin/vue-language-server --version
```

Version 2.2.12 is known to work. The vimrc supplies the isolated TypeScript SDK and disables Volar hybrid mode, which is required for a generic LSP client such as coc.nvim.

Restart Vim, open a Vue file, and check:

```vim
:set filetype?
:CocInfo
:CocList services
```

`:set filetype?` should report `filetype=vue`. `:CocList services` should list the `vue` language server as running. Do not force Vue files to the `html` filetype.

## Workflow

### NERDTree

NERDTree opens automatically when Vim starts without file arguments.

| Key | Action |
| --- | --- |
| `Alt-f` | Toggle NERDTree |
| `Alt-y` | Find the current file in NERDTree |
| `Ctrl-P` | Run FZF Files in the file window |
| `:Rg query` | Run project search in the file window |

Most terminals encode Alt as an Escape prefix. The vimrc consequently writes these mappings as `<Esc>f`, `<Esc>y`, and `<Esc>w`; they are intended to be pressed as Alt-f, Alt-y, and Alt-w. If entering a mapping literally inside Vim, `Ctrl-V` followed by the Alt combination inserts the same `^[` byte sequence.

The custom quit behavior is intentional:

- Plain `:q` refuses to hide a modified file.
- `:q!` explicitly forces the file window closed.
- A NERDTree-only tab closes instead of leaving a full-screen tree.
- `:q` entered from NERDTree safely targets the associated file window.

### FZF

| Key | Command | Purpose |
| --- | --- | --- |
| `Ctrl-P`, `Space f f` | `:Files` | Find files |
| `Space f g` | `:Rg` | Search project text |
| `Space f b` | `:Buffers` | Switch loaded buffers |
| `Space f l` | `:Lines` | Search lines in loaded buffers |
| `Space f h` | `:History` | Search recent files and commands |
| `Space f c` | `:Commits` | Search Git commits |

While an FZF picker has a preview pane, use `Shift-Up` and `Shift-Down` to scroll the preview without leaving the picker. NERDTree is hidden while mapped FZF pickers are open and restored after the picker closes.

The file source includes hidden files but excludes common build, metadata, cache, Git, and `node_modules` directories. Errors are written to `~/.vim/fzf-error.log`.

### Buffers and windows

| Key | Action |
| --- | --- |
| `Ctrl-Right` / `Ctrl-Left` | Next/previous buffer |
| `Alt-Shift-Left/Right` | Focus left/right window |
| `Alt-<` / `Alt->` | Narrow/widen window |
| `-` / `+` | Shorten/tall window |
| `Alt-w` | Close buffer with Bclose |

New horizontal splits open below; vertical splits open to the right.

### Coc.nvim navigation and refactoring

| Key | Action |
| --- | --- |
| `Space j d` | Go to definition |
| `Space j r` | Find references |
| `Space j t` | Go to type |
| `Space j h` | Show documentation |
| `Space j n` | Rename symbol; enter the new name |
| `Space j f` | Apply a suggested fix |

`Space j d` jumps to where the symbol itself is defined, such as a variable declaration or function implementation. `Space j t` jumps to where the symbol's type is defined, such as a class, interface, or type alias. For `const user: User`, definition goes to `user`; type goes to `User`.

Coc records navigation in Vim's jump list. Use `Ctrl-O` to go backward and `Ctrl-I` to go forward.

Hover documentation (`Space j h`) opens in a floating window rather than a preview split.

While the completion popup menu is open, `Tab`/`Shift-Tab` cycle candidates and `Enter` confirms the selected one. Outside the menu these keys behave normally.

### Diagnostics

`Space d o` runs `:CocDiagnostics`, which fills Vim's native location list with coc's diagnostics for the current buffer, same as before.

| Key | Action |
| --- | --- |
| `Space d o` | Open diagnostics |
| `Space d c` | Close diagnostics |
| `] d` | Next diagnostic |
| `[ d` | Previous diagnostic |

`] d` and `[ d` jump directly to the next/previous diagnostic via coc, independent of whether the location list is open.

### Search and display

Search is incremental and case-insensitive unless the query contains uppercase characters. `*`, `#`, `g*`, and `g#` highlight their matches. Arrow keys, `Esc`, `Space h`, and entering insert mode clear the highlight.

The sign column is always visible so coc and GitGutter signs do not shift the text. The editor keeps five context lines around the cursor and enables persistent undo.

### Git

Useful Fugitive commands:

```vim
:Git
:Gdiffsplit
:Gwrite
:G blame
```

GitGutter shows changed, added, and removed lines in the sign column. `Space f c` searches commits through FZF.

### Markdown with Glow

Open a saved Markdown file and run:

```vim
:Glow
```

Glow opens in a temporary terminal tab. Press `q` inside Glow; its terminal and tab close automatically. NERDTree is not mirrored into Glow tabs.

### Persistent undo

Undo files live in `~/.vim/undo`. The directory is created automatically with mode 0700.

- `u`: undo
- `Ctrl-R`: redo
- `:earlier 10m`: return to the state from ten minutes ago
- `:later 10m`: move forward again

## Project directory behavior

When `~/Repositories` exists, Vim starts there. If it does not exist, startup continues in the current directory. This makes the same vimrc usable in containers and sandboxes.

For language servers and searches, opening Vim from a project root is still recommended:

```bash
cd path/to/project
vim
```

## Updating

Update plugins:

```vim
:PluginUpdate
```

Update coc extensions too:

```vim
:CocUpdateSync
```

Update Volar only within the compatible major version:

```bash
npm update --allow-git=all --prefix ~/.local/share/vue-language-server
```

Do not blindly upgrade to Volar 3.x: its TypeScript request-forwarding architecture may not work with coc.nvim's generic LSP client.

## Troubleshooting

### Coc.nvim and Volar

```vim
:CocInfo
:CocOpenLog
:CocList services
```

If the Vue server is dead, `:CocList services` shows its status and `:CocOpenLog` opens coc's log for its stderr output. Check the editor environment:

```vim
:echo executable('node')
:echo exepath('node')
:echo executable('rg')
:echo executable('glow')
```

Desktop-launched Vim can inherit a different PATH from an NVM-enabled terminal.

### Filetypes

```vim
:set filetype?
```

Incorrect filetype detection prevents the intended semantic completer from running.

### Mappings

```vim
:verbose nmap <C-P>
:verbose nmap <leader>jd
:verbose cmap <CR>
```

The final line shows where each mapping was defined.

### Reloading

Autocommands are placed in named groups and cleared before recreation, so the file can be sourced repeatedly:

```vim
:source ~/.vimrc
```

Plugin and language-server changes are best tested after fully restarting Vim.

### Minimal startup

Test Vim without this configuration:

```bash
vim --clean
```

Measure startup:

```bash
vim --startuptime /tmp/vim-startup.log
less /tmp/vim-startup.log
```

## Repository layout

- `vimrc`: complete configuration.
- `README.md`: installation, workflow, maintenance, and troubleshooting.
- `.gitignore`: local editor artifacts, histories, logs, and environment files.

Plugins, undo files, FZF history, language servers, and generated logs remain outside the repository.

## Security notes

- Modelines are disabled.
- Persistent undo is stored in a private directory.
- Volar is installed without sudo.
- npm Git dependency permission is scoped to individual commands.
- Logs, histories, sessions, and environment files are ignored.

## License

Licensed under the [MIT License](LICENSE).
