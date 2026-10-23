#!/bin/zsh
cd "$(dirname "$0")" || exit 1
exec /opt/homebrew/bin/swipl -q -s main.pl -g start_web -t 'thread_get_message(stop)'
