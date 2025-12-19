# json

Functions for converting Lua values to/from JSON. Useful for saving configuration setting tables, importing data that users are intended to edit externally, and storing large data structures outside your Lua code.

The `indent` parameter is an integer specifying the number of spaces to indent with when dumping tables. 0 disables indentation, and -1 also disables line breaks.

Supports Lua's boolean, number, string, and table (see warning below) types. Other types will be converted to `nil`, stored as JSON `null`s. Due to JSON limitations, non-string table keys will be converted to strings (if numbers) or an empty string (if another type), unless the table is a sequence (consecutive integer keys, starting at 1; see the [lua manual](https://www.lua.org/manual/5.4/manual.html#3.4.7) for more details). Sequences are stored as JSON arrays.

**WARNING:** Care should be taken when storing non-sequence tables with numeric keys, as those keys will be converted to strings. Extra work must be done to convert those keys back into numbers.

The following are examples of tables that won't change when converted to and back from JSON:
```lua
{1, 3, 2, "this is a sequence"}
{foo="bar", baz=42}
{table1={1,2,3}, table2={foo=1,bar=2}}
```
The following are examples of tables that **will** change when converted to and back from JSON:
```lua
{9, 8, nil, 6, 5} -- Sequence with a "hole", becomes {["1"]=9,["2"]=8,["4"]=6,["5"]=5}
{[0]=0,[1]=1,[2]=2} -- Sequence doesn't start at 1, becomes {["0"]=0,["1"]=1,["2"]=2}
{"foo", "bar", baz=17} -- Becomes {["1"]="foo", ["2"]="bar", baz=17}
local function f() end
{[f]="function key", funcval=f} -- Becomes {[""]="function key"}
```

## Methods

### `json.load_string(json_str)`
Takes a JSON string and turns it into a Lua value (usually a table). Returns `nil` on error.

### `json.dump_string(value, [indent])`
Takes a Lua value (usually a table) and turns it into a JSON string. Returns an empty string on error. If unspecified, `indent` will default to -1.

### `json.load_file(filepath)`
Loads a JSON file identified by `filepath` relative to the `UnrealVRMod/GameName/data` subdirectory and returns it as a Lua value (usually a table). Returns `nil` if the file does not exist.

### `json.dump_file(filepath, value, [indent])`
Takes a Lua value (usually a table), and turns it into a JSON file identified as `filepath` relative to the `UnrealVRMod/GameName/data` subdirectory.  Returns `true` if the dump was successful, `false` otherwise. If unspecified, `indent` will default to 4
