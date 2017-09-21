#!/bin/sh

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;
VERSION=$1
if [ -z $1 ]
then
  VERSION=`cat version.txt`
fi

#Initialize gitflow
git flow init -f -d

# ensure you are on latest develop  & master
git checkout develop
git pull origin develop
git checkout -

git checkout master
git pull origin master
git checkout develop

git flow release start $VERSION

# bump released version to server
git push

git checkout develop

# COMMENT LINES BELOW IF YOU BUMP VERSION AT THE END
NEXTVERSION=`./bump-version-drynext.sh`
./bump-version.sh $NEXTVERSION
git commit -am "Bumps version to $NEXTVERSION"
git push origin develop
