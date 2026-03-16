# Configuration Target Design
This setup helps us remove global target configurations and enforce specific configs locally for each project.
Instead of creating the target under a global configuration, set via`CMAKE_<LANG>_FLAGS_<CONFIG>`, then locally adjusting it through the `target_compile_definitions`, for example, we take the global configuration completely out of the picture.
We configure a set of interface targets which define all configurations we require for our targets:

Target Name        | Description
-------------------|------------
Config::Default    | Default. Strong optimization and extra debug information set up.
Config::DefaultWin | Default for Windows projects. Same as Config::Default with nice-to-have WINDOWS/MFC/ATL macros defined.
Config::Minimal    | Only parallel build, optimization, and debug information settings.
Config::CLR        | Common Language Runtime enabled. Default configuration with flags adapted to be /clr compatible (MSVC only).

