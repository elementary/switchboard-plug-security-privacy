configure_file (${CMAKE_SOURCE_DIR}/data/org.pantheon.security-privacy.policy.in ${CMAKE_BINARY_DIR}/data/org.pantheon.security-privacy.policy)
install(FILES ${CMAKE_BINARY_DIR}/data/org.pantheon.security-privacy.policy DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/polkit-1/actions/)
install(FILES ${CMAKE_SOURCE_DIR}/data/security-privacy-plug-helper PERMISSIONS OWNER_EXECUTE OWNER_READ DESTINATION ${PKGDATADIR}/)

include (GSettings)
add_schema ("org.pantheon.security-privacy.gschema.xml")
