# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.1-1] - 2026-10-09

### Added
- `is_element` global that validates whether a function can be used as an element (exactly 1 parameter).

### Fixed
- `is_element` no longer crashes when the argument is not a function.
- Runtime generates more compact code: sugar `func{...}` calls, inlined expressions and alphabetically ordered props.
- `import.M.compile` now returns `nil, err` when compilation fails instead of erroring with a confusing message.
- Import test path updated to the new fixture location (`dslx/test/?.dslx`).

### Changed
- LSP annotations (`---@param`/`---@return`) and MIT headers added across all modules.
- Removed the unused `loglua` dependency.

## [2.0-1] - 2026-10-04

### Breaking
- Module renamed from `DaviLuaXML` to `dslx`, complete rewrite of the library on top of LPeg.

### Added
- Parser rewritten on LPeg: `<tag prop="x">texto</tag>` becomes `tag{name = "tag", props = {prop = "x"}, childrens = {"texto"}}`.
- Runtime with extensible handler system: register custom node types with `runtime:addHandler`.
- Import API: `require()` of `.dslx` files directly, with `install`/`uninstall`/`loadfile`/`reload`/`clear`.
- Compiler can write the generated Lua to a file (`tofile`, `output_dir`, `output_name`) and resolves relative paths.
- Main module exports the full API and installs the `require` searcher automatically.

### Removed
- 1.x subsystems dropped in the rewrite: `proptypes`, middleware, cache, sourcemap, treeshake and the `dslxc` CLI.

## [1.5-1] - 2025-12-15

### Added
- Prop validation system (`DaviLuaXML.proptypes`) with registry-based schemas and component-local `propTypes`.
- Runtime invocation helper (`DaviLuaXML.runtime`) used by transformed code.
- Simple line-based sourcemap support (`DaviLuaXML.sourcemap`) with runtime error rewriting in loader/core.
- Tree-shaking pass (`DaviLuaXML.treeshake`) with compiler flag `dslxc --treeshake`.

### Changed
- Transformed tags are routed through `__daviluaxml_invoke(...)` (enables validation and consistent invocation).

## [1.4-1] - 2025-12-15

### Added
- Cache layer for `.dslx` loading to avoid re-transforming unchanged files (`DaviLuaXML.cache`).
- Pre-compilation support (`DaviLuaXML.compile`) to convert `.dslx` to plain `.lua`.
- `dslxc` CLI tool to compile a file or an entire directory of `.dslx`.
- Test coverage for the new cache and compiler modules.

### Changed
- `require("DaviLuaXML")` loader now uses the cache automatically during module loading.

## [1.3-1] - 2025-12-14

### Changed
- File extension renamed from `.lx` to `.dslx` (Davi System Lua XML).
- Documentation and examples updated to reference `.dslx`.
- VS Code extension updated to recognize `.dslx` files.

### Breaking
- Projects using `.lx` files must rename them to `.dslx`.

## [1.2-5] - 2025-12-01

### Fixed
- Multiline string serialization now uses Lua long brackets (`[[...]]` / `[=[...]=]`) to avoid invalid syntax.

## [1.2-4] - 2025-12-01

### Added
- Middleware documentation added to the help system (en/pt/es).

## [1.2-3] - 2025-12-01

### Changed
- Release/tag housekeeping to align with already-existing LuaRocks versions.

## [1.2-2] - 2025-12-01

### Changed
- Rockspec version bump to avoid conflicts with an existing `1.2-1` on LuaRocks.

## [1.2-1] - 2025-12-01

### Added
- Middleware system to transform `props` and `children` before serialization.

### Fixed
- FCST module loading issues during development/testing.

## [1.1-1] - 2025-11-26

### Added
- Multi-language help system (English, Portuguese, Spanish).
- README translations and language selector.
- Debug logging guidance via `loglua`.
