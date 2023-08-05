class AppBuildOp extends BulkOperationBase {
    progressTitle := "Building App"
    progressText := "Please wait while the application is built."
    successMessage := "Ran {n} builder(s) successfully."
    failedMessage := "{n} builder(s) failed to run due to errors."
    builders := ""

    __New(app, builders, owner := "") {
        if (!HasBase(builders, Array.Prototype)) {
            builders := [builders]
        }

        this.progressTitle := "Building " . app.appName
        this.progressText := "Please wait while " . app.appName . " is built."
        this.builders := builders
        super.__New(app, owner)
    }

    RunAction() {
        if (this.useProgress) {
            this.progress.SetRange(0, this.builders.Length)
        }

        version := this.app.Version

        for index, builder in this.builders {
            key := builder.name
            this.StartItem(key, key . ": Building...")
            this.results[key] := builder.Build(version)
            this.FinishItem(key, true, key . ": Finished building")
        }
    }
}
