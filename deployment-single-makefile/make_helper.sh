#!/bin/bash

set -e

function bump_version(){

  if [ -z "$1" ]
  then
    echo "Pass version as param 1"
    return 1
  fi

CURRENT_DIR=`pwd`
VERSION=$1

if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

echo $VERSION > version.txt

#Optionally - Update your app version in app files, like package.json, bower.json , etc
# Example for nodejs package.json:

#sed -i.bak "s/[[:space:]]*\"version\"[[:space:]]*:[[:space:]]*\".*\",/  \"version\":\"$VERSION\",/g" $CURRENT_DIR/package.json
#rm $CURRENT_DIR/package.json.bak || true


}



# =================================================
# BELOW THIS LINE STARTS UNCHANGABLE PART OF SCRIPT
# =================================================

# =====================================
# 0.0.1 => 0.0.2
function _bump_minor_version_dry(){
  if [ -z "$1" ]
  then
    echo "Pass version as param 1"
    return 1
  fi

  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1

  for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    [ ${#new} -gt $len ] && carry=1 || carry=0
    [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
  done
  new="${part[*]}"
  echo -e "${new// /.}"
}

# =====================================
# 0.0.1 => 0.1.0

function _bump_version_dry(){
  if [ -z "$1" ]
  then
    echo "Pass version as param 1"
    return 1
  fi

  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1

  for (( CNTR=${#part[@]}-2; CNTR>=0; CNTR-=1 )); do
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    [ ${#new} -gt $len ] && carry=1 || carry=0
    [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
  done
  part[2]=0 #zerorify minor version
  new="${part[*]}"
  echo -e "${new// /.}"
}

# =====================================

function package(){
if [ -z "$1" ]
then
  SUFFIX=""
else
  SUFFIX="-$1"
fi

if [ -z "$PROJECT_NAME" ]
then
  echo "Please set PROJECT_NAME"
  return 1
fi

if [ -z "$PROJECT_VERSION" ]
then
  echo "Please set PROJECT_VERSION"
  return 1
fi


echo "Packaging ${PROJECT_NAME}(${PROJECT_VERSION}${SUFFIX})"

rm -rf ./build || true
rm -f ${PROJECT_NAME}-*.tgz || true
mkdir -p ./build || true

GITCOMMIT=`git rev-parse --short HEAD`
GITTAG=`git describe --exact-match --tags $(git log -n1 --pretty='%h') 2>/dev/null || true`
DATE=`date +%Y-%m-%d:%H:%M:%S`

echo "major_version=${PROJECT_VERSION}" > build/version.txt
echo "minor_version=$1" >> build/version.txt
echo "git_hash=$GITCOMMIT" >> build/version.txt
echo "git_tag=$GITTAG" >> build/version.txt
echo "built=$DATE" >> build/version.txt

echo PRODUCING ARTIFACT ${PROJECT_NAME}-${PROJECT_VERSION}$SUFFIX.tgz  in build/
cd build && tar cfz  ../${PROJECT_NAME}-${PROJECT_VERSION}$SUFFIX.tgz .

}

# =====================================

function unpackage(){
if [ -z "$1" ]
then
  echo "Please pass PROJECT_NAME as parameter"
  return 1
else
  PROJECT_NAME="$1"
fi

current_artefact=$(find ./${PROJECT_NAME}*.tgz -type f -exec stat -c "%n" {} + | sort | head -n1)
echo Working with artefact: $current_artefact
tar xvzf $current_artefact
echo artefact unpacked: $current_artefact
}


# =GITFLOW SUPPORT==================================

function gitflow_release_start(){
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
NEXTVERSION=$(_bump_version_dry $VERSION)
$(bump_version $NEXTVERSION)

git commit -am "Bumps version to $NEXTVERSION"
git push origin develop

# return to release version for further operations
git checkout -
}

function gitflow_release_finish(){

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
  echo We expect gitflow to be followed, make sure release branch called release/x.x.x
  exit 1
fi

#Initialize gitflow
git flow init -f -d

# ensure you are on latest develop  & master and return back
git checkout develop
git pull origin develop
git checkout -

git checkout master
git pull origin master
git checkout -

# UNCOMMENT THESE TWO LINES IF YOU BUMP VERSION AT THE END
#./bump-version.sh $RELEASETAG
#git commit -am "Bumps version to $RELEASETAG"

git flow release finish -m "release $RELEASETAG" $RELEASETAG

git push origin develop && git push origin master --tags


}


function gitflow_hotfix_start(){
if [ ! -d "./.git" ];then cd $(git rev-parse --show-cdup); fi;

if [ -z $1 ]
then
  echo "Please provide uniqie hotfix name. Jira ticket number is a good candidate"
  exit 1
else
  HOTFIX_NAME=$1
fi

if [ -z $2 ]
then
  VERSION=`cat version.txt`
  NEXTVERSION=$(_bump_minor_version_dry $VERSION)
  $(bump_version $NEXTVERSION)
else
  NEXTVERSION=$2
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

git flow hotfix start $HOTFIX_NAME

git commit -am "Bumps version to $NEXTVERSION"

# bump hotfix version to server
git push
}

function gitflow_hotfix_finish(){

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
     echo "Hotfix can be finished only on a hotfix branch!"
     return 1
  fi

  if [ -z $HOTFIXTAG ]
  then
    echo We expect gitflow to be followed, make sure hotfix branch called hotfix/x.x.x.x
    exit 1
  fi

  #Initialize gitflow
  git flow init -f -d

  # ensure you are on latest develop  & master and return back
  git checkout develop
  git pull origin develop
  git checkout -

  git checkout master
  git pull origin master
  git checkout -

  git flow hotfix finish -m "hotfix $HOTFIXTAG" $HOTFIXTAG

  git push origin develop && git push origin master --tags

}

# Allows to call a function based on arguments passed to the script
# ./make_helper.sh package  "243"
$*
