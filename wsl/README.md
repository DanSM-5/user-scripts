## Connect with 1password from wsl

1. On windows install `npiperelay`

2. On wsl add the following to your `.bashrc`/`.zshrc` or any other startup script

```bash
#!/usr/bin/env bash

# Optional shell check if symlinked to same file in gitbash
if [ "$IS_WSL" = true ]; then
  # Configure ssh forwarding
  export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
  # need `ps -ww` to get non-truncated command for matching
  # use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
  ALREADY_RUNNING=$(ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"; echo $?)
  if [[ $ALREADY_RUNNING != "0" ]] && command_exists socat; then
      if [[ -S $SSH_AUTH_SOCK ]]; then
          # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
          echo "removing previous socket..."
          rm $SSH_AUTH_SOCK
      fi
      echo "Starting SSH-Agent relay..."
      # setsid to force new session to keep running
      # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
      (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
  fi
fi
```

## Common wsl config

### Jenv utility

Utility to start jenv

```bash
init_jenv () {
  if command_exists jenv; then
    echo "Jenv already in session"
  elif [ -d "$HOME/.config/jenv/bin" ]; then
    echo "Starting jenv..."
    export PATH="$HOME/.config/jenv/bin:$PATH"
    eval "$(jenv init -)"
    echo 'Done!'
  else
    echo "No jenv available"
  fi
}

```

### Java environment variables

```bash

export ZSH_AUTOSUGGEST_HISTORY_IGNORE=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

if [ "$IS_WSL2" = true ]; then
  # Configure jenv
  # export PATH="$HOME/.config/jenv/bin:$PATH"
  # eval "$(jenv init -)"
  export JAVA_HOME='/usr/lib/jvm/java-11-openjdk-amd64'
  export PATH="$PATH:$JAVA_HOME/bin"

  export ANDROID_HOME=$HOME/Android
  export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

  # export WSL_HOST_IP="$(tail -1 /etc/resolv.conf | cut -d' ' -f2)"
  # export ADB_SERVER_SOCKET=tcp:$WSL_HOST_IP:5037
  export TZ='America/Toronto'
elif [ "$IS_WSL1" = true ]; then
  export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
  export ANDROID_HOME=$HOME/Android/Sdk
  export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
  export HOMEBREW_NO_AUTO_UPDATE=true
fi
```
