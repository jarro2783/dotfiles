eval `dircolors`

export EDITOR=vim
export PAGER=less

setopt PROMPT_SUBST

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'l:|=* r:|=*'
zstyle ':completion:*' max-errors 5
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

autoload -Uz compinit
compinit

HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=10000
setopt appendhistory autocd extendedglob notify
bindkey -e

# my key bindings
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward

# aliases
alias vi=vim
alias ls='ls --color'

function get_pwd() {
  echo ${PWD/$HOME/~}
}

PROMPT='%F{green}%B%m: %F{blue}%~ %K{5}%F{7}%T
%k%f%b→ '

export $(gnome-keyring-daemon --start)

export GOPATH=$HOME/src/go
export PATH=$PATH:$HOME/local/src/arcanist/bin:$HOME/src/go/bin:$HOME/.gem/ruby/2.1.0/bin

# coloured man pages
man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

# vcs
autoload -Uz vcs_info

zstyle ':vcs_info:*' check-for-changes true

zstyle ':vcs_info:*' actionformats \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats       \
    '%F{5}[%F{2}%r%F{5}](%F{4}%S%F{5}:%F{3}%b%F{5}|%f%c%u%m%F{5})'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'

### git: Show marker (T) if there are untracked files in repository
# Make sure you have added staged to your 'formats':  %c
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

git_status_count() {
  awk '
    BEGIN { staged = 0; unstaged = 0; }
    /^[A-Z] / { staged+=1; }
    /^ [A-Z]/ { unstaged+=1; }
    /^\?\?/ { untracked+=1; }
    END {
      printf "staged=%s\n",staged
      printf "unstaged=%s\n",unstaged
      printf "untracked=%s\n",untracked
    }
  '
}

git_distance() {
  awk '
    BEGIN { ahead = 0; behind = 0; }
    /^>/ { ahead+=1 }
    /^</ { behind+=1 }
    END {
      printf "ahead=%s\n",ahead
      printf "behind=%s\n",behind
    }
  '
}

+vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]]; then
        eval $(git status --porcelain | git_status_count)
        # This will show the marker if there are any untracked files in repo.
        # If instead you want to show the marker only if there are untracked
        # files in $PWD, use:
        #[[ -n $(git ls-files --others --exclude-standard) ]] ; then
        if [[ $untracked -ne 0 ]]; then
          hook_com[misc]="%F{6}…$untracked%f"
        fi

        if [[ $unstaged != 0 ]]; then
          hook_com[unstaged]="%F{red}✚$unstaged"
        fi

        if [[ $staged != 0 ]]; then
          hook_com[staged]="%F{3}●$staged"
        fi
    fi

    branch=$hook_com[branch]
    eval $(git rev-list --left-right origin/$branch...HEAD 2>/dev/null | git_distance)

    if [[ $ahead != 0 ]]; then
      hook_com[branch]+="%F{7}↑${ahead}"
    fi
    if [[ $behind != 0 ]]; then
      hook_com[branch]+="%F{7}↓${behind}"
    fi
}

precmd() {
  vcs_info
}

RPROMPT='${vcs_info_msg_0_}%f'
