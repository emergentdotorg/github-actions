#!/usr/bin/env bash

set -e

DEBUG="${DEBUG:-false}"

# defaults
MAVEN_RELEASE_PLUGIN_VER="${MAVEN_RELEASE_PLUGIN_VER:-3.1.1}"
MAVEN_RELEASE_PUSH_CHANGES="${MAVEN_RELEASE_PUSH_CHANGES:-true}"

if [ "$DEBUG" = "true" ] ; then
  echo MAVEN_LOCAL_REPO_PATH="${MAVEN_LOCAL_REPO_PATH}"
  echo MAVEN_NEXT_RELEASE_VER="${MAVEN_NEXT_RELEASE_VER}"
  echo MAVEN_NEXT_SNAPSHOT_VER="${MAVEN_NEXT_SNAPSHOT_VER}"
  echo MAVEN_RELEASE_PLUGIN_VER="${MAVEN_RELEASE_PLUGIN_VER}"
  echo MAVEN_RELEASE_PUSH_CHANGES="${MAVEN_RELEASE_PUSH_CHANGES}"
fi

failOnError() {
  local rc=$?
  if [ ${rc} -ne 0 ] ; then
    echo "Error, found result code $rc, exiting!"
    exit $rc
  fi
  return $rc
}

normalizeGoal() {
  val="$1"
	if [ -n "${MAVEN_RELEASE_PLUGIN_VER}" ] && [[ "$val" =~ ^release:.* ]] ; then
			val="${val/^release:/org.apache.maven.plugins:maven-release-plugin:${MAVEN_RELEASE_PLUGIN_VER}:}"
	fi
  echo "$val"
}

function loadArgData {
	declare -n arrRef="$1"

	readarray -t optser	<<<"$(grep -v 'missingno' <<-EOF
		-Dresume=false
		-DlocalCheckout=true
		-DtagNameFormat=@{project.version}
		-DscmCommentPrefix=[GitHub]
		-Darguments=-Dmaven.javadoc.skip=true
		-DpushChanges=${MAVEN_RELEASE_PUSH_CHANGES:-missingno}
		-Dmaven.repo.local=${MAVEN_LOCAL_REPO_PATH:-missingno}
		-DreleaseVersion=${MAVEN_NEXT_RELEASE_VER:-missingno}
		-DdevelopmentVersion=${MAVEN_NEXT_SNAPSHOT_VER:-missingno}
		EOF
		)"
	arrRef+=( "${optser[@]}" )

  #	readarray -t argser <<<"$( grep -v 'missingno' <<-EOF |
  #		-s ${MAVEN_USER_SETTINGS_PATH:-missingno}
  #		EOF
  #		{ while read -r k1 v1; do printf '%s\n%s\n' "$k1" "$v1" ; done })"
  #	arrRef+=( "${argser[@]}" )
}

getRelProp() {
  grep "^${1}=" release.properties|cut -d'=' -f2
}

loadVersionsInfo() {
  PROJECT_GROUP_ID="$(mvn help:evaluate -Dexpression=project.groupId -q -DforceStdout)"
  PROJECT_ARTIFACT_ID="$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)"
  MAVEN_RELEASE_TAG="$( getRelProp "scm.tag" )"
  MAVEN_RELEASE_VERSION="$( getRelProp "project.rel.${PROJECT_GROUP_ID}\\\\:${PROJECT_ARTIFACT_ID}" )"
  MAVEN_SNAPSHOT_VERSION="$( getRelProp "project.dev.${PROJECT_GROUP_ID}\\\\:${PROJECT_ARTIFACT_ID}" )"

	[ -n "${MAVEN_RELEASE_TAG}" ] || { echo "Failed loading MAVEN_RELEASE_TAG" ; return 1 ; }
	[ -n "${MAVEN_RELEASE_VERSION}" ] || { echo "Failed loading MAVEN_RELEASE_VERSION" ; return 1 ; }
	[ -n "${MAVEN_SNAPSHOT_VERSION}" ] || { echo "Failed loading MAVEN_SNAPSHOT_VERSION" ; return 1 ; }

  # For later in this action
	export MAVEN_RELEASE_TAG
	export MAVEN_RELEASE_VERSION
	export MAVEN_SNAPSHOT_VERSION

  # For actions or steps that come after in this workflow
  echo "maven-release-tag=${MAVEN_RELEASE_TAG}" >> $GITHUB_OUTPUT
  echo "maven-release-version=${MAVEN_RELEASE_VERSION}" >> $GITHUB_OUTPUT
  echo "maven-snapshot-version=${MAVEN_SNAPSHOT_VERSION}" >> $GITHUB_OUTPUT
}

execMvn() {
	declare -a optsArr=( )
  loadArgData "optsArr"
  for val in "$@" ; do
    optsArr+=( "$( normalizeGoal "$val" )" )
  done
  printf "%s " " mvn" "${optsArr[@]}"
  mvn "${optsArr[@]}"
  return $?
}

invokePrepare() {
  execMvn "$@" release:prepare || failOnError
  loadVersionsInfo || failOnError
}

invokePerform() {
  execMvn "$@" release:perform || failOnError
  if [ "${MAVEN_RELEASE_PUSH_CHANGES}" = "false" ] ; then
 		git push --follow-tags --atomic || failOnError
  fi
}

invokeRelease() {
	invokePrepare "$@" || failOnError
	invokePerform "$@" || failOnError
}

case $1 in
	release)
		shift
		invokeRelease "$@"
		;;
	prepare)
		shift
		invokePrepare "$@"
		;;
	perform)
		shift
		invokePerform "$@"
		;;
	rollback)
		shift
		execMvn "$@" release:rollback || failOnError
		;;
	clean)
		shift
		execMvn "$@" release:clean || failOnError
		;;
	*)
		echo "Unknown command $1, quitting!"
		;;
esac
