#!/bin/sh

# IMPORTANT - THIS FILE IS INTENDED TO BE EXECUTED ONLY IN BAMBOO ENVIRONMENT

set -e

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT AT A FINAL STEP
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT

GITBRANCHFULL=`git rev-parse --abbrev-ref HEAD`
GITBRANCH=`echo "$GITBRANCHFULL" | cut -d "/" -f 1`
RELEASETAG=`echo "$GITBRANCHFULL" | cut -d "/" -f 2`

echo $GITBRANCH
echo $RELEASETAG

if [ $GITBRANCH != "release" ] ; then
   echo "Release can be finished only on release branch!"
   return 1
fi

if [ -z $RELEASETAG ]
then
  echo We expect gitflow to be followed, make sure release branch called release/x.x.x.x
  exit 1
fi


# add remote due to bamboo git cache shit
git remote add central "git@github.com:Voronenko/gitflow-release.git" || true

#Initialize gitflow
git flow init -f -d

# ensure you are on latest develop  & master and return back
git checkout develop
git pull central develop
git checkout -

git checkout master
git pull central master
git checkout -

# UNCOMMENT THESE TWO LINES IF YOU BUMP VERSION AT THE END
#./bump-version.sh $RELEASETAG
#git commit -am "Bumps version to $RELEASETAG"

git flow release finish -m "release $RELEASETAG" $RELEASETAG

git push central develop && git push central master --tags
