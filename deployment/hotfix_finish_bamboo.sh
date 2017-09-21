#!/bin/sh

# IMPORTANT - THIS FILE IS INTENDED TO BE EXECUTED ONLY IN BAMBOO ENVIRONMENT

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT AT A FINAL STEP
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT

GITBRANCHFULL=`git rev-parse --abbrev-ref HEAD`
GITBRANCH=`echo "$GITBRANCHFULL" | cut -d "/" -f 1`
HOTFIXTAG=`echo "$GITBRANCHFULL" | cut -d "/" -f 2`
GIT_REMOTE=git@github.com:Voronenko/bamboo-release.git

echo $GITBRANCH
echo $HOTFIXTAG

if [ $GITBRANCH != "hotfix" ] ; then
   echo "Hotfix can be finished only on hotfix branch!"
   return 1
fi

if [ -z $HOTFIXTAG ]
then
  echo We expect gitflow to be followed, make sure hotfix branch called hotfix/ISSUE_NUMBER
  exit 1
fi

# add remote due to bamboo git cache shit
git remote add central "$GIT_REMOTE"

#Initialize gitflow
git flow init -f -d

# ensure you are on latest develop  & master and return back
git checkout develop
git pull central develop
git checkout -

git checkout master
git pull central master
git checkout -

git flow hotfix finish -m "hotfix $HOTFIXTAG" $HOTFIXTAG

git push central develop && git push central master --tags
