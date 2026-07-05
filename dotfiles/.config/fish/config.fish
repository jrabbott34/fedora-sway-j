# ── starship prompt ───────────────────────────────────────────────────────────
starship init fish | source

# ── aliases ───────────────────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias la='eza -a --icons'
alias cat='bat --style=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias swayconfig='gedit ~/.config/sway/config'
alias wayconfig='gedit ~/.config/waybar/config.jsonc'

# ── environment ───────────────────────────────────────────────────────────────
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache

# ── system info on new terminal ────────────────────────────────────────────────
if status is-interactive
    fastfetch
end
