--- LJ-Expand's environment table containing all functions and data related to it 
lje = {}

--- Simple persistent blob storage for scripts. Data is stored in the `%USERPROFILE%\.lje\data` folder. The namespace is flat: entry names may only contain letters, digits, underscores, and hyphens (max 128 characters) — no subdirectories or file extensions.
lje.data = {}

--- Environment management, script context inspection, and global state control.
lje.env = {}

--- Function inspection and compilation utilities.
lje.func = {}

--- Low-level garbage collector inspection and manipulation.
lje.gc = {}

--- Functions for working with proxy objects in the secure state. When an engine call hook fires, table and userdata arguments are not copied — they are passed as lightweight proxy handles (light userdata) pointing at the host object. Proxies are arena-allocated and do not pin their referent, so they are only valid for the duration of the engine call that produced them. Do not store proxy handles.
lje.proxy = {}

--- Introspection for the currently running LJE script.
lje.script = {}

--- Secure-state-only functionality for interacting with the host (game) Lua state in a controlled way. These functions are only meaningful from within the isolated secure state.
lje.secure = {}

--- ["Per-script user settings. Each script ships its defaults in a `settings.default.toml` file in its own folder; users override them in `%USERPROFILE%\\.lje\\settings\\<author>.<name>.toml`, which lives outside the script's folder so it survives a `git pull`. At read time the two are merged (user overrides win) and the result is cached per script.", '', 'The namespace functions (`get`, `all`, `reload`) operate on the *currently executing* script, so they only work while your script is running — typically at load time. In deferred callbacks (hooks, render, timers) there is no current script; call `lje.settings.open()` once at load and use the returned settings object instead. See the [Settings guide](../guides/settings) for the full picture.']
lje.settings = {}

--- ['Read values out of another Lua universe — the game client (and, later, the menu) — from inside the secure state, **without ever holding a reference into it**.', '', 'Holding a live reference to a foreign object is detectable by adversarial scripts in that state, and a bare pointer into it can dangle if the foreign garbage collector runs. `lje.state.path` avoids both: you describe a traversal up front as a chain of inert operations, and only the terminal `:copy()` touches the foreign state. The whole walk runs in a single C call using raw lookups (no metamethods, no allocation in the foreign state), so the foreign GC cannot step mid-walk and no foreign pointer survives the call. The value you get back is a deep copy living entirely in the secure state.', '', 'Because of this, you can hold onto the **result** of `:copy()` freely — it is yours. What you must never do is try to keep a path pointed at something long-term and treat it as a live handle; a path is a recipe, evaluated fresh each time you call `:copy()`.']
lje.state = {}

--- Miscellaneous utility functions for bytecode inspection, stack introspection, and table creation.
lje.util = {}

--- LuaJIT virtual machine manipulation, primarily engine call interception.
lje.vm = {}

--- Loads a script file relative to the current script's directory. Optionally controls whether the script is executed immediately after loading. Defaults to executing if the second argument is omitted. Requires an active script context. Load and runtime errors are printed to the console rather than raised, in which case nothing is returned.
--- @param path string Path to the script file, relative to the current script.
--- @param execute boolean Whether to execute the script after loading. Defaults to `true`.
--- @return ...
function lje.include(path, execute) end --- @diagnostic disable-line

--- Prints a message to the console, prefixed with `[LJE CONSOLE]`.
--- @param msg string The message to print.
--- @return nil
function lje.con_print(msg) end --- @diagnostic disable-line

--- Writes a binary blob to the data folder under the given name. Creates the folder if it does not exist. Returns `true` on success, `false` on failure. Progress is always printed to the console.
--- @param name string The name of the data entry to write.
--- @param data string The raw data to store. May contain binary content.
--- @return boolean
function lje.data.write(name, data) end --- @diagnostic disable-line

--- Reads a previously written blob from the data folder. Returns nothing if the folder does not exist or if the entry is not found.
--- @param name string The name of the data entry to read.
--- @return string | nil
function lje.data.read(name) end --- @diagnostic disable-line

--- Returns the name of the currently executing LJE script, if any.
--- @return string | nil
function lje.env.current_script() end --- @diagnostic disable-line

--- Returns the full path of the currently executing LJE script, if any.
--- @return string | nil
function lje.env.current_script_path() end --- @diagnostic disable-line

