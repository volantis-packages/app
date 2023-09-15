class SettingsWindowBase extends FormGuiBase {
    availableThemes := Map()
    needsRestart := false

    __New(container, themeObj, config) {
        this.availableThemes := container.Get("manager.theme").GetAvailableThemes()
        super.__New(container, themeObj, config)
    }

    GetDefaultConfig(container, config) {
        defaults := super.GetDefaultConfig(container, config)

        if (this.app.Parameter["app.has_main_window"]) {
            defaults["ownerOrParent"] := this.app.Parameter["app.main_window_key"]
        }

        defaults["child"] := false
        defaults["title"] := "Settings"
        defaults["buttons"] := "*&Done"
        return defaults
    }

    GetSettingsSections() {
        sections := [Map("label", "General", "callback", ObjBindMethod(this, "GeneralSettings"))]

        if (this.app.Parameter["app.uses_themes"]) {
            sections.Push(Map("label", "Appearance", "callback", ObjBindMethod(this, "AppearanceSettings")))
        }

        if (this.app.Parameter["app.uses_cache"]) {
            sections.Push(Map("label", "Cache", "callback", ObjBindMethod(this, "CacheSettings")))
        }

        if (this.app.Parameter["app.has_advanced_settings"]) {
            sections.Push(Map("label", "Advanced", "callback", ObjBindMethod(this, "AdvancedSettings")))
        }

        return sections
    }

    GeneralSettings() {

    }

    AppearanceSettings() {
        this.AddHeading(this.app.appName . " Theme")
        chosen := this.GetItemIndex(this.availableThemes, this.app.Config["theme_name"])
        ctl := this.guiObj.AddDDL("vtheme_name xs y+m Choose" . chosen . " w250 c" . this.themeObj.GetColor("editText"), this.availableThemes)
        ctl.OnEvent("Change", "OnThemeNameChange")
        ctl.ToolTip := "Select a theme for " . this.app.appName . " to use."

        this.Add("ButtonControl", "", "Reload " this.app.appName, "OnReload")
    }

    CacheSettings() {
        this.AddConfigLocationBlock("Cache Dir", "cache_dir", "&Flush")

        this.AddHeading("Cache Settings")
        this.AddConfigCheckBox("Flush cache on exit (Recommended only for debugging)", "flush_cache_on_exit")
    }

    AdvancedSettings() {
        this.AddHeading("Errors")
        this.AddCOnfigCheckBox("Force error messages to show on top of other windows", "force_error_window_to_top")

        this.AddHeading("Logging Level")
        chosen := this.GetItemIndex(this.container.Get("logger").GetLogLevels(), this.app.Config["logging_level"])
        ctl := this.guiObj.AddDDL("vlogging_level xs y+m Choose" . chosen . " w200 c" . this.themeObj.GetColor("editText"), this.container.Get("logger").GetLogLevels())
        ctl.OnEvent("Change", "OnLoggingLevelChange")
    }

    Controls() {
        super.Controls()
        buttonSize := this.themeObj.GetButtonSize("s", true)
        buttonW := (buttonSize.Has("w") && buttonSize["w"] != "auto") ? buttonSize["w"] : 80

        settingsSections := this.GetSettingsSections()

        tabs := ""

        if (settingsSections.Length > 1) {
            tabNames := []

            for (section in settingsSections) {
                tabNames.Push(section["label"])
            }

            tabsCtl := this.Add("TabsControl", "vSettingsTabs", "", tabNames)
            tabs := tabsCtl.ctl
        }

        for (section in settingsSections) {
            if (tabs != "") {
                tabs.UseTab(section["label"], true)
            }

            section["callback"]()
        }

        if (tabs != "") {
            tabs.UseTab()
        }

        closeW := 100
        closeX := this.margin + this.windowSettings["contentWidth"] - closeW
    }

    AddConfigLocationBlock(heading, settingName, extraButton := "", helpText := "") {
        location := this.app.Config[settingName] ? this.app.Config[settingName] : "Not selected"
        return this.Add("LocationBlock", "", heading, location, settingName, extraButton, true, helpText)
    }

    AddConfigCheckbox(checkboxText, settingName) {
        isChecked := this.app.Config[settingName]
        opts := ["v" . settingName, "w" . this.windowSettings["contentWidth"], "Checked" . isChecked]
        ctl := this.Add("BasicControl", opts, "", "", "CheckBox", checkboxText)
        ctl.RegisterHandler("Click", "OnSettingsCheckbox")
        return ctl
    }

    OnSettingsCheckbox(chk, info) {
        this.guiObj.Submit(false)
        ctlName := chk.Name
        this.app.Config[ctlName] := chk.Value

        if (chk.HasProp("NeedsRestart") && chk.NeedsRestart) {
            this.needsRestart := true
        }
    }

    AddSettingsButton(buttonLabel, ctlName, width := "", height := "", position := "xs y+m", buttonStyle := "normal") {
        buttonSize := this.themeObj.GetButtonSize("s", true)

        if (width == "") {
            width := (buttonSize.Has("w") && buttonSize["w"] != "auto") ? buttonSize["w"] : 80
        }

        if (height == "") {
            height := (buttonSize.Has("h") && buttonSize["h"] != "auto") ? buttonSize["h"] : 20
        }

        return this.Add("ButtonControl", "v" . ctlName . " " . position . " w" . width . " h" . height, buttonLabel, "", buttonStyle)
    }

    SetText(ctlName, ctlText, fontStyle := "") {
        this.guiObj.SetFont(fontStyle)
        this.guiObj[ctlName].Text := ctlText
        this.SetFont()
    }

    OnCacheDirMenuClick(btn) {
        if (btn == "ChangeCacheDir") {
            this.app["manager.cache"].ChangeCacheDir()
            this.SetText("CacheDir", this.app.Config["cache_dir"], "Bold")
        } else if (btn == "OpenCacheDir") {
            this.app["manager.cache"].OpenCacheDir()
        } else if (btn == "FlushCacheDir") {
            this.app["manager.cache"].FlushCaches(true, true)
        }
    }

    OnThemeNameChange(ctl, info) {
        this.guiObj.Submit(false)
        this.app.Config["theme_name"] := this.availableThemes[ctl.Value]
        this.needsRestart := true
    }

    OnLoggingLevelChange(ctl, info) {
        this.guiObj.Submit(false)
        this.app.Config["logging_level"] := ctl.Text
    }

    ProcessResult(result, submittedData := "") {
        ; TODO: Add temporary storage and a Cancel button to the Settings window
        this.app.Config.SaveConfig()

        if (this.needsRestart) {
            response := this.app["manager.gui"].Dialog(Map(
                "title", "Restart " . this.app.appName . "?",
                "text", "One or more settings that have been changed require restarting " . this.app.appName . " to fully take effect.`n`nWould you like to restart " . this.app.appName . " now?"
            ))

            if (response == "Yes") {
                this.app.RestartApp()
            }
        }

        this.ReloadModifiedComponents()

        return result
    }

    /**
     * This method is called if the application does not need a full restart,
     * giving it a chance to reload certain components as needed.
     */
    ReloadModifiedComponents() {

    }
}
