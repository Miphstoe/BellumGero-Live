## Changelog (Bellum Gero local dev)

### 2026-02-01

#### Context/docs fixes
- **Corrected Core3 config path**: `MMOCoreORB/bin/conf/config.lua` (not `MMOCoreORB/bin/config.lua`).
- **Corrected DB settings from codebase**: `DBHost="db"`, `DBPort=3306`, `DBName="swgemu"`, `DBUser="swgemu"`.
- **Removed plaintext DB password from context docs** (secrets should live in config/local env only).
- **Added a high-signal codebase map** to speed up navigation (Lua vs C++ vs config).
- **Reformatted `SWG_CONTEXT.md`** for clarity and “single source of truth”.
- **Documented how to locate TRE files** when `/mnt/c/SWGEmu/*.tre` is not the correct path (example Desktop location).

#### Build blockers resolved (WSL / Debian)
- **Discord++ / DPP dependency**:
  - Build required `pkg-config` package `dpp`.
  - `libdpp-dev` was not available in current Debian repos, so DPP was built + installed from source.
  - Verified via `pkg-config --modversion dpp` and `pkg-config --cflags --libs dpp`.
- **GCC 14 `-Werror=redundant-move`**:
  - Removed redundant `std::move(...)` in return statements in:
    - `MMOCoreORB/src/server/zone/objects/scene/SceneObjectImplementation.cpp`
  - Purpose: keep the strict build (`-Werror`) and maintain modern compiler compatibility.
- **Engine3 linker issue (`StringHashCodeTable::crctable`)**:
  - Fixed duplicate/undefined symbol problems by:
    - Removing redundant out-of-line declaration in `utils/engine3/MMOEngine/src/system/lang/String.cpp`
    - Marking the header table as `inline static constexpr` in `utils/engine3/MMOEngine/src/system/lang/String.h`
  - Note: `utils/engine3` is a git submodule; track this change intentionally.
