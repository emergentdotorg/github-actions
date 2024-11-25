#!/usr/bin/env bash

doUntag() {
  git tag -d "$1" ; git push origin --delete "$1"
}

doDeploy() {
  mvn -B \
    -DaltDeploymentRepository=dist::file:///tmp/repo/combined \
    deploy
}

doClean() {
  mvn -B \
    -DpushChanges=false \
    -DlocalCheckout=true \
    -Darguments="-DaltDeploymentRepository=dist::file:///tmp/repo/altrepo" \
    release:clean
}

doRelease() {
  mvn -B \
    -DpushChanges=false \
    -DlocalCheckout=true \
    -Darguments="-Dgpg.skip=true -DaltDeploymentRepository=dist::file:///tmp/repo/altrepo" \
    release:prepare release:perform "$@"
}

doPrepare() {
  mvn -B \
    -DpushChanges=false \
    -DlocalCheckout=true \
    -Darguments="-Dgpg.skip=true -DaltDeploymentRepository=dist::file:///tmp/repo/altrepo" \
    release:prepare "$@"
}

doBrancb() {
  mvn -B \
    -DbranchName="$1" \
    -DlocalCheckout=true \
    -Darguments="-DaltDeploymentRepository=dist::file:///tmp/altrepo" \
    release:branch release:perform
}

doVersion() {
  mvn -B \
    -DnewVersion="$1" \
    -DgenerateBackupPoms=false \
    -DprocessAllModules=true \
    org.codehaus.mojo:versions-maven-plugin:2.18.0:set
}

cmd="$1" ; shift
case "$cmd" in
  untag)
    doUntag "$@"
    ;;
  clean)
    doClean "$@"
    ;;
  deploy)
    doDeploy "$@"
    ;;
  release)
    doRelease "$@"
    ;;
  prepare)
    doPrepare "$@"
    ;;
  branch)
    doRelease "$@"
    ;;
  version)
    doVersion "$@"
    ;;
  *)
    echo "Unknown cmd: $cmd"
    ;;
esac
