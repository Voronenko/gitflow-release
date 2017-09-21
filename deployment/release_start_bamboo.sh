#!/bin/sh

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

VERSION=$1
if [ -z $1 ]
then
  VERSION=`cat version.txt`
fi

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT
GIT_REMOTE=git@github.com:Voronenko/bamboo-release.git

# add remote due to bamboo git cache shit
git remote add central "$GIT_REMOTE"

#Initialize gitflow
git flow init -f -d

# ensure you are on latest develop  & master
git checkout develop
git pull central develop
git checkout -

git checkout master
git pull central master
git checkout develop

git flow release start $VERSION

# bump released version to server
git push central release/$VERSION

git checkout develop

# COMMENT LINES BELOW IF YOU BUMP VERSION AT THE END
NEXTVERSION=`./bump-version-drynext.sh`
./bump-version.sh $NEXTVERSION
git commit -am "Bumps version to $NEXTVERSION"
git push central develop
