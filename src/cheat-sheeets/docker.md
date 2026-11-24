docker -l debug  build . --no-cache  -t riskback --build-arg nuget=https://repo.asax.ir/public/nuget/index.json 
docker build -f mydockerfilepath -t myimagename .

docker engine settings
  "registry-mirrors": [
    "https://repo.asax.ir",
    "https://registry.docker.ir",
    "https://docker.iranrepo.ir"
  ]


//////////////////


# accessing localmachine ports from docker container:
use this host name : host.docker.internal

for example:
"constring": "Data Source=host.docker.internal;Initial Catalog=FundRiskAssessment;User Id=sa;Password=1qaz;TrustServerCertificate=true;Application Name=FundRiskAssessment"


///////////////

-- start interactive docker container of an image
docker run --rm -it [image]

-- start interactive docker container of an image with shell playground
docker run --rm -it [image] sh


//////////////////


-- get version of a docker image:
-- this command runs a container, executes a command inside it and removes the container after executing the command.
docker run --rm nginx:latest nginx -v

-- info about an image
docker image inspect nginx:latest

///////////////

