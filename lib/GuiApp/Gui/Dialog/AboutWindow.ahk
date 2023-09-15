class AboutWindow extends DialogBox {
    GetDefaultConfig(container, config) {
        defaults := super.GetDefaultConfig(container, config)
        defaults["title"] := "About " . container.GetApp().appName
        defaults["buttons"] := "*&OK"
        return defaults
    }

    Controls() {
        super.Controls()
        this.SetFont("xl", "Bold")
        this.guiObj.AddText("w" . this.windowSettings["contentWidth"], this.app.appName)
        this.SetFont("large", "Bold")
        this.guiObj.AddText("w" . this.windowSettings["contentWidth"] . " y+" . (this.margin/2), this.app.Parameter["app.short_description"])
        this.SetFont("")
        version := this.app.Version

        if (version == "{{VERSION}}") {
            version := "Git"
        }

        this.guiObj.AddText("w" . this.windowSettings["contentWidth"] . " y+" . (this.margin/2),  "Version: " . version)

        text := ""

        if (this.app.Parameter["app.long_description"]) {
            text := this.app.Parameter["app.long_description"]
        }

        if (this.app.Parameter["app.by_line"]) {
            if (text != "") {
                text .= "`n`n"
            }

            text .= this.app.Parameter["app.by_line"]
        }

        if (text != "") {
            text .= "`n"
        }

        this.guiObj.AddText("w" . this.windowSettings["contentWidth"], text)

        position := "Wrap x" . this.margin . " y+" . this.margin
        options := position . " w" . this.windowSettings["contentWidth"] . " +0x200 c" . this.themeObj.GetColor("textLink")

        for appLink in this.app.Parameter["app.links"] {
            this.guiObj.AddLink(options, appLink)
        }
    }
}
