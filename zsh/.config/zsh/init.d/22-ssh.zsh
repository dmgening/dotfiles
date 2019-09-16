#
# Provides for an easier use of SSH by setting up ssh-agent.
#


if (( ! $+commands[ssh-agent] )); then
  return 1
fi

#
# Variables
#

typeset -U identities

identities=("${(@)SSH_IDENTITY_LIST:-$(echo "id_rsa ")}")
config_dir="${SSH_CONFIG_DIR:-$XDG_CONFIG_HOME/ssh}"
agent_env="${SSH_AGENT_ENV:-${TMPDIR:-/tmp}/ssh-agent.env.$UID}"
agent_sock="${TMPDIR:-/tmp}/ssh-agent.sock.$UID"

#
# Start ssh-agent 
#

if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
  # Export environment variables.
  source "$agent_env" 2> /dev/null

  # Start ssh-agent if not started.
  if ! ps -U "$LOGNAME" -o pid,ucomm | grep -q -- "${SSH_AGENT_PID:--1} ssh-agent"; then
    eval "$(ssh-agent | sed '/^echo /d' | tee "$agent_env")"
  fi
fi

# Create a persistent SSH authentication socket.
if [[ -S "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$agent_sock" ]]; then
  ln -sf "$SSH_AUTH_SOCK" "$agent_sock"
  export SSH_AUTH_SOCK="$agent_sock"
fi

#
# Load identities.
#

if ssh-add -l 2>&1 | grep -q 'The agent has no identities'; then
  # ssh-add has strange requirements for running SSH_ASKPASS, so we duplicate
  # them here. Essentially, if the other requirements are met, we redirect stdin
  # from /dev/null in order to meet the final requirement.
  #
  # From ssh-add(1):
  # If ssh-add needs a passphrase, it will read the passphrase from the current
  # terminal if it was run from a terminal. If ssh-add does not have a terminal
  # associated with it but DISPLAY and SSH_ASKPASS are set, it will execute the
  # program specified by SSH_ASKPASS and open an X11 window to read the
  # passphrase.
  if [[ -n "$DISPLAY" && -x "$SSH_ASKPASS" ]]; then
    ssh-add ${identities:+$config_dir/${^identities[@]}} < /dev/null 2> /dev/null
  else
    ssh-add ${identities:+$config_dir/${^identities[@]}} 2> /dev/null
  fi
fi

# Clean up.
unset config_dir agent_env agent_sock identities