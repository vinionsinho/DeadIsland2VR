# UEVR_FConsoleManager

Instance can be obtained with `uevr.api:get_console_manager()`.

## Functions

### `console:get_console_objects()`

Returns a `TArray<ConsoleObjectElement>` of console objects.

### `console:find_object(name: string)`

Returns the [IConsoleObject](IConsoleObject.md) object with the specified name.

### `console:find_variable(name: string)`

Returns the [IConsoleVariable](IConsoleVariable.md) object with the specified name.

### `console:find_command(name: string)`

Returns the [IConsoleCommand](IConsoleCommand.md) object with the specified name.