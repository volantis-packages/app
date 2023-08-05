class AppBuilderBase extends AppBase {
    GetParameterDefinitions(config) {
        parameters := super.GetParameterDefinitions(config)
        parameters["config_path"] := "@@{app_dir}\@@{app_name}.build.json"
        parameters["config.dist_dir"] := "@@{app_dir}\Dist"
        parameters["config.build_dir"] := "@@{app_dir}\Build"
        parameters["config.icon_file"] := "@@{app_dir}\Resources\Graphics\@@{app_name}.ico"
        parameters["config.github_username"] := ""
        parameters["config.github_token"] := ""
        parameters["config.github_repo"] := ""
        parameters["config.cleanup_build_artifacts"] := false
        parameters["config.makensis"] := "C:\Program Files (x86)\NSIS\makensis.exe"
        parameters["config.open_build_dir"] := false
        parameters["config.open_dist_dir"] := true
        parameters["config.choco_pkg_name"] := this.GetChocoName()
        return parameters
    }

    /**
     * Libraries to copy from Lib directory to the Build directory.
     */
    GetBuildLibs() {
        return ['Shared']
    }

    /**
     * Libraries to copy from Vendor directory to the Build directory.
     */
    GetVendorLibs() {
        return []
    }

    GetChocoName() {
        name := StrLower(this.appName)
        StrReplace(name, " ", "-")
        return name
    }

    GetServiceDefinitions(config) {
        services := super.GetServiceDefinitions(config)

        services["FileHasher"] := "FileHasher"

        services["GitTagBuildVersionIdentifier"] := Map(
            "class", "GitTagBuildVersionIdentifier",
            "arguments", AppRef()
        )

        return services
    }

    RunApp(config) {
        super.RunApp(config)

        version := this["GitTagBuildVersionIdentifier"].IdentifyVersion()

        buildInfo := this["manager.gui"].Dialog(Map(
            "type", "BuildSettingsForm",
            "version", version
        ))

        if (!buildInfo) {
            this.ExitApp()
        }

        version := buildInfo.Version

        if (!version) {
            throw AppBuildException("Version not provided.")
        }

        this.Version := version
        this.CreateGitTag(version)

        success := AppBuildOp(this, this.GetBuilders(buildInfo)).Run()

        if (!success) {
            throw AppBuildException(this.appName . "build failed. Skipping deploy...")
        }

        if (buildInfo.DeployToGitHub || buildInfo.DeployToChocolatey) {
            releaseInfo := this["manager.gui"].Dialog(Map("type", "ReleaseInfoForm"))

            if (!releaseInfo) {
                this.ExitApp()
            }

            success := AppDeployOp(this, this.GetDeployers(buildInfo)).Run()

            if (!success) {
                throw AppBuildException(this.appName . " deployment failed. You might need to handle things manually...")
            }
        }

        TrayTip("Finished building " . this.appName . "!", this.appName . " Builder", 1)
        this.ExitApp()
    }

    GetBuilders(buildInfo) {
        builders := []

        if (buildInfo.BuildApp) {
            builders.Push(AhkExeBuilder(this))

            if (buildInfo.BuildInstaller) {
                builders.Push(NsisInstallerBuilder(this))

                if (buildInfo.BuildChocoPkg) {
                    builders.Push(ChocoPkgBuilder(this))
                }
            }
        }

        return builders
    }

    GetDeployers(buildInfo) {
        deployers := Map()

        if (buildInfo.DeployToGitHub) {
            deployers["GitHub"] := GitHubBuildDeployer(this)
        }

        if (buildInfo.DeployToApi) {
            deployers["Api"] := ApiBuildDeployer(this)
        }

        if (buildInfo.DeployToChocolatey) {
            deployers["Chocolatey"] := ChocoDeployer(this)
        }

        return deployers
    }

    CreateGitTag(version) {
        if (!this.GetCmdOutput("git show-ref " . version)) {
            RunWait("git tag " . version, this.appDir)

            response := this["manager.gui"].Dialog(Map(
                "title", "Push git tag?",
                "text", "Would you like to push the git tag that was just created (" . version . ") to origin?"
            ))

            if (response == "Yes") {
                RunWait("git push origin " . version, this.appDir)
            }
        }
    }

    InitialSetup(config) {
        ; TODO: Ask initial build setup questions and store them in the config file
    }

    CheckForUpdates(notify := true) {
        ; TODO: Offer to pull the latest git code if it's outdated, and then restart the script if updates were applied
    }

    ExitApp() {
        this.CleanupBuild()
        super.ExitApp()
    }

    CleanupBuild() {
        if (this.Config["cleanup_build_artifacts"]) {
            if (DirExist(this.Config["build_dir"])) {
                DirDelete(this.Config["build_dir"], true)
            }
        }
    }
}
