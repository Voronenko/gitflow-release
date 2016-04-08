#!/bin/bash

# credits: http://stackoverflow.com/questions/8653126/how-to-increment-version-number-in-a-shell-script
# increments minor version, i.e. 0.17.1 => 0.17.2

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
