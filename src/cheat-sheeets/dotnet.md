dotnet publish -c Release -r win-x64 --self-contained true

dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=link -p:SelfContained=true -p:DeleteExistingFiles=true



default version> rider
Preferences > Build, Execution, Deployment > Toolset and Build;