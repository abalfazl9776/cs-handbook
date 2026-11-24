"Serilog": {
    "Using": [
      "Serilog.Formatting.Elasticsearch"
    ],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Information",
        "Microsoft.Extensions.Diagnostics.HealthChecks.DefaultHealthCheckService": "Error",
        "System": "Error"
      }
    },
    "Enrich": [
      "FromLogContext",
      "WithMachineName",
      "WithAssemblyInformationalVersion",
      "WithAssemblyName",
      "WithExceptionDetails"
    ],
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "log.txt",
          "rollingInterval": "Day"
        }
      },
      {
        "Name": "Console",
        "Args": {
          "restrictedToMinimumLevel": "Debug",
          "outputTemplate": "{NewLine}{NewLine}{Timestamp:HH:mm:ss.fff}[{Level:u3}]{Properties:j}{Message:j}{Exception:j}",
          "theme": "Serilog.Sinks.SystemConsole.Themes.AnsiConsoleTheme::Code, Serilog.Sinks.Console"
        }
      }
    ]
  }