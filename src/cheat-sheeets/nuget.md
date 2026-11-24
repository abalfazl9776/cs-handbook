// How to install a nuget package from a single file (.nupkg) locally?
// NuGet usually expects a feed folder, not a single file, so the normal approach is still to place the .nupkg into a folder and add that folder as a source.


--Step 1: Put the package in a folder
C:\LocalNuGetPackages\MyLibrary.1.0.0.nupkg


--Step 2: Add that folder as a source
dotnet nuget add source "C:\LocalNuGetPackages" --name LocalPackages


--Step 3: Install the package in your project
dotnet add package MyLibrary --version 1.0.0






-------------------dependencies----------------------
dotnet nuget why Asa.Mdp.Protobuf.External

dotnet list package --include-transitive