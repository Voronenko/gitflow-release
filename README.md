## Introduction

Perhaps most of developers are familiar with git-flow model, that makes release process controlled. In this article I would demonstrate one of approaches to introduce git-flow releasing in your project, capable to be integrated with continious integration tool of your choice, like Atlassian Bamboo provided as an example

## Background

If you never heard about git-flow previously, I suggest to study classic post [http://nvie.com/posts/a-successful-git-branching-model/](http://nvie.com/posts/a-successful-git-branching-model/) && how Atlassian interpret the same idea [https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)

For those, who aware, let me remind well known diagram:

![](https://raw.githubusercontent.com/Voronenko/gitflow-release/master/images/git-workflow-release-cycle-4maintenance.png)

## Implementation - tools

Usually I introduce approach with set of file-helpers that migrate & evolve with each next project. I support idea, that code infrastructure should be stored alongside the project code. Thus usually I have deployment folder where devops scenarios live (usually I use Ansible tool, althouth had experience with CHEF deployments too), and suppose that developers provide me with build logic that outputs target artifact files under buiild/ folder. As a result, typical devops magic structure looks like:

<pre lang="C++">|-- build
|-- deployment
|   |-- release_finish.sh
|   |-- release_finish_bamboo.sh
|   |-- release_start.sh
|   `-- release_start_bamboo.sh
|-- bump-version-drynext.sh
|-- bump-version.sh
|-- package.sh
|-- unpackage.sh
`-- version.txt
</pre>

Let's take a look on files contents & purpose.

#### version.txt

Simple text file, containing current project version. I like idea with git tags in git-flow, but really would prefer to have the possibility to control versioning on my own.  Typical version example is x.y.z:

<pre>
0.0.1
</pre>

#### bump-version-drynext.sh

In most of scenarios of continious integration, subsequent releases change only minor version. Thanks to handy bash script credited in source we have possibility to get value of the next minor version

<pre>➜  releasing  ./bump-version-drynext.sh
0.0.2</pre>

Logic is simple enough - we read current version from version.txt & apply shell magic to get next value.

```shell-script
#!/bin/bash

# credits: http://stackoverflow.com/questions/8653126/how-to-increment-version-number-in-a-shell-script

increment_version ()
{
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


VERSION=`cat version.txt`

increment_version $VERSION

```

#### bump-version.sh

Very important file. Usually I prefer that app version in my project files (like bower.json, package.json) to match current project version. This is the place were patching could be implemented.

What the code does - it applies version parameter to files, and writes new one into version.txt

```shell-script
#!/bin/bash

set -e

CURRENT_DIR=`pwd`
VERSION=$1

echo $VERSION > version.txt

#Optionally - Update your app version in app files, like package.json, bower.json , etc
# Example for nodejs package.json:

#sed -i.bak "s/[[:space:]]*\"version\"[[:space:]]*:[[:space:]]*\".*\",/  \"version\":\"$VERSION\",/g" $CURRENT_DIR/package.json
#rm $CURRENT_DIR/package.json.bak || true

```

#### package.sh

This logic allows to create tgz-ipped artifact file either in form project-name-version.tgz or in form project-name-version-buildnumber.tgz ; The latest case could be important, if you need to store artifacts history for every build.

File can be adjusted by changing PROJECT variable to match your project name. In addition, if you ever wanted to know more information about artifact, it packs version.txt file, which contains information about major_version, minor_version, git_hash, and built date. With this info you can identify commit that was used to produce the build.

In addition, such files can be easily read by build servers like bamboo or jenkins & transformed into internal variables.

Resulting files are placed in build/ and packed.

```shell-script
#!/bin/sh
if [ -z "$1" ]
then
  SUFFIX=""
else
  SUFFIX="-$1"
fi

PROJECT=project-name

rm -rf ./build || true
rm ${PROJECT}-*.tgz || true
mkdir -p ./build || true

VERSION=`cat version.txt`
GITCOMMIT=`git rev-parse --short HEAD`
DATE=`date +%Y-%m-%d:%H:%M:%S`

# do build here, that produces necessary files for artifact under build/ folder

echo "major_version=$VERSION" > build/version.txt
echo "minor_version=$1" >> build/version.txt
echo "git_hash=$GITCOMMIT" >> build/version.txt
echo "built=$DATE" >> build/version.txt

echo PRODUCING ARTIFACT $PROJECT-$VERSION$SUFFIX.tgz  in build/
tar cfz  $PROJECT-$VERSION$SUFFIX.tgz build
```

#### Unpackage.sh

This file is usually executed on a next step in build process, when artifact was previously packed by build step, and now you need to do smth with content, for example initiate deployment. In 100% scenarios I would expect only one artifact file, but if there are several versions, I pick only the most recent one.

In a result, you will get unpacked artifact in build folder.

```shell-script
#!/bin/sh
PROJECT=project-name
rm -rf ./build || true
current_artefact=$(find ./${PROJECT}*.tgz -type f -exec stat -c "%n" {} + | sort | head -n1)
echo Working with artefact: $current_artefact
tar xvzf $current_artefact
echo artefact unpacked: $current_artefact

```

#### deployment/release_start.sh

What it does - it creates the release, and pushes release branch to server, so the continious integration tool can pick it up and build. I have to say that some portion of holy war is present here: when to bump version. I had two types of the customers: customer - BEGIN insist, that version.txt contains version he is going to release, thus once I start release process, I should immediate bump version up in the develop, as all new features there will belong to the next release. From other hand, customer-END usually does not care on version.txt, and per his understanding, bumping the version is the final step in the release - i.e. after that push everything that was commited previously was 0.0.1 ongoing development and now we have released 0.0.2\.  I would prefer to bump version at the end. As you see both approaches are supported with litle commenting.

This batch implements release start by either providing new release version as a parameter, or getting the one from version.txt

```shell-script
#!/bin/sh

cd ${PWD}/../
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

```

#### deployment/release_finish.sh

Fortunately, this step does not require any external parameters. Current release version is detected from the branch name (release/0.0.2) and rest of the steps are clear. Again here, if you follow the classic bump-the-version approach - you would need to uncomment "./bump-version.sh $RELEASETAG"

```shell-script
#!/bin/sh

cd ${PWD}/../

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

```

## Linking to build server

All popular build servers support branches detecting and building. For example, Atlassian Bamboo has this easily configurable via UI , while, for example, for Jenkins you will need to play more.

![](https://raw.githubusercontent.com/Voronenko/gitflow-release/master/images/bamboo_release_branch.png)

Process on a build server could be implemented in a way, that allows to initiate release from the develop branch using optional build step:

![](https://raw.githubusercontent.com/Voronenko/gitflow-release/master/images/bamboo_release_start.png)

And introduce possiblility to finalize release as a optional step on a release branch:

![](https://raw.githubusercontent.com/Voronenko/gitflow-release/master/images/bamboo_release_finish.png)

If you try to use recipes without adjustments, you will get into trouble, as almost any build server for speed and size advantages does not checkout complete repository  history, thus steps will fail.

For bamboo, following "hack" might be introduced: we are manually setting the new remote, with command **git remote add central "$GIT_REMOTE" **, and all subsequent operations implement with custom remote.

#### deployment/release_start_bamboo.sh

Please find below slightly modified release_start for bamboo:

```shell-script
#!/bin/sh

cd ${PWD}/../

VERSION=$1
if [ -z $1 ]
then
  VERSION=`cat version.txt`
fi

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT
GIT_REMOTE=git@github.com:Voronenko/gitflow-release.git

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

```

#### deployment/release_finish_bamboo.sh

```shell-script
#!/bin/sh

# IMPORTANT - THIS FILE IS INTENDED TO BE EXECUTED ONLY IN BAMBOO ENVIRONMENT

cd ${PWD}/../

# PREVENT INTERACTIVE MERGE MESSAGE PROMPT AT A FINAL STEP
GIT_MERGE_AUTOEDIT=no
export GIT_MERGE_AUTOEDIT

GITBRANCHFULL=`git rev-parse --abbrev-ref HEAD`
GITBRANCH=`echo "$GITBRANCHFULL" | cut -d "/" -f 1`
RELEASETAG=`echo "$GITBRANCHFULL" | cut -d "/" -f 2`
GIT_REMOTE=git@github.com:Voronenko/gitflow-release.git

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

# UNCOMMENT THESE TWO LINES IF YOU BUMP VERSION AT THE END
#./bump-version.sh $RELEASETAG
#git commit -am "Bumps version to $RELEASETAG"

git flow release finish -m "release $RELEASETAG" $RELEASETAG

git push central develop && git push central master --tags

```

## Points of Interest

Potentially, you can reuse approach to your own projects with minimal adaptation. If you would use that approach with different build server, I would be grateful if you share your experience. If you need to implement continious integration on your project - you are welcome.

Mentioned samples could be seen or forked from  [https://github.com/Voronenko/gitflow-release](https://github.com/Voronenko/gitflow-release)
