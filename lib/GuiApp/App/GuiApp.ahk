class GuiAppBase extends AppBase {
    themeReady := false

    GetParameterDefinitions(config) {
        params := super.GetParameterDefinitions(config)
        params["app.uses_themes"] := true
        params["app.has_settings"] := false
        params["app.settings_window"] := "SettingsWindow"
        params["app.has_advanced_settings"] := false
        params["app.has_main_window"] := false
        params["app.main_window_key"] := "MainWindow"
        params["app.show_about_menu_item"] := false
        params["app.about_window"] := "AboutWindow"
        params["app.default_theme"] := "Steampad"
        params["config.backups_view_mode"] := "Report"
        params["config.theme_name"] := "@@app.default_theme"
        params["config.themes_dir"] := "@@{resources_dir}\themes"
        params["config.force_error_window_to_top"] := false
        params["config.modules_view_mode"] := "Report"
        params["config.main_window"] := "MainWindow"
        params["themes.extra_themes"] := []
        return params
    }

    GetServiceDefinitions(config) {
        services := super.GetServiceDefinitions(config)

        services["definition_loader.themes"] := Map(
            "class", "DirDefinitionLoader",
            "arguments", [
                "@factory.structured_data",
                "@@config.themes_dir",
                "",
                false,
                false,
                "",
                "theme"
            ]
        )

        services["factory.gui"] := Map(
            "class", "GuiFactory",
            "arguments", ["@{}", "@manager.theme", "@id_generator"]
        )

        services["factory.theme"] := Map(
            "class", "ThemeFactory",
            "arguments", [
                "@{}",
                "@@resources_dir",
                "@manager.event",
                "@id_generator",
                "@logger"
            ]
        )

        services["installer.themes"] := Map(
            "class", "ThemeInstaller",
            "arguments", [
                "@@version",
                "@state.app",
                "@manager.cache",
                "file",
                "@version.sorter",
                "@@themes.extra_themes",
                "@@{tmp_dir}\Installers"
            ]
        )

        services["manager.gui"] := Map(
            "class", "GuiManager",
            "arguments", [
                "@{}",
                "@factory.gui",
                "@state.app",
                "@manager.event",
                "@notifier"
            ]
        )

        services["manager.theme"] := Map(
            "class", "ThemeManager",
            "arguments", [
                "@{}",
                "@manager.event",
                "@notifier",
                "@config.app",
                "@definition_loader.themes",
                "Steampad"
            ]
        )

        return services
    }

    PreInitializeModules(config) {
        this.InitializeTheme()
    }

    InitializeTheme() {
        this[["gdip", "manager.gui", "manager.theme"]]
        this.themeReady := true
    }

    ConfirmAction(message, title) {
        return this.app["manager.gui"].Dialog(Map(
            "title", title,
            "text", message
        ))
    }

    InitializeApp(config) {
        super.InitializeApp(config)

        if (this.Parameter["app.custom_tray_menu"]) {
            A_TrayMenu.Delete()
            this["manager.event"].Register(Events.AHK_NOTIFYICON, "TrayClick", ObjBindMethod(this, "OnTrayIconRightClick"), 1)
        }
    }

    RunApp(config) {
        super.RunApp(config)
        this.OpenApp(config)
    }

    OpenApp(config) {
        mainWin := this.Parameter["config.main_window"]

        if (mainWin) {
            if (this["manager.gui"].Has(mainWin)) {
                WinActivate("ahk_id " . this["manager.gui"][mainWin].GetHwnd())
            } else {
                this["manager.gui"].OpenWindow(Map(
                    "type", mainWin,
                    "title", this.appName
                ))
            }
        }
    }

    RestartApp() {
        if (this.Services.Has("manager.gui")) {
            guiMgr := this["manager.gui"]

            if (guiMgr.Has("MainWindow")) {
                guiMgr.StoreWindowState(this["manager.gui"]["MainWindow"])
            }
        }

        super.RestartApp()
    }

    ShowError(title, errorText, err, allowContinue := true) {
            if (this.themeReady) {
                try {
                    btns := allowContinue ? "*&Continue|&Reload|&Exit" : "*&Reload|&Exit"

                    this["manager.gui"].Dialog(Map(
                        "type", "ErrorDialog",
                        "title", "Unhandled Exception",
                        "text", errorText,
                        "buttons", btns,
                        "alwaysOnTop", this.Config["force_error_window_to_top"]
                    ), err)
                } catch as ex {
                    this.ShowUnthemedError(title, errorText, err, ex, allowContinue)
                }
            } else {
                this.ShowUnthemedError(title, err.Message, err, "", allowContinue)
            }


        return allowContinue ? -1 : 1
    }

    ShowUnthemedError(title, errorText, err, displayErr := "", allowContinue := true) {
        otherErrorInfo := (displayErr && err != displayErr) ? "`n`nThe application could not show the usual error dialog because of another error:`n`n" . displayErr.File . ": " . displayErr.Line . ": " . displayErr.What . ": " . displayErr.Message : ""
        super.ShowError(title, errorText . otherErrorInfo, err, allowContinue)
        MsgBox(errorText . otherErrorInfo, "Error")
    }

    ShowTrayMenu() {
        menuItems := []
        menuItems.Push(Map("label", "Open " . this.appName, "name", "OpenApp"))
        menuItems := this.SetTrayMenuItems(menuItems)
        menuItems.Push("")
        menuItems.Push(Map("label", "Restart", "name", "RestartApp"))
        menuItems.Push(Map("label", "Exit", "name", "ExitApp"))

        result := this["manager.gui"].Menu(menuItems, this)
        this.HandleTrayMenuClick(result)
    }

    SetTrayMenuItems(menuItems) {
        if (!A_IsCompiled) {
            menuItems.Push("")
            menuItems.Push(Map("label", "Build " . this.appName, "name", "BuildApp"))
            menuItems.Push(Map("label", "Update Includes", "name", "UpdateIncludes"))
        }

        return menuItems
    }

    HandleTrayMenuClick(result) {
        if (result == "OpenApp") {
            this.OpenApp()
        } else if (result == "RestartApp") {
            this.RestartApp()
        } else if (result == "ExitApp") {
            this.ExitApp()
        } else if (result == "BuildApp") {
            this.BuildApp()
        } else if (result == "UpdateIncludes") {
            this.UpdateIncludes()
        }

        return result
    }

    MainMenu(parentGui, parentCtl, showOpenAppItem := false) {
        menuItems := this.GetMainMenuItems(showOpenAppItem)

        if (menuItems.Length) {
            this.HandleMainMenuClick(this["manager.gui"].Menu(
                menuItems,
                parentGui,
                parentCtl
            ))
        }
    }

    GetMainMenuItems(showOpenAppItem := false) {
        menuItems := []
        menuItems := this.AddMainMenuEarlyItems(menuItems, showOpenAppItem)

        if (menuItems.Length) {
            menuItems.Push("")
        }

        length := menuItems.Length

        toolsItems := this.GetToolsMenuItems()

        if (toolsItems.Length) {
            menuItems.Push(Map("label", "&Tools", "name", "ToolsMenu", "childItems", toolsItems))
        }

        aboutItems := this.GetAboutMenuItems()

        if (aboutItems.Length) {
            menuItems.Push(Map("label", "&About", "name", "About", "childItems", aboutItems))
        }

        menuItems := this.AddMainMenuMiddleItems(menuItems)

        if (menuItems.Length > length) {
            menuItems.Push("")
        }

        length := menuItems.Length
        menuItems := this.AddMainMenuLateItems(menuItems)

        if (menuItems.Length > length) {
            menuItems.Push("")
        }

        if (this.Parameter["app.show_restart_menu_item"]) {
            menuItems.Push(Map("label", "&Restart", "name", "Reload"))
        }

        menuItems.Push(Map("label", "E&xit", "name", "Exit"))

        event := MenuItemsEvent(AppEvents.APP_MENU_ITEMS_ALTER, menuItems)
        this.Dispatch(event)
        menuItems := event.MenuItems

        return menuItems
    }

    GetAboutMenuItems() {
        aboutItems := []

        if (this.Parameter["app.show_about_menu_item"]) {
            aboutItems.Push(Map("label", "&About " . this.appName, "name", "About"))
        }

        if (this.Parameter["app.show_website_menu_item"]) {
            aboutItems.Push(Map("label", "Open &Website", "name", "OpenWebsite"))
        }

        event := MenuItemsEvent(AppEvents.APP_MENU_ABOUT_ITEMS_ALTER, aboutItems)
        this.Dispatch(event)
        aboutItems := event.MenuItems

        return aboutItems
    }

    GetToolsMenuItems() {
        toolsItems := this.AddEntityManagerMenuLinks([])
        event := MenuItemsEvent(AppEvents.APP_MENU_TOOLS_ITEMS_ALTER, toolsItems)
        this.Dispatch(event)
        toolsItems := event.MenuItems

        return toolsItems
    }

    AddMainMenuEarlyItems(menuItems, showOpenAppItem := false) {
        if (showOpenAppItem) {
            menuItems.Push(Map("label", "Open " . this.appName, "name", "OpenApp"))
            menuItems.Push("")
        }

        event := MenuItemsEvent(AppEvents.APP_MENU_ITEMS_EARLY, menuItems)
        this.Dispatch(event)
        menuItems := event.MenuItems

        return menuItems
    }

    AddMainMenuMiddleItems(menuItems) {
        event := MenuItemsEvent(AppEvents.APP_MENU_ITEMS_MIDDLE, menuItems)
        this.Dispatch(event)
        menuItems := event.MenuItems
        return menuItems
    }

    AddMainMenuLateItems(menuItems) {
        if (this.Parameter["app.has_settings"]) {
            menuItems.Push(Map("label", "&Settings", "name", "Settings"))
        }

        if (this.Parameter["app.supports_update_check"]) {
            menuItems.Push(Map("label", "Check for &Updates", "name", "CheckForUpdates"))
        }

        event := MenuItemsEvent(AppEvents.APP_MENU_ITEMS_LATE, menuItems)
        this.Dispatch(event)
        menuItems := event.MenuItems

        return menuItems
    }

    AddEntityManagerMenuLinks(menuItems) {
        menuEntityTypes := this._getToolsMenuEntityTypes()

        for key, entityType in menuEntityTypes {
            menuLinkText := entityType.definition["manager_menu_link_text"]

            if (!menuLinkText) {
                menuLinkText := "&" . entityType.definition["name_plural"]
            }

            menuItems.Push(Map("label", menuLinkText, "name", "manage_" . key))
        }

        return menuItems
    }

    _getToolsMenuEntityTypes() {
        entityTypes := Map()

        for key, entityType in this["manager.entity_type"] {
            if (entityType.definition["manager_link_in_tools_menu"]) {
                entityTypes[key] := entityType
            }
        }

        return entityTypes
    }

    HandleMainMenuClick(result) {
        event := MenuResultEvent(AppEvents.APP_MENU_PROCESS_RESULT, result)
        this.Dispatch(event)
        result := event.Result

        if (!event.IsFinished) {
            if (result == "About") {
                this.ShowAbout()
            } else if (result == "OpenWebsite") {
                this.OpenWebsite()
            } else if (result == "Settings") {
                this.ShowSettings()
            } else if (result == "CheckForUpdates") {
                this.CheckForUpdates()
            } else if (result == "Reload") {
                this.restartApp()
            } else if (result == "Exit") {
                this.ExitApp()
            } else {
                for key, entityType in this._getToolsMenuEntityTypes() {
                    if (result == "manage_" . key) {
                        this["entity_type." . key].OpenManageWindow()
                        break
                    }
                }
            }
        }

        return result
    }

    ShowSettings() {
        windowName := this.Parameter["app.settings_window"]

        if (windowName) {
            this["manager.gui"].Dialog(Map("type", windowName, "unique", false))
        }
    }

    ShowAbout() {
        windowName := this.Parameter["app.about_window"]

        if (windowName) {
            this["manager.gui"].Dialog(Map("type", windowName))
        }
    }

    ShowUpdateMessage(releaseInfo) {
        this["manager.gui"].Dialog(Map("type", "UpdateAvailableWindow"), releaseInfo)
    }
}
