# Boilerplate usage

1. Implement project specific `clean_build.sh` to build project artifact inside `/build` folder.

2. Put semantic version file `version.txt` in the root (starting with `0.0.1` at the beginning of the development)

3. If you want to write project version into some custom files - adjust `bump_version` inside `make_helper.sh`

4. Adjust Makefile, set `PROJECT_NAME` constant to match project name

5. make file actions

5.1 `make build` - builds project (by invoking `clean_build.sh`)

5.2 `make test` - if implemented, runs tests over project

5.3 `make package $suffix` - packages artifact into `${PROJECT_NAME}(${PROJECT_VERSION}${SUFFIX}.tgz` , suffix optional, can be build number, if you need to distinguish artifacts between builds. In other case, build overwrites previous artifact. Make sure you've build project before.

5.4 `make unpackage` - looks for last file that matches mask `${PROJECT_NAME}(${PROJECT_VERSION}${SUFFIX}.tgz` and unpacks it.

5.5 `make release-start`  - starts release from develop branch via `gitflow release start`

5.6 `make release-finish`  - finishes release from release branch via `gitflow release finish`

5.7 `make hotfix-start HOTFIX_NAME`  - starts hotfix named HOTFIX_NAME from master branch via `gitflow hotfix start`

5.8 `make hotfix-finish`  - finishes hotfix from hotfix branch via `gitflow hotfix finish`
