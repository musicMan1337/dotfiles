# CI3 Backend Routing — Quick Reference

## URL Structure

```
http://localhost:PORT/index.php/{path_to_controller}/{function_name}
```

Controllers live at: `public/application/controllers/*`

## REST Controllers vs Legacy Controllers

### REST Controllers (extend REST_Controller)
- Functions are suffixed with HTTP method: `records_get()`, `record_post()`, `index_get()`
- The URL does NOT include the suffix — the HTTP method determines which function runs
- Example: `GET /index.php/api/employees/records` → calls `records_get()` in the Employees controller
- When using the `viper_request` MCP tool, pass the full function name with suffix (e.g., `api/employees/records_get`) and it parses automatically

### Legacy Controllers (extend CI_Controller)
- Functions have no method suffix: `reports()`, `dashboard()`, `index()`
- Typically respond to GET (sometimes POST for form handlers)
- When using `viper_request`, pass the path as-is and optionally specify `method`

## The `index` Function

If the function name is `index` (with or without method suffix), it can be omitted from the URL:
- `api/employees/index_get` → `GET /index.php/api/employees`
- `dashboard/index` → `GET /index.php/dashboard`

## Common API Patterns

- **List/search**: `GET /index.php/api/{resource}/records` → `records_get()`
- **Single record**: `GET /index.php/api/{resource}/record?id=123` → `record_get()`
- **Create**: `POST /index.php/api/{resource}/record` → `record_post()`
- **Update**: `PUT /index.php/api/{resource}/record` → `record_put()`
- **Delete**: `DELETE /index.php/api/{resource}/record?id=123` → `record_delete()`

These are conventions, not rules — individual controllers may differ.
