# /etc/profile.d/jenkins-env.sh
# Sourced for login shells (SSH, su -, docker exec -it bash -l)
# Purpose: Interactive shell enhancements only
# Environment variables are centralized in Dockerfile ENV
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Prompt — root gets #, all others get $
# Respects NO_COLOR, checks for real terminal
# ---------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    _PROMPT_SYMBOL="#"
else
    _PROMPT_SYMBOL="\$"
fi

# Safe plain default
PS1="\u@\h:\w ${_PROMPT_SYMBOL} "

# Colorful prompt only if terminal supports it and NO_COLOR not set
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ] && [ -n "${BASH_VERSION:-}" ]; then
    PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\] ${_PROMPT_SYMBOL} "
fi

export PS1
unset _PROMPT_SYMBOL

# ---------------------------------------------------------------------
# Source user's .bashrc if it exists (for aliases, history, etc.)
# ---------------------------------------------------------------------
if [ -n "${BASH_VERSION:-}" ] && [ -f "${HOME}/.bashrc" ]; then
    . "${HOME}/.bashrc"
fi
