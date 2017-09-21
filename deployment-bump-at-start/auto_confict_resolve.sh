#!/bin/sh

set -e

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

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
  exit 1
fi


git push central develop && git push central master --tags
