#!/bin/sh

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

VERSION=$1
if [ -z $1 ]
then
  echo "Please provide uniqie hotfix name. Jira ticket number is a good candidate"
  exit 1
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

git flow hotfix start $VERSION

NEXTVERSION=`./bump-minorversion-drynext.sh`
./bump-version.sh $NEXTVERSION
git commit -am "Bumps version to $NEXTVERSION"


# bump hotfix version to server
git push