--- Searches for files matching `search_path` relative to the current script's directory. Returns `nil` if no script is active.
--- 
--- Supports wildcard patterns, so if you wanted to find all files in `detours/`, you would do `detours/*`.
--- @param search_path string A path pattern to search for, relative to the current script.
--- @return table | nil
function lje.env.find_script_files(search_path) end --- @diagnostic disable-line

--- Reads the contents of a file relative to the current script's directory. Returns `nil` if no script is active or the file cannot be read.
--- @param relative_path string The path to the file to read, relative to the current script.
--- @return string | nil
function lje.env.read_script_file(relative_path) end --- @diagnostic disable-line

--- Registers a per-script cleanup callback. The callback runs in the secure state when the game closes the main Lua state (e.g. on disconnect or shutdown), before LJE tears down its own resources. Requires an active script context, and only fires for secure scripts. Errors thrown by the callback are caught and printed to the console.
--- @param fn function Must be a Lua function, not a C function.
--- @return nil
function lje.env.on_cleanup(fn) end --- @diagnostic disable-line

--- Compiles a Lua string into a function without executing it. The chunk is loaded under the chunkname `@lje_dynamic_compile` and flagged internally as an LJE proto. Returns `nil` on compilation failure (the error is printed to the console).
--- @param source string Lua source code to compile.
--- @return function | nil
function lje.func.compile(source) end --- @diagnostic disable-line

--- Returns the internal LuaJIT fast function ID (`ffid`) of a function.
--- 
--- - `0` means a Lua function
--- - `1` means a C function
--- - Anything else is the unique ID of a fast function.
--- @param fn function The function to inspect.
--- @return number
function lje.func.type(fn) end --- @diagnostic disable-line

--- Returns the GC's current tracked memory total in bytes.
--- @return integer
function lje.gc.get_total() end --- @diagnostic disable-line

--- Directly overrides the GC's tracked memory total. Useful for hiding allocations from GC pressure calculations. Use with care — setting this too low can cause the GC to trigger too aggressively; too high and it may never trigger.
--- @param bytes integer The value to set as the GC total.
--- @return nil
function lje.gc.set_total(bytes) end --- @diagnostic disable-line

--- Immediately triggers a full GC collection cycle.
--- @return nil
function lje.gc.run_full_gc() end --- @diagnostic disable-line

--- A per-script cache used by `lje.require`. Keyed by script name, then by path. Populated automatically — you generally do not need to interact with this directly.
--- @type table
lje.includeCache = nil

--- A cached version of `lje.include`. The first call for a given `path` within a script context executes the file and caches the result. Subsequent calls return the cached value immediately. Must be called within an active script context.
--- @param path string Path to the file to include, relative to the current script.
--- @return any
function lje.require(path) end --- @diagnostic disable-line

--- A `string.format`-style console print with inline ANSI color support. Wrap text in `$colorName{...}` to colorize it.
--- 
--- Supported colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `default`.
--- 
--- Example:
--- ```lua
--- lje.con_printf("$red{Error}: %s", message)
--- ```
--- @param fmt string A `string.format` format string. Color codes use the syntax `$colorName{text}`.
--- @param ... any Format arguments, passed to `string.format`.
--- @return nil
function lje.con_printf(fmt, ...) end --- @diagnostic disable-line

--- Returns the type of the host object a proxy refers to.
--- @param proxy lightuserdata A proxy handle, as received in an engine call hook.
--- @return string
function lje.proxy.type(proxy) end --- @diagnostic disable-line

--- Materializes the proxied host object into the secure state and returns it. Tables are deep-copied (including metatables, with cycles preserved); userdata contents are copied byte-for-byte and the metatable is remapped to the secure state's own version by its `MetaName`, if one exists. C functions encountered during the copy become secure wrappers; Lua functions are replaced with an empty stub function.
--- @param proxy lightuserdata A proxy handle, as received in an engine call hook.
--- @return any
function lje.proxy.copy(proxy) end --- @diagnostic disable-line

--- Returns the parsed `info.toml` metadata for the currently executing script. See the [info.toml reference](../guides/info-toml) for what each field means.
--- @return table | nil
function lje.script.info() end --- @diagnostic disable-line

