#!/bin/sh

set -e

# IMPORTANT - THIS FILE IS INTENDED TO BE EXECUTED ONLY IN BAMBOO ENVIRONMENT

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT AT A FINAL STEP
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT

GITBRANCHFULL=`git rev-parse --abbrev-ref HEAD`
GITBRANCH=`echo "$GITBRANCHFULL" | cut -d "/" -f 1`
HOTFIXTAG=`echo "$GITBRANCHFULL" | cut -d "/" -f 2`

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

set +e
git checkout develop
git merge $GITBRANCHFULL
set -e

# attempt automatic conflict resolve

FILES_IN_CONFLICT=`git diff --name-only --diff-filter=U | wc -l`
echo "Conflicted files: $FILES_IN_CONFLICT"

if [ $FILES_IN_CONFLICT -gt 2 ] ; then
  echo "Looks like hotfix introduced conflicts( $FILES_IN_CONFLICT ). Please resolve manually"
  exit 1
fi

if [ "$FILES_IN_CONFLICT" = "2" ] ; then

  VERSION_IN_CONFLICT=`git diff --name-only --diff-filter=U | grep version.txt`
  if [ "$VERSION_IN_CONFLICT" = "version.txt" ] ; then
   git checkout --ours version.txt
   git add version.txt
  fi

  PACKAGE_JSON_IN_CONFLICT=`git diff --name-only --diff-filter=U | grep package.json`
  if [ "$PACKAGE_JSON_IN_CONFLICT" = "package.json" ] ; then
   git checkout --ours package.json
   git add package.json
  fi

  git commit -am "automatic version fix by hotfix-finish routine"

fi

FILES_IN_CONFLICT=`git diff --name-only --diff-filter=U | wc -l`

if [ "$FILES_IN_CONFLICT" = "0"  ] ; then
  echo "EVERYTHING SMOOTHLY - NO CONFLICTS"
fi

if [ "$FILES_IN_CONFLICT" != "0"  ] ; then
  echo "PROBLEM: STILL FILES IN CONFLICT"
  git diff --name-only --diff-filter=U
  git reset --hard
  exit 1
fi

git checkout $GITBRANCHFULL

git flow hotfix finish -m "hotfix $HOTFIXTAG" $HOTFIXTAG


git push central develop && git push central master --tags
