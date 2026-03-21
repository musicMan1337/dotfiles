# PHP Debugging in Viper

Viper runs on IIS, so traditional PHP logging is awkward. Use the built-in `debugLog()` helper instead.

## debugLog()

**Location:** `public/application/helpers/sitehelpers_helper.php`

```php
debugLog($message, $log_path = "debug.log", $max_size_mb = 10)
```

- **`$message`** — String to log. For arrays/objects, use `print_r($var, true)` or `json_encode($var)`.
- **`$log_path`** — Filename relative to `public/uploaded/` (default: `debug.log`).
- **`$max_size_mb`** — Auto-rotates if file exceeds this size.

**Output location:** `public/uploaded/debug.log` (or `public/uploaded/{custom}.log`)

**Dev only:** Only logs when `ENVIRONMENT === "development"`. Silent no-op in production.

## Common Patterns

```php
// Simple message
debugLog("hit the records_get endpoint");

// Dump a variable
debugLog(print_r($data, true));

// Dump with label
debugLog("payload: " . json_encode($payload));

// Multiple values
debugLog("user: {$user_id}, entity: {$entity}, action: {$action}");

// Custom log file
debugLog("auth trace: " . print_r($_SESSION, true), "auth_debug.log");
```

## Debug Workflow for the Agent

1. **Clear the log** before each debug session for a clean slate:
   - Use `viper_request` or `browser_evaluate` is not needed — just truncate the file directly via the Viper MCP or read/clear via shell.
   - The log lives at: `~/eBacon/Viper/public/uploaded/debug.log`

2. **Add `debugLog()` calls** to the PHP code you're investigating.

3. **Trigger the code** — either via `viper_request` (backend) or by interacting with the frontend via Playwright.

4. **Read the log** to see the output.

5. **Clean up** — remove the `debugLog()` calls when done.

## Clearing the Log

Truncate the file to start fresh (preserves the file, just empties it):
```bash
> ~/eBacon/Viper/public/uploaded/debug.log
```

Or for a custom log file:
```bash
> ~/eBacon/Viper/public/uploaded/custom.log
```
