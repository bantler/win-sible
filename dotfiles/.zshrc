[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh
[[ -f ~/.zsh/starship.zsh ]] && source ~/.zsh/starship.zsh
[[ -f ~/.zsh/wsl2fix.zsh ]] && source ~/.zsh/wsl2fix.zsh

# Load Starship
eval "$(starship init zsh)"

# Add sources
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load completions
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

autoload -Uz compinit
compinit

# Load Zoxide
export PATH="$HOME/.local/bin:$PATH"
eval "$(zoxide init zsh)"

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

SSH_ENV=$HOME/.ssh/environment

# start the ssh-agent
function start_agent {
    echo "Initializing new SSH Agent ..."

    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"

    echo "... succeeded!"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add
}

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH-AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

