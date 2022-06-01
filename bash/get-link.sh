#!/usr/bin/env bash

link="$1"
destination="$HOME/.config/ytfzf/subcriptions"
if [[ $link =~ "youtube.com/c/" ]] || [[ $link =~ "youtube.com/user/" ]]; then
  channel=$(ytfzf --channel-link="$link")
IFS='' read -r -d '' content <<EOF
# ${link}
${channel}
EOF
else
  content="\n$link"
fi

printf "\n$content" >> "$destination"

