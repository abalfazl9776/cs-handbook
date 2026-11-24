Msbuild.exe /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="Abel"

msbuild  Presentation.Web.csproj /nologo /nr:false /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="Abel" /p:platform="any cpu" /p:configuration="Release" /p:VisualStudioVersion="16.0" 





/p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="$(Build.ArtifactStagingDirectory)\BasketPanel"


-- use to publish basket agent
msbuild.exe Basket.sln /nologo /nr:false /p:platform="any cpu" /p:configuration="Release" /p:VisualStudioVersion="16.0" 