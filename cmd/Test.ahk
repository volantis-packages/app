TraySetIcon("{{APPICON}}")

HtmlResultViewer("{{APPNAME}} Test Suite").ViewResults(
    SimpleTestRunner(FilesystemTestLoader("{{APPDIR}}").GetTests()).RunTests()
)
