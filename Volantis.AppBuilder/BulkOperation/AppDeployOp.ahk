class AppDeployOp extends BulkOperationBase {
    progressTitle := "Deploying App"
    progressText := "Please wait while the application is deployed."
    successMessage := "Deployed to {n} source(s) successfully."
    failedMessage := "{n} source(s) failed to deploy due to errors."
    deployers := ""

    __New(app, deployers, owner := "") {
        if (!HasBase(deployers, Map.Prototype)) {
            deployers := Map("Deployer", deployers)
        }

        this.progressTitle := "Deploying " . app.appName
        this.progressText := "Please wait while " . app.appName . " is deployed."
        this.deployers := deployers
        super.__New(app, owner)
    }

    RunAction() {
        if (this.useProgress) {
            this.progress.SetRange(0, this.deployers.Length)
        }

        version := this.app.Version

        for key, deployer in this.deployers {
            this.StartItem(key, key . ": Deploying...")
            this.results[key] := deployer.Build(version)
            this.FinishItem(key, true, key . ": Finished deploying")
        }
    }
}