--- Resolves a dot-separated path in the host state's global environment using raw lookups (no metamethods) and brings the resulting value into the secure state.
--- 
--- - Paths starting with `_R.` are resolved in the host registry instead of the global environment (e.g. `_R.Entity`).
--- - If the final value is a **C function**, it is wrapped in a secure dispatcher: calling the wrapper executes the original C function against the host state while redirecting its Lua C API activity (e.g. registry access) back to the secure state. Lua functions are rejected and `nil` is returned.
--- - Any other value is deep-copied into the secure state (see `lje.proxy.copy` for the copy semantics).
--- 
--- Returns `nil` if any path segment is missing, empty, or a non-table intermediate. Each failure case is logged to the console.
--- @param name string A dot-separated path into the host global environment, e.g. `"Msg"` or `"player.GetAll"`. Prefix with `_R.` to resolve in the host registry.
--- @return any | nil
function lje.secure.pull(name) end --- @diagnostic disable-line

--- Forces state redirection on or off. While enabled, Lua C API calls made against the host state are transparently redirected to the secure state (registry accesses go to the shadow registry, etc.). This is normally managed automatically — wrappers returned by `lje.secure.pull` enable it for the duration of each call — so manual use is only needed for advanced control.
--- @param force boolean `true` to force redirection to the secure state, `false` to disable it.
--- @return nil
function lje.secure.isolate(force) end --- @diagnostic disable-line

--- Reads a single setting from the current script's merged settings, by dotted path.
--- 
--- The key is traversed through nested tables, so `get("render.color")` returns `settings.render.color`. If any segment along the path is missing (or is not a table), `default` is returned when provided, otherwise `nil`.
--- @param key string A setting key. Use dots to traverse nested tables, e.g. `"section.option"`.
--- @param default any Returned when the key is not present after merging.
--- @return any
function lje.settings.get(key, default) end --- @diagnostic disable-line

--- Returns the current script's full merged settings table (defaults overlaid with user overrides). The table is cached; treat it as read-only.
--- @return table
function lje.settings.all() end --- @diagnostic disable-line

--- Drops the cached settings for the current script so the next `get`/`all` re-reads `settings.default.toml` and the user override file from disk.
--- @return nil
function lje.settings.reload() end --- @diagnostic disable-line

--- Binds a settings object to the **calling** script and returns it. Call this once at load time (while your script has an active context) and reuse the returned object anywhere — including deferred callbacks such as hooks, render, and timers, where the bare `get`/`all`/`reload` would not know which script is asking.
--- 
--- The object exposes `:get(key, default)`, `:all()`, and `:reload()`, which behave like the namespace functions but always resolve to the script that opened them.
--- @return userdata | nil
function lje.settings.open() end --- @diagnostic disable-line

--- Lower-level primitive behind `lje.settings.open()`. Returns a settings object bound to the script with the given name (its folder name, as returned by `lje.env.current_script()`).
--- 
--- Most scripts should use `lje.settings.open()` instead, which captures the calling script's name for you.
--- @param name string The script (folder) name to bind to.
--- @return userdata
function lje.settings.bind(name) end --- @diagnostic disable-line

--- A handle to the game client's Lua state, for use as the first argument to `lje.state.path`. This is the state your scripts would normally run in. It is installed as a global in the secure state once the client state is known (at startup, before secure scripts run). A `LJE_MENU_STATE` handle is planned for the future.
--- @type lightuserdata
lje.state.client = nil

--- Begins a path into `target`, rooted at the global named `root`. Returns a **path object** — an inert builder. Each builder method appends one operation and returns the same object, so calls chain. Nothing reads from `target` until you call `:copy()`.
--- 
--- `root` is looked up by raw key in the target state's global environment (no metamethods). It is a single global name, **not** a dotted path — use `:index` to descend further.
--- 
--- ### Path methods
--- 
--- Each returns the path object for chaining, except `:copy()`, which evaluates the chain.
--- 
--- | Method | Effect |
--- | --- | --- |
--- | `:index(key)` | Raw-indexes the current value (which must be a table) by the string `key`. |
--- | `:upvalue(n)` | Reads the `n`-th upvalue (1-based) of the current value, which must be a Lua or C function. Fast/builtin functions have no accessible upvalues and fail. |
--- | `:expect(type)` | Asserts the current value's type and fails the path otherwise. Accepts Lua type names (`"table"`, `"function"`, `"userdata"`, …) and GMod metatypes by `MetaName` (`"Player"`, `"Vector"`, …), resolved from the object's metatable. GMod metatype takes priority over the bare Lua type. Opt-in — only add it where you want the guard. |
--- | `:copy()` | Evaluates the whole chain against `target` and deep-copies the final value into the secure state. Returns the copy, or `nil` if any step fails (each failure is logged to the console). See `lje.proxy.copy` for the copy semantics. |
--- 
--- If the root is missing or `nil`, or any operation fails — indexing a non-table, a missing key, taking an upvalue of a non-function or an out-of-range index, or a failed `:expect` — `:copy()` logs the reason and returns `nil`.
--- 
--- ### Example
--- 
--- ```lua
--- -- Pull the `teams` table that team.GetName closes over, without ever
--- -- holding a reference into the client state.
--- local teams = lje.state.path(lje.state.client, "team")
---   :index("GetName")  -- team.GetName (a function)
---   :upvalue(1)        -- its first upvalue
---   :expect("table")   -- guard: make sure it really is a table
---   :copy()            -- deep-copy it into the secure state
--- ```
--- @param target lightuserdata The state to read from, e.g. `LJE_CLIENT_STATE`.
--- @param root string A single global name in `target` to root the path at, e.g. `"team"`. Not a dotted path — chain `:index` to go deeper.
--- @return userdata
function lje.state.path(target, root) end --- @diagnostic disable-line

