class AppBase {
    versionStr := ""
    appName := ""
    appKey := ""
    appDir := ""
    tmpDir := ""
    dataDir := ""
    configObj := ""
    stateObj := ""
    serviceContainerObj := ""
    startConfig := ""
    isSetup := false

    static Instance := ""

    Version {
        get => this.versionStr
        set => this.versionStr := value
    }

    Services {
        get => this.serviceContainerObj
        set => this.serviceContainerObj := value
    }

    Config {
        get => this["config.app"]
    }

    State {
        get => this["state.app"]
    }

    Parameter[key] {
        get => this.Services.GetParameter(key)
        set => this.Services.SetParameter(key, value)
    }

    __Item[serviceId] {
        get => this.Service(serviceId)
    }

    __New(params*) {
        AppBase.Instance := this

        config := params.Has(1) ? params[1] : ""

        if (!List.IsMapLike(config)) {
            if (config == "") {
                config := Map()
            } else if (params.Has(2)) {
                config := Map(params*)
            } else {
                throw AppException("App config must be a map or an even number of values used as key-value pairs.")
            }
        }

        this.startConfig := List.Merge(this.GetDefaultConfig(), config)

        if (this.startConfig["console"]) {
            this.AllocConsole()
        }

        if (this.startConfig["trayIcon"]) {
            TraySetIcon(this.startConfig["trayIcon"])
        }

        if (this.startConfig["autoStart"]) {
            this.Startup()
        }
    }

    GetDefaultConfig() {
        return Map(
            "appName", "",
            "appDir", "",
            "console", false,
            "trayIcon", "",
            "autoStart", true,
            "version", "",
            "appKey", "",
            "tmpDir", "",
            "dataDir", ""
        )

    }

