npm config edit

npm config set registry <registry url>

npm config set registry https://package-mirror.liara.ir/repository/npm/


// in .npmrc file
registry=https://repo.asax.ir/public/npm/
or
registry=https://repo.asax.ir/repository/npm-fdp-group/


// build with limited resource
node --max-old-space-size=2048 ./node_modules/@angular/cli/bin/ng build