--- Returns a FNV-1a hash of the bytecode of a Lua function. Useful as a stable identity for a function's compiled bytecode — two functions with identical source compiled identically will produce the same hash.
--- @param fn function Must be a Lua function, not a C function.
--- @return integer
function lje.util.get_bytecode_hash(fn) end --- @diagnostic disable-line

--- Returns the current call stack as an array of frame descriptor tables. Each entry contains a `level` (1-based integer), a `type` (`"lua"` or `"c"`), and a `func` (the function at that level). Lua frames additionally include a `chunkname` field.
--- @return table
function lje.util.get_call_stack() end --- @diagnostic disable-line

--- Returns the Lua registry table (`LUA_REGISTRYINDEX`). Useful for inspecting or manipulating registry-stored references.
--- @return table
function lje.util.get_registry() end --- @diagnostic disable-line

--- Registers a Lua function that intercepts every Lua chunk the host (game) state loads. The callback runs in the secure state and receives the chunkname and the source code; it must return a string, which replaces the source that actually gets loaded. If the callback errors or returns a non-string, the original source is used unmodified. Only one callback can be active at a time — registering a new one replaces the previous.
--- @param fn function A function of the form `fn(chunkname, source) -> string`. Must be a Lua function, not a C function.
--- @return nil
function lje.util.set_script_hook_callback(fn) end --- @diagnostic disable-line

--- Creates a new table with pre-allocated space. Equivalent to `lua_createtable`. Useful for avoiding rehashing overhead when the approximate size of the table is known in advance.
--- @param narr integer Expected number of array-part entries. Defaults to `0`.
--- @param nrec integer Expected number of hash-part entries. Defaults to `0`.
--- @return table
function lje.util.create_table(narr, nrec) end --- @diagnostic disable-line

--- Pretty-prints any value to the console using `lje.con_print`. Tables are printed recursively with indentation, and cyclic references are detected and printed as `<recursion: ...>` instead of looping forever.
--- @param value any The value to print.
--- @return nil
function lje.util.inspect(value) end --- @diagnostic disable-line

--- Registers a per-script engine call hook. Whenever the engine invokes a Lua function in the host (game) state, the callback is invoked in the secure state as `fn(func, nargs, nresults, ...)`:
--- 
--- - `func` — a light userdata pointer identifying the called function. Useful for identity comparisons without copying a full function object across states.
--- - `nargs` / `nresults` — the argument and result counts of the engine call.
--- - `...` — the call arguments. Tables and userdata arrive as proxy handles (see `lje.proxy`); other values are copied into the secure state.
--- 
--- The hook's return values are ignored — handling/suppressing engine calls is not currently supported. Errors thrown by the hook are caught and printed to the console. Requires an active script context, and hooks only fire for secure scripts. Only one hook can be active per script at a time.
--- @param fn function Must be a Lua function, not a C function.
--- @return nil
function lje.vm.set_engine_call_hook(fn) end --- @diagnostic disable-line

--- Controls when this script's engine call hook runs relative to the engine call itself.
--- 
--- - `false` (default) — the hook runs *before* the engine call proceeds normally.
--- - `true` — LJE performs the engine call first, then invokes the hook afterwards, so the hook observes a call that has already happened. Since the call is consumed in the process, any remaining scripts' hooks are skipped for that call, and if the hook itself errors, the call's status is returned to the engine as-is.
--- 
--- Requires an active script context.
--- @param post boolean `true` to run the hook after the engine call, `false` to run it before.
--- @return nil
function lje.vm.set_engine_call_hook_post(post) end --- @diagnostic disable-line