    GetParameterDefinitions(config) {
        return Map(
            "version", this.versionStr,
            "app_name", this.appName,
            "app_key", this.appKey,
            "app_dir", this.appDir,
            "data_dir", this.dataDir,
            "tmp_dir", this.tmpDir,
            "app.website_url", "",
            "app.custom_tray_menu", false,
            "app.developer", "",
            "app.uses_cache", true,
            "app.show_restart_menu_item", true,
            "app.supports_update_check", false,
            "app.show_website_menu_item", false,
            "app.short_description", "",
            "app.long_description", "",
            "app.by_line", "",
            "app.links", [],
            "resources_dir", "@@{app_dir}\resources",
            "config_path", "@@{app_dir}\" . this.appName . ".json",
            "config_key", "config",
            "config.backup_dir", "@@{data_dir}\\Backups",
            "config.backups_file", "@@{data_dir}\Backups.json",
            "config.cache_dir", "@@{tmp_dir}\Cache",
            "config.flush_cache_on_exit", false,
            "config.check_updates_on_start", false,
            "config.logging_level", "Error",
            "config.modules_file", "@@{data_dir}\Modules.json",
            "config.log_path", "@@{data_dir}\" . this.appName . "Log.txt",
            "config.module_dirs", ["@@{data_dir}\Modules"],
            "config.core_module_dirs", ["@@{app_dir}\Lib\"],
            "state_path", "@@{data_dir}\" . this.appName . "State.json",
            "service_files.app", "@@{app_dir}\" . this.appName . ".services.json",
            "service_files.user", "@@{data_dir}\" . this.appName . ".services.json",
            "include_files.modules", "@@{data_dir}\ModuleIncludes.ahk",
            "include_files.module_tests", "@@{data_dir}\ModuleIncludes.test.ahk",
            "module_config", Map(),
            "modules.Auth", true,
            "structured_data.basic", Map(
                "class", "BasicData",
                "extensions", []
            ),
            "structured_data.ahk", Map(
                "class", "AhkVariable",
                "extensions", []
            ),
            "structured_data.json", Map(
                "class", "JsonData",
                "extensions", [".json"]
            ),
            "structured_data.proto", Map(
                "class", "ProtobufData",
                "extensions", [".db", ".proto"]
            ),
            "structured_data.vdf", Map(
                "class", "VdfData",
                "extensions", [".vdf"]
            ),
            "structured_data.xml", Map(
                "class", "Xml",
                "extensions", [".xml"]
            ),
            "entity_type.backup", Map(
                "name_singular", "Backup",
                "name_plural", "Backups",
                "entity_class", "BackupEntity",
                "entity_manager_class", "BackupManager",
                "storage_config_storage_parent_key", "Backups",
                "storage_config_path_parameter", "config.backups_file",
                "manager_view_mode_parameter", "config.backups_view_mode",
                "manager_gui", "ManageBackupsWindow",
                "manager_link_in_tools_menu", true
            ),
            "entity_field_type.boolean", "BooleanEntityField",
            "entity_field_type.class_name", "ClassNameEntityField",
            "entity_field_type.directory", "DirEntityField",
            "entity_field_type.entity_reference", "EntityReferenceField",
            "entity_field_type.file", "FileEntityField",
            "entity_field_type.hotkey", "HotkeyEntityField",
            "entity_field_type.icon_file", "IconFileEntityField",
            "entity_field_type.id", "IdEntityField",
            "entity_field_type.number", "NumberEntityField",
            "entity_field_type.service_reference", "ServiceReferenceField",
            "entity_field_type.string", "StringEntityField",
            "entity_field_type.time_offset", "TimeOffsetEntityField",
            "entity_field_type.url", "UrlEntityField",
            "entity_field_widget_type.checkbox", "CheckboxEntityFieldWidget",
            "entity_field_widget_type.combo", "ComboBoxEntityFieldWidget",
            "entity_field_widget_type.directory", "DirectoryEntityFieldWidget",
            "entity_field_widget_type.entity_form", "EntityFormEntityFieldWidget",
            "entity_field_widget_type.entity_select", "EntitySelectEntityFieldWidget",
            "entity_field_widget_type.file", "FileEntityFieldWidget",
            "entity_field_widget_type.hotkey", "HotkeyEntityFieldWidget",
            "entity_field_widget_type.number", "NumberEntityFieldWidget",
            "entity_field_widget_type.select", "SelectEntityFieldWidget",
            "entity_field_widget_type.text", "TextEntityFieldWidget",
            "entity_field_widget_type.time_offset", "TimeOffsetEntityFieldWidget",
            "entity_field_widget_type.url", "UrlEntityFieldWidget"
        )
    }

    GetServiceDefinitions(config) {
        return Map(
            "cache.file", Map(
                "class", "FileCache",
                "arguments", [
                    "@@tmp_dir",
                    "@cache_state.file",
                    "@@config.cache_dir",
                    "File"
                ]
            ),
            "cache_state.file", Map(
                "class", "CacheState",
                "arguments", ["@@config.cache_dir", "File.json", "@version.sorter", "@@version"]
            ),
            "config.app", Map(
                "class", "AppConfig",
                "arguments", ["@config_storage.app_config", "@{}", "@@config_key"]
            ),
            "config.modules", Map(
                "class", "PersistentConfig",
                "arguments", ["@config_storage.modules", "@{}", "module_config"]
            ),
            "config_storage.app_config", Map(
                "class", "JsonConfigStorage",
                "arguments", "@@config_path"
            ),
            "config_storage.modules", Map(
                "class", "JsonConfigStorage",
                "arguments", ["@@config.modules_file", "modules"]
            ),
            "debugger", Map(
                "class", "Debugger",
                "calls", Map(
                    "method", "SetLogger",
                    "arguments", "@logger"
                )
            ),
            "definition_loader.entity_type", Map(
                "class", "ParameterEntityTypeDefinitionLoader",
                "arguments", ["@{}", "entity_type", "@factory.entity_type"]
            ),
            "definition_loader.modules", Map(
                "class", "ModuleDefinitionLoader",
                "arguments", [
                    "@factory.modules",
                    "@config.modules",
                    "@@config.module_dirs",
                    "@@config.core_module_dirs",
                    "@@modules"
                ]
            ),
            "factory.entity_field_widget", Map(
                "class", "EntityFieldWidgetFactory",
                "arguments", ["@{}"]
            ),
            "factory.entity_type", Map(
                "class", "EntityTypeFactory",
                "arguments", ["@{}", "@manager.event", "@id_sanitizer"]
            ),
            "factory.modules", Map(
                "class", "ModuleFactory",
                "arguments", ["@{}", "@factory.structured_data", "@config.modules"]
            ),
            "factory.structured_data", Map(
                "class", "StructuredDataFactory",
                "arguments", "@@structured_data"
            ),
            "gdip", "Gdip",
            "id_generator", "UuidGenerator",
            "id_sanitizer", Map(
                "class", "StringSanitizer"
            ),
            "logger", Map(
                "class", "LoggerService",
                "arguments", ["@logger.file"]
            ),
            "logger.file", Map(
                "class", "FileLogger",
                "arguments", [
                    "@@config.log_path",
                    "@@config.logging_level",
                    true
                ]
            ),
            "manager.cache", Map(
                "class", "CacheManager",
                "arguments", [
                    "@config.app",
                    "@{}",
                    "@manager.event",
                    "@notifier"
                ]
            ),
            "manager.entity_type", Map(
                "class", "EntityTypeManager",
                "arguments", [
                    "@{}",
                    "@manager.event",
                    "@notifier",
                    "@definition_loader.entity_type"
                ]
            ),
            "manager.event", Map(
                "class", "EventManager"
            ),
            "manager.installer", Map(
                "class", "InstallerManager",
                "arguments", ["@{}", "@manager.event", "@notifier"]
            ),
            "manager.module", Map(
                "class", "ModuleManager",
                "arguments", [
                    "@{}",
                    "@manager.event",
                    "@notifier",
                    "@config.app",
                    "@config.modules",
                    "@definition_loader.modules"
                ]
            ),
            "notifier", Map(
                "class", "NotificationService",
                "arguments", ["@notifier.toast"]
            ),
            "notifier.toast", Map(
                "class", "ToastNotifier",
                "arguments", ["@{App}"]
            ),
            "shell", Map(
                "com", "WScript.Shell",
                "props", Map("CurrentDirectory", "@@app_dir")
            ),
            "state.app", Map(
                "class", "AppState",
                "arguments", ["@@state_path", "@version.sorter", "@@version"]
            ),
            "version.sanitizer", "VersionSanitizer",
            "version.sorter", Map(
                "static", "SimpleVersionSorter",
            )
        )
    }

    RunAhkScript(scriptPath) {
        SplitPath(A_AhkPath,, &ahkDir)

        if (ahkDir == "") {
            ahkDir := this.appDir . "\Vendor\AutoHotKey"
        }

        ahkExe := ahkDir . "\AutoHotkey" . (A_Is64bitOS ? "64" : "32") . ".exe"
        SplitPath(scriptPath, &scriptDir)

        if (FileExist(ahkExe) && FileExist(scriptPath)) {
            RunWait(ahkExe . " " . scriptPath,, scriptDir)
        } else {
            throw AppException("Could not run AHK script")
        }
    }

    UpdateIncludes() {
        if (AhkIncludeUpdater(this.appDir).UpdateIncludes()) {
            this.RestartApp()
        }
    }

    BuildApp() {
        scriptPath := this.appDir . "\bin\Build.ahk"

        if (FileExist(scriptPath)) {
            this.RunAhkScript(scriptPath)
        } else {
            throw AppException("Could not locate Build script.")
        }
    }

    AllocConsole() {
        DllCall("AllocConsole")

        if (WinExist("ahk_id " . DllCall("GetConsoleWindow", "ptr"))) {
            WinHide()
        }
    }

    Startup(config := "") {
        if (!config) {
            config := this.startConfig
        }

        SplitPath(A_ScriptName,,,, &appBaseName)

        this.appName := config["appName"] ? config["appName"] : appBaseName
        this.appKey := config["appKey"] ? config["appKey"] : RegExReplace(config["appName"], "[^a-zA-Z]", "")
        this.versionStr := config["version"] ? config["version"] : "1.0.0"
        this.appDir := config["appDir"] ? config["appDir"] : A_ScriptDir
        this.tmpDir := config["tmpDir"] ? config["tmpDir"] : A_Temp . "\" . config["appName"]
        this.dataDir := config["dataDir"] ? config["dataDir"] : A_AppData . "\" . config["appName"]

        if (!DirExist(this.tmpDir)) {
            DirCreate(this.tmpDir)
        }

        if (!DirExist(this.dataDir)) {
            DirCreate(this.dataDir)
        }

        this.LoadServices(config)

        if (!config.Has("useShell") || config("useShell")) {
            this["shell"]
        }

        OnError(ObjBindMethod(this, "OnException"))

        event := AppRunEvent(AppEvents.APP_PRE_INITIALIZE, this, config)
        this["manager.event"].DispatchEvent(event)

        this.InitializeApp(config)

        event := AppRunEvent(AppEvents.APP_POST_INITIALIZE, this, config)
        this["manager.event"].DispatchEvent(event)

        event := AppRunEvent(AppEvents.APP_PRE_RUN, this, config)
        this["manager.event"].DispatchEvent(event)

        this.RunApp(config)

        event := AppRunEvent(AppEvents.APP_POST_STARTUP, this, config)
        this["manager.event"].DispatchEvent(event)
    }

    PreInitializeModules(config) {

    }

    LoadServices(config) {
        this.Services := ServiceContainer(SimpleDefinitionLoader(
            this.GetServiceDefinitions(config),
            this.GetParameterDefinitions(config)
        ))

        this.Services.LoadDefinitions(MapDefinitionLoader(config))
        sdFactory := this["factory.structured_data"]
        serviceFile := this.Parameter["service_files.app"]

        if (FileExist(serviceFile)) {
            this.Services.LoadDefinitions(FileDefinitionLoader(sdFactory, serviceFile))
        }

        this["config.app"]
        this.PreInitializeModules(config)
        this.InitializeModules(config)

        for index, moduleServiceFile in this["manager.module"].GetModuleServiceFiles() {
            if (FileExist(moduleServiceFile)) {
                this.Services.LoadDefinitions(FileDefinitionLoader(sdFactory, moduleServiceFile))
            } else {
                throw ModuleException("Module service file " . moduleServiceFile . " not found")
            }
        }

        ; Reload user config files to ensure they are the active values
        this["config.app"].LoadConfig(true)

        ; Register early event subscribers (e.g. modules)
        this["manager.event"].RegisterServiceSubscribers(this.Services)

        this["manager.event"].Register(AppEvents.APP_SERVICES_LOADED, "AppServices", ObjBindMethod(this, "OnServicesLoaded"))

        event := ServiceDefinitionsEvent(AppEvents.APP_SERVICE_DEFINITIONS, "", "", config)
        this["manager.event"].DispatchEvent(event)

        if (event.Services.Count || event.Parameters.Count) {
            this.Services.LoadDefinitions(SimpleDefinitionLoader(event.Services, event.Parameters))
        }

        serviceFile := this.Parameter["service_files.user"]

        if (FileExist(serviceFile)) {
            this.Services.LoadDefinitions(FileDefinitionLoader(sdFactory, serviceFile))
        }

        ; Register any missing late-loading event subscribers
        this["manager.event"].RegisterServiceSubscribers(this.Services)

        event := AppRunEvent(AppEvents.APP_SERVICES_LOADED, this, config)
        this["manager.event"].DispatchEvent(event)
    }

    OnServicesLoaded(event, extra, eventName, hwnd) {
        this["manager.cache"]
        this["manager.entity_type"].All()
        this["manager.installer"].RunInstallers(InstallerBase.INSTALLER_TYPE_REQUIREMENT)
    }

    InitializeModules(config) {
        includeFiles := this.Parameter["include_files"]
        updated := this["manager.module"].UpdateModuleIncludes(includeFiles["modules"], includeFiles["module_tests"])

        if (updated) {
            message := A_IsCompiled ?
                "Your modules have been updated. Currently, you must recompile " this.appName . " yourself for the changes to take effect. Would you like to exit now (highly recommended)?" :
                "Your modules have been updated, and " this.appName . " must be restarted for the changes to take effect. Would you like to restart now?"

            response := this.ConfirmAction(message, "Module Includes Updated")

            if (response == "Yes") {
                if (A_IsCompiled) {
                    this.ExitApp()
                } else {
                    this.RestartApp()
                }
            }
        }
    }

    ConfirmAction(message, title) {
        return MsgBox(message, title, 4)
    }

    InitializeApp(config) {
        A_AllowMainWindow := false
    }

    RunApp(config) {
        if (this.Config["check_updates_on_start"]) {
            this.CheckForUpdates(false)
        }

        if (this.Services.HasParameter("config_path") && !FileExist(this.Parameter["config_path"])) {
            this.InitialSetup(config)
        }
    }

    ExitApp() {
        event := AppRunEvent(AppEvents.APP_SHUTDOWN, this)
        this["manager.event"].DispatchEvent(event)

        ; TODO Call shutdown hook on services instead of hardcoding?

        if (this.Services.Has("gdip")) {
            Gdip_Shutdown(this.Services["gdip"].GetHandle())
        }

        ExitApp
    }

    RestartApp() {
        event := AppRunEvent(AppEvents.APP_RESTART, this)
        this["manager.event"].DispatchEvent(event)

        if (this.Services.Has("gdip")) {
            Gdip_Shutdown(this.Services["gdip"].GetHandle())
        }

        Reload()
    }

    GetCmdOutput(command, trimOutput := true) {
        output := ""

        if (!this.Services.Has("shell")) {
            throw AppException("The shell is disabled, so shell commands cannot currently be run.")
        }

        result := this["shell"].Exec(A_ComSpec . " /C " . command).StdOut.ReadAll()

        if (trimOutput) {
            result := Trim(result, " `r`n`t")
        }

        return result
    }

    Service(name, params*) {
        nameIsArray := HasBase(name, Array.Prototype)

        if (nameIsArray || (params && params.Length)) {
            results := Map()

            if (!nameIsArray) {
                name := [name]
            }

            for index, arrName in name {
                results[arrName] := this[arrName]
            }

            if (params && params.Length) {
                for index, arrName in params {
                    results[arrName] := this[arrName]
                }
            }

            return results
        }

        return this.Services.Get(name)
    }

    OnException(e, mode) {
        extra := (e.HasProp("Extra") && e.Extra != "") ? "`n`nExtra information:`n" . e.Extra : ""
        occurredIn := e.What ? " in " . e.What : ""

        developer := this.Parameter["app.developer"]

        if (!developer) {
            developer := "the developer(s)"
        }

        errorText := this.appName . " has experienced an unhandled exception. You can find the details below."
        errorText .= "`n`n" . e.Message . extra

        if (!A_IsCompiled) {
            errorText .= "`n`nOccurred in: " . e.What

            if (e.File) {
                errorText .= "`nFile: " . e.File . " (Line " . e.Line . ")"
            }

            if (e.Stack) {
                errorText .= "`n`nStack trace:`n" . e.Stack
            }
        }

        if (this.Services.Has("logger")) {
            this["logger"].Error(errorText)
        }

        errorText .= "`n"

        return this.ShowError("Unhandled Exception", errorText, e, mode != "ExitApp")
    }

    ShowError(title, errorText, err, allowContinue := true) {
        MsgBox(errorText, title)

        if (!allowContinue) {
            this.ExitApp()
        }
    }

    OnTrayIconRightClick(wParam, lParam, msg, hwnd) {
        if (lParam == Events.MOUSE_RIGHT_UP) {
            if (this.Parameter["app.custom_tray_menu"]) {
                this.ShowTrayMenu()
                return 0
            }
        }
    }

    InitialSetup(config) {
        this.isSetup := true
    }

    ShowTrayMenu() {

    }

    __Delete() {
        this.ExitApp()
        super.__Delete()
    }

    Dispatch(event) {
        this["manager.event"].DispatchEvent(event)
    }

    OpenWebsite() {
        websiteUrl := this.Parameter["app.website_url"]

        if (websiteUrl) {
            Run(websiteUrl)
        }
    }

    CheckForUpdates(notify := true) {
        if (this.Parameter["app.supports_update_check"]) {
            updateAvailable := false

            event := ReleaseInfoEvent(AppEvents.APP_GET_RELEASE_INFO, this)
            this.Dispatch(event)
            releaseInfo := event.ReleaseInfo

            if (
                releaseInfo
                && releaseInfo.Has("version")
                && releaseInfo["version"]
                && this["version.sorter"].Compare(this.Version, releaseInfo["version"]) < 0
            ) {
                updateAvailable := true
                this.ShowUpdateMessage(releaseInfo)
            }

            if (!updateAvailable && notify) {
                this["notifier"].Info("You're running the latest version of " . this.appName . ". Shiny!")
            }
        }
    }

    ShowUpdateMessage(releaseInfo) {
        this["notifier"].Info("There is a new version of " . this.appName . " available")
    }
}
