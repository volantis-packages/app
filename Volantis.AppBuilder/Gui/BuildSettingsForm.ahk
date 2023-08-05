class BuildSettingsForm extends FormGuiBase {
    GetDefaultConfig(container, config) {
        defaults := super.GetDefaultConfig(container, config)
        defaults["title"] := "Build Settings"
        defaults["text"] := "Fill in the information below and click Build to start the build process."
        defaults["buttons"] := "*&Build|&Cancel"
        defaults["version"] := container.GetApp().Version
        return defaults
    }

    Controls() {
        super.Controls()

        this.AddHeading("Application Version")
        this.guiObj.AddText("y+" (this.margin/2) . " w" . this.windowSettings["contentWidth"], "This is the version that will be built. Entering a new version will create a git tag, and if you later choose to make a GitHub release, the tag will be pushed to the repository.")
        this.AddEdit("Version", this.config["version"], "", 150)

        this.AddHeading("Build Options")
        this.BuildOptions()

        this.AddHeading("Deployment Options")
        this.DeploymentOptions()
    }

    BuildOptions() {
        this.AddCheckBox("Build " . this.app.appName . ".exe", "BuildApp", true, false, "OnCheckbox")
        this.AddCheckBox("Build installer", "BuildInstaller", false, false, "OnCheckbox")
        this.AddCheckBox("Build chocolatey package (Experimental)", "BuildChocoPkg", false, false, "OnCheckbox")
    }

    DeploymentOptions() {
        this.AddCheckBox("Deploy release to GitHub (Experimental)", "DeployToGitHub", false, false, "OnCheckbox")
        this.AddCheckBox("Deploy chocolatey package (Experimental)", "DeployToChocolatey", false, false, "OnCheckbox")
    }

    ProcessResult(result, submittedData := "") {
        return (result == "Build") ? submittedData : ""
    }
}
