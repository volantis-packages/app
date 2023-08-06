TraySetIcon("{{APPICON}}")
if (AhkIncludeUpdater("{{APPDIR}}").UpdateIncludes()) {
    MsgBox("{{APPNAME}} libraries have changed. Please restart or rebuild the application.")
}
