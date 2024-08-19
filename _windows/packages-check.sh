#!/bin/bash

shouldExit=false

# Check if elevate is installed
if ! command -v el &>/dev/null; then
  echo "Elevate is not installed. Please install it using the following command as an administrator:"
  echo "choco install elevate -y"
  echo ""
  shouldExit=true
fi

if $shouldExit; then
  echo "Script failed to run -- exiting..."
  exit 1
fi
