#!/bin/bash

set -e

CURRENT_DIR=`pwd`
VERSION=$1

echo $VERSION > version.txt

#Optionally - Update your app version in app files, like package.json, bower.json , etc
# Example for nodejs package.json:

#sed -i.bak "s/[[:space:]]*\"version\"[[:space:]]*:[[:space:]]*\".*\",/  \"version\":\"$VERSION\",/g" $CURRENT_DIR/package.json
#rm $CURRENT_DIR/package.json.bak || true

