#!/bin/sh

# HACK: This is to get the github notifier actually running otherwise it will fail to run due to some libssl.so nonsense
nix run github:whutchinson98/github-notifier
exit_code=$?

if [ $exit_code -eq 2 ]; then
    echo '{"text": "", "class": "notification", "tooltip": "You have GitHub notifications"}'
else
    echo '{"text": "", "class": "none", "tooltip": "No notifications"}'
fi
