set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_ENV_PASSTHROUGH PATH)

set(VCPKG_CMAKE_SYSTEM_NAME MinGW)
set(VCPKG_POLICY_DLLS_WITHOUT_LIBS enabled)

# Debug MinGW COFF objects for large generated Qt sources exceed the ~10MB
# string table limit even with -Wa,-mbig-obj (qtlanguageserver/qlanguageservergen.cpp).
if(PORT MATCHES "^qt")
    set(VCPKG_BUILD_TYPE release)
endif()

# Bookworm mingw-w64 headers lack ISelectionProvider; Qt 6.9's MinGW UI Automation
# shim then fails with "expected class-name" in qwindowsuiautomation.h.
if(PORT STREQUAL "qtbase" OR PORT STREQUAL "qtwebview")
    set(VCPKG_CMAKE_CONFIGURE_OPTIONS "-DFEATURE_accessibility=OFF")
endif()
