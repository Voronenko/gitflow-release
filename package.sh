#!/bin/sh
if [ -z "$1" ]
then
  SUFFIX=""
else
  SUFFIX="-$1"
fi

set -x

PROJECT=project-name

rm -rf ./build || true
rm ${PROJECT}-*.tgz || true
mkdir -p ./build || true

CI_SUGGESTED_BRANCH=${CI_COMMIT_BRANCH}
echo "Do we run on supported CI system to detect current branch being built? - ${CI_SUGGESTED_BRANCH}"

if [ -z "$CI_SUGGESTED_BRANCH" ]
then
  VERSION=$(git describe --exact-match 2> /dev/null || echo "`git symbolic-ref HEAD 2> /dev/null | cut -b 12-`-`git log --pretty=format:\"%h\" -1`")
  GITBRANCH=$(git symbolic-ref HEAD 2> /dev/null | sed -e 's,.*/\(.*\),\1,')
else
  VERSION=$CI_SUGGESTED_BRANCH
  GITBRANCH=$CI_SUGGESTED_BRANCH
fi

GITCOMMIT=`git rev-parse --short HEAD`
GITTAG=`git describe --exact-match --tags $(git log -n1 --pretty='%h') 2>/dev/null`
DATE=`date +%Y-%m-%d:%H:%M:%S`

# do build here, that produces necessary files for artifact under build/ folder

echo "project=$PROJECT" > build/version.txt
echo "major_version=$VERSION" >> build/version.txt
echo "minor_version=$1" >> build/version.txt
echo "git_hash=$GITCOMMIT" >> build/version.txt
echo "git_tag=$GITTAG" >> build/version.txt
echo "git_branch=$GITBRANCH" >> build/version.txt
echo "built=$DATE" >> build/version.txt

echo PRODUCING ARTIFACT $PROJECT-$VERSION$SUFFIX.tgz  in build/
cd build
tar cfz  ../$PROJECT-$VERSION$SUFFIX.tgz .
