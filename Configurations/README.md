# Configuration Mechanism
We use a modern CMake mechanism to specify the configuration of a project through interface libraries instead of using global variables `CMAKE_<LANG>_FLAGS_<CONFIG>` or `CMAKE_<TYPE>_LINKER_FLAGS_<CONFIG>`.
Also whole program optimization is configured locally per project instead of through `CMAKE_INTERPROCEDURAL_OPTIMIZATION_<CONFIG>`. The setting `CMAKE_MSVC_DEBUG_INFORMATION_FORMAT` is also reset in favor of local per-target configuration.

## Table of Contents:
 - [Configuration Target Design](docs/Config.md)
 - [Compiler and Linker Flags](docs/CompilerFlags.md)


## Open Tasks
 - GCC / Clang detailed analysis