class CliApp extends AppBase {
    GetParameterDefinitions(config) {
        params := super.GetParameterDefinitions(config)

        return params
    }

    GetServiceDefinitions(config) {
        services := super.GetServiceDefinitions(config)

        return services
    }

    InitializeApp(config) {
        super.InitializeApp(config)
    }

    RunApp(config) {
        super.RunApp(config)

    }
}
