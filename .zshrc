# oh-my-posh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
	eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/catppuccin_frappe.json)"
fi

# GitHub access token
"[REDACTED FOR OBVIOUS REASONS]"

# fzf
source <(fzf --zsh)

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/joad/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Aliases
alias ll="eza -alh --group-directories-first --icons"
alias tm="tmux new-session -A -s main"
alias jn="jupyter notebook"
alias mtop="sudo mactop --interval 500 --color cyan"

alias db-save="dropdb --if-exist -U postgres -h localhost -p 5432 wellinjob-dump && createdb -U postgres -h localhost -p 5432 wellinjob-dump -T wellinjob"
alias db-restore="dropdb --if-exist -U postgres -h localhost -p 5432 wellinjob && createdb -U postgres -h localhost -p 5432 wellinjob -T wellinjob-dump"
alias db-local-to-e2e="dropdb --if-exist -U postgres -h localhost -p 5434 wellinjob && dropdb --if-exists -U postgres -h localhost -p 5434 wellinjob-e2e  && createdb -U postgres -h localhost -p 5434 wellinjob && pg_dump -C -h localhost -p 5432 -U postgres wellinjob -f wellinjob.dump && psql -h localhost -p 5434 -U postgres -f wellinjob.dump && createdb -U postgres -h localhost -p 5434 wellinjob-e2e -T wellinjob && rm -f wellinjob.dump"
alias db-save-e2e="dropdb --if-exist -U postgres -h localhost -p 5434 wellinjob-dump-e2e && createdb -U postgres -h localhost -p 5434 wellinjob-dump-e2e -T wellinjob-e2e"
alias db-restore-e2e="dropdb --if-exist -U postgres -h localhost -p 5434 wellinjob-e2e && createdb -U postgres -h localhost -p 5434 wellinjob-e2e -T wellinjob-dump-e2e"\n

alias vtest="NODE_ENV=test npx vitest --bail=1 run"
alias vtestd="NODE_ENV=test LOG_LEVEL=error npx vitest --inspect-brk --no-file-parallelism run"

# nvm
export NODE_OPTIONS=--dns-result-order=ipv4first
export NVM_DIR="$HOME/.nvm"
. $(brew --prefix nvm)/nvm.sh

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

find-up() {
  current_path="$(pwd)"
  while [[ "$current_path" != "" && ! -e "$current_path/$1" ]]; do
    current_path=${current_path%/*}
  done
}

load-yarn() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"
  find-up package.json
  if [ -n "$current_path" ]; then
    packageManager="$(grep 'packageManager' $current_path/package.json)"
    if [ -n "$packageManager" ]; then
      corepack enable
      corepack prepare > /dev/null
    fi
  fi
}

add-zsh-hook chpwd load-yarn
load-yarn

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Zoxide

# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
function __zoxide_pwd() {
    \builtin pwd -L
}

# cd + custom logic based on the value of _ZO_ECHO.
function __zoxide_cd() {
    # shellcheck disable=SC2164
    \builtin cd -- "$@"
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
function __zoxide_hook() {
    # shellcheck disable=SC2312
    \command zoxide add -- "$(__zoxide_pwd)"
}

# Initialize hook.
# shellcheck disable=SC2154
if [[ ${precmd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]] && [[ ${chpwd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]]; then
    chpwd_functions+=(__zoxide_hook)
fi

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function __zoxide_z() {
    # shellcheck disable=SC2199
    if [[ "$#" -eq 0 ]]; then
        __zoxide_cd ~
    elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        __zoxide_cd "$1"
    else
        \builtin local result
        # shellcheck disable=SC2312
        result="$(\command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")" && __zoxide_cd "${result}"
    fi
}

# Jump to a directory using interactive search.
function __zoxide_zi() {
    \builtin local result
    result="$(\command zoxide query --interactive -- "$@")" && __zoxide_cd "${result}"
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

function cd() {
    __zoxide_z "$@"
}

function cdi() {
    __zoxide_zi "$@"
}

# Completions.
if [[ -o zle ]]; then
    __zoxide_result=''

    function __zoxide_z_complete() {
        # Only show completions when the cursor is at the end of the line.
        # shellcheck disable=SC2154
        [[ "${#words[@]}" -eq "${CURRENT}" ]] || return 0

        if [[ "${#words[@]}" -eq 2 ]]; then
            # Show completions for local directories.
            _files -/
        elif [[ "${words[-1]}" == '' ]]; then
            # Show completions for Space-Tab.
            # shellcheck disable=SC2086
            __zoxide_result="$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" --interactive -- ${words[2,-1]})" || __zoxide_result=''

            # Bind '\e[0n' to helper function.
            \builtin bindkey '\e[0n' '__zoxide_z_complete_helper'
            # Send '\e[0n' to console input.
            \builtin printf '\e[5n'
        fi

        # Report that the completion was successful, so that we don't fall back
        # to another completion function.
        return 0
    }

    function __zoxide_z_complete_helper() {
        if [[ -n "${__zoxide_result}" ]]; then
            # shellcheck disable=SC2034,SC2296
            BUFFER="cd ${(q-)__zoxide_result}"
            \builtin zle reset-prompt
            \builtin zle accept-line
        else
            \builtin zle reset-prompt
        fi
    }
    \builtin zle -N __zoxide_z_complete_helper

    [[ "${+functions[compdef]}" -ne 0 ]] && \compdef __zoxide_z_complete cd
fi

eval "$(zoxide init zsh)"
