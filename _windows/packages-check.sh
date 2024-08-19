#!/bin/bash

# Check if elevate is installed
if ! command -v el &>/dev/null; then
  echo "Elevate is not installed. Please install it using the following command as an administrator:"
  echo "choco install elevate -y"
  echo ""
  exit 1
fi
