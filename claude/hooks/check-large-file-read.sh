#!/bin/bash
# Hook: Pre-read check for large files
# If a file exceeds 2000 lines and no offset/limit was specified,
# exit code 2 forces Claude to re-read with chunked parameters.

FILE_PATH="$CLAUDE_TOOL_ARG_FILE_PATH"
OFFSET="$CLAUDE_TOOL_ARG_OFFSET"
LIMIT="$CLAUDE_TOOL_ARG_LIMIT"

# Skip if not a regular file or if offset/limit already specified
[ ! -f "$FILE_PATH" ] && exit 0
[ -n "$OFFSET" ] || [ -n "$LIMIT" ] && exit 0

LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
[ -z "$LINE_COUNT" ] && exit 0

if [ "$LINE_COUNT" -gt 2000 ]; then
  echo "File has $LINE_COUNT lines (exceeds 2000). Use offset and limit parameters to read in chunks of 2000 lines. Start with offset=0, limit=2000."
  exit 2
fi

exit 0
