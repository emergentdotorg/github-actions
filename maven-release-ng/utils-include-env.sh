#!/usr/bin/env bash

MVNCMD="${MVNCMD:-mvn}"
MAVEN_RELEASE_PLUGIN_FQN="{MAVEN_RELEASE_PLUGIN_FQN:-release}"

failOnError() {
  local rc=$?
  if [ ${rc} -ne 0 ] ; then
    echo "Error, found result code $rc, exiting!"
    exit $rc
  fi
}

normalizeArg() {
  # Fixup goals with the 'release:' prefix
  val="$1"
  if [[ "$val" =~ ^release:.* ]] ; then
      val="${val/^release:/${MAVEN_RELEASE_PLUGIN_FQN}:}"
  fi
  echo "$val"
}

execMvn() {
  declare -a optsArr=( )
  for val in "$@" ; do
    optsArr+=( "$( normalizeArg "$val" )" )
  done
  ${MVNCMD} "${optsArr[@]}"
  failOnError
}

getReleaseProp() {
  if [ -f "release.properties" ] ; then
    grep "^${1}=" release.properties|cut -d'=' -f2
  fi
}

readReleaseProperties() {
  PROJECT_GROUP_ID="$( ${MVNCMD} help:evaluate -Dexpression=project.groupId -q -DforceStdout )"
  PROJECT_ARTIFACT_ID="$( ${MVNCMD} help:evaluate -Dexpression=project.artifactId -q -DforceStdout )"

  MAVEN_SCM_TAG="$( getReleaseProp "scm.tag" )"
  MAVEN_RELEASE_VERSION="$( getReleaseProp "project.rel.${PROJECT_GROUP_ID}\\\\:${PROJECT_ARTIFACT_ID}" )"
  MAVEN_DEVELOPMENT_VERSION="$( getReleaseProp "project.dev.${PROJECT_GROUP_ID}\\\\:${PROJECT_ARTIFACT_ID}" )"

  # For later in this action
  export MAVEN_SCM_TAG
  export MAVEN_RELEASE_VERSION
  export MAVEN_DEVELOPMENT_VERSION
}
