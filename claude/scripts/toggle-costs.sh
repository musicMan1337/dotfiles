#!/bin/bash
if [ -f ~/.claude/.hide-costs ]; then
  rm ~/.claude/.hide-costs
  echo "costs shown"
else
  touch ~/.claude/.hide-costs
  echo "costs hidden"
fi
