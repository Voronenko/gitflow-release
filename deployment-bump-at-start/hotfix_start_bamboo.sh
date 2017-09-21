#!/bin/sh

set -e

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

VERSION=$1
if [ -z $1 ]
then
  echo "Please provide uniqie hotfix name. Jira ticket number is a good candidate"
  exit 1
fi

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT

# add remote due to bamboo git cache shit
git remote add central "git@github.com:Voronenko/gitflow-release.git" || true

#Initialize gitflow
git flow init -f -d

# ensure you are on latest develop  & master
git checkout develop
git pull central develop
git checkout -

git checkout master
git pull central master
git checkout develop

git flow hotfix start $VERSION

NEXTVERSION=`./bump-minorversion-drynext.sh`
./bump-version.sh $NEXTVERSION
git commit -am "Bumps version to $NEXTVERSION"

# bump hotfixed version to server
git push central hotfix/$VERSION
