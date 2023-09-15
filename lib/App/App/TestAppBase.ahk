class TestAppBase extends AppBase {
    ExitApp() {
        event := AppRunEvent(AppEvents.APP_SHUTDOWN, this)
        this["manager.event"].DispatchEvent(event)
        ; Don't actually exit
    }

    RestartApp() {
        event := AppRunEvent(AppEvents.APP_SHUTDOWN, this)
        this["manager.event"].DispatchEvent(event)
        ; Don't actually restart
    }
}
