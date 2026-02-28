vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libstatgrab/libstatgrab
    REF 13227a3baebe03d4eca147d860ca73f610984999
    SHA512 8c5aade84ae2275cc030607263f08cc80b035b09fa43cffdecc792089983faebc4260e90a5018140aa381d869fae4b51f04fc1fda08ede01dac2b1a67c4d5f87
    PATCHES
        configure.ac.patch
        disk_stats.c.patch
        globals.c.patch
        os_info.c.patch
        vector.c.patch
        opt.c.patch
)

if(VCPKG_TARGET_IS_WINDOWS)
    # The test Makefiles generate test scripts which Windows Make mistakenly assumes are EXEs.
    # Look for references to full_stats.t and diff_stats.t
    list(APPEND EXTRA_OPTS --disable-tests)
endif()

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
    OPTIONS
        --disable-man
        --disable-saidar
        --disable-statgrab
        ${EXTRA_OPTS}
)

vcpkg_install_make()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug"
)

vcpkg_copy_pdbs()
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.LGPL")
