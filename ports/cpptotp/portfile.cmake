vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO RavuAlHemio/cpptotp
    REF 696f618aec5c97970dd0948fef11cf46f7dfa255
    SHA512 0
    PATCHES CMakeLists.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/cpptotp-config.cmake.in" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()

vcpkg_cmake_config_fixup()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
