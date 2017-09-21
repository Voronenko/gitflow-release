 #!/bin/bash

exists()
{
  command -v "$1" >/dev/null 2>&1
}

. ~/.nvm/nvm.sh

node_version="$(nvm version)"
nvmrc_path="$(nvm_find_nvmrc)"

npm=npm

if [ -n "$nvmrc_path" ]; then
   nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

  if [ "$nvmrc_node_version" != "N/A" ] && [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
  fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
fi

node --version

if exists yarn; then
  echo 'Yarn exists!'
else
  echo 'Your system does not have Yarn, installing'
  npm install -g yarn
fi

yarn
if [ $? -eq 0 ]; then
    echo yarn reports node version ok
    npm=yarn
else
    echo yarn does not like your node version, using native npm
fi


rm -rf ./node_modules
$npm install
cp -r bin build
cp -r node_modules build
cp -r public build
cp -r routes build
cp -r views build
cp app.js build
