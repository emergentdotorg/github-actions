#!/usr/bin/env bash

echo MAVEN_NEXT_RELEASE_VER="${MAVEN_NEXT_RELEASE_VER}"
echo MAVEN_NEXT_SNAPSHOT_VER="${MAVEN_NEXT_SNAPSHOT_VER}"
echo MAVEN_RELEASE_PLUGIN_VER="${MAVEN_RELEASE_PLUGIN_VER}"
#MAVEN_USER_SETTINGS_PATH="$GITHUB_WORKSPACE/settings.xml"
echo MAVEN_USER_SETTINGS_PATH="${MAVEN_USER_SETTINGS_PATH}"
echo MAVEN_OPTS="${MAVEN_OPTS}"
echo MAVEN_ARGS="${MAVEN_ARGS}"

MAVEN_ORIG_OPTS="${MAVEN_OPTS}"
MAVEN_ORIG_ARGS="${MAVEN_ARGS}"



#mvnDargumentsArr=( )
#mvnDargumentsArr+=( "-Dmaven.javadoc.skip=true" )
#
#mvnOptsArr=( )
#if [ ${#mvnDargumentsArr[@]} -gt 0 ] ; then mvnOptsArr+=( "-Darguments=${mvnDargumentsArr[*]}" ) ; fi
#if [ -n "${MAVEN_NEXT_RELEASE_VER}" ] ; then mvnOptsArr+=( "-DreleaseVersion=${MAVEN_NEXT_RELEASE_VER}" ) ; fi
#if [ -n "${MAVEN_NEXT_SNAPSHOT_VER}" ] ; then mvnOptsArr+=( "-DdevelopmentVersion=${MAVEN_NEXT_SNAPSHOT_VER}" ) ; fi
#
#mvnArgsArr=( )
#mvnArgsArr+=( "-B" )
#if [ -n "${MAVEN_USER_SETTINGS_PATH}" ] ; then mvnArgsArr+=( "-s" "${MAVEN_USER_SETTINGS_PATH}" ) ; fi

checkReturnCode() {
  local rc=$?
  if [ ${rc} -ne 0 ] ; then
    echo "Error, found result code $rc, exiting!"
    exit $rc
  fi
  return $rc
}

normalizeGoal() {
  val="$1"
  if [ -n "${MAVEN_RELEASE_PLUGIN_VER}" ] ; then
    val="${val/^release:/org.apache.maven.plugins:maven-release-plugin:${MAVEN_RELEASE_PLUGIN_VER}:}"
  fi
  echo "$val"
}

extractValue() {
  val="$1"
  val="${1##[^=]*}"
  val="${val#=}"
  echo "$val"
}

getRelProp() {
  grep "^${1}=" release.properties|cut -d'=' -f2
}

execMvn() {
  # resolved maven goals
  local mvnGoalsArr=( )
  for var in "$@"
  do
    if [ -n "${MAVEN_RELEASE_PLUGIN_VER}" ] ; then
      var="${var/^release:/org.apache.maven.plugins:maven-release-plugin:${MAVEN_RELEASE_PLUGIN_VER}:}"
    fi
    mvnGoalsArr+=( "$var" )
  done

  local mvnOptsArr=( )
  mvnOptsArr+=( "-Dresume=false" )
  mvnOptsArr+=( "-DpushChanges=true" )
  mvnOptsArr+=( "-DlocalCheckout=true" )
  mvnOptsArr+=( "-DtagNameFormat=@{project.version}" )
  mvnOptsArr+=( "-DscmCommentPrefix=[GitHub] " )

  local mvnDargumentsArr=( )
  mvnDargumentsArr+=( "-Dmaven.javadoc.skip=true" )
  if [ ${#mvnDargumentsArr[@]} -gt 0 ] ; then mvnOptsArr+=( "-Darguments=${mvnDargumentsArr[*]}" ) ; fi

  if [ -n "${MAVEN_NEXT_RELEASE_VER}" ] ; then mvnOptsArr+=( "-DreleaseVersion=${MAVEN_NEXT_RELEASE_VER}" ) ; fi
  if [ -n "${MAVEN_NEXT_SNAPSHOT_VER}" ] ; then mvnOptsArr+=( "-DdevelopmentVersion=${MAVEN_NEXT_SNAPSHOT_VER}" ) ; fi

  # maven arguments that come after the goals
  local mvnArgsArr=( )
  mvnArgsArr+=( "-B" )
  if [ -n "${MAVEN_USER_SETTINGS_PATH}" ] ; then mvnArgsArr+=( "-s" "${MAVEN_USER_SETTINGS_PATH}" ) ; fi

  mvnArgsArr+=( "-B" )
  MAVEN_OPTS="$MAVEN_OPTS ${mvnOptsArr[*]}"
  MAVEN_ARGS="$MAVEN_ARGS ${mvnArgsArr[*]}"


#  mvn "${mainArgs[@]}" "${goalArgs[@]}" "${mvnArgsArr[@]}"
  mvn "${mainArgs[@]}" $MAVEN_ARGS "${goalArgs[@]}"
  return $?
}

performRelease() {
  local rc=0

  execMvn release:prepare
  rc=$? ; if [ ${rc} -ne 0 ] ; then echo "Error preparing, result code was $rc, exiting!" ; exit $rc ; fi

  if [ -n "${GITHUB_OUTPUT}" ] ; then
    MAVEN_RELEASE_VERSION="$( getRelProp "release.version" )"
    MAVEN_SNAPSHOT_VERSION="$( getRelProp "snapshot.version" )"
    echo "maven-release-version=${MAVEN_RELEASE_VERSION}" >> "${GITHUB_OUTPUT}"
    echo "maven-snapshot-version=${MAVEN_SNAPSHOT_VERSION}" >> "${GITHUB_OUTPUT}"
  fi

  execMvn release:perform
  rc=$? ; if [ ${rc} -ne 0 ] ; then echo "Error performing, result code was $rc, exiting!" ; exit $rc ; fi

  git push --follow-tags --atomic
  rc=$? ; if [ ${rc} -ne 0 ] ; then echo "Error performing, result code was $rc, exiting!" ; exit $rc ; fi
}

performGoals() {
  execMvn "$@"
  local rc=$? ; if [ ${rc} -ne 0 ] ; then echo "Error, result code was $rc, exiting!" ; exit $rc ; fi
}

showArgs() {
  for arg in "$@"
  do
    echo "${arg}"
  done | awk 'BEGIN { RS = "" ; FS = "\n" } { printf "\"%s\"", $1 ; for (x=2; x<=NF; x++) { printf " \"%s\"", $x } printf "\n" }'
}

execMvn() {
  if [ "$DRYRUN" = "true" ] ; then
    showArgs mvn "$@"
    return 0
  fi
  mvn "$@"
  local rc=$? ; if [ ${rc} -ne 0 ] ; then echo "Error, result code was $rc, exiting!" ; exit $rc ; fi
}

parseArguments() {
  local -n outArgsArr="$1"
  shift
  local key val
  declare -a argsArr
  declare -A optsMap

  local concatValueOptKeys=( "Darguments" )
  local skipIfEmptyOptKeys=( "Darguments" "DreleaseVersion" "DdevelopmentVersion" )

  while [[ $# -gt 0 ]]; do
    case $1 in
      -b|--builder) ;&
      -f|--file) ;&
      -l|--log-file) ;&
      -s|--settings|-gs|--global-settings) ;&
      -t|--toolchains|-gt|--global-toolchains) ;&
      -P|--activate-profiles) ;&
      -pl|--projects) ;&
      -rf|--resume-from)
        argsArr+=( "$1" "$2" ) ; shift ; shift
        ;;
      -X|--debug)
        # these are maven args without values
        argsArr+=( "$1" ) ; shift
        ;;
      --argument) ;&
      --next-release-version) ;&
      --next-snapshot-version) ;&
      -D*|-X*)
        # these are java args without (separate) values
        if [ "$1" = "--argument" ] ; then
          key="Darguments"
          val="$2"
          shift ; shift
        elif [ "$1" = "--next-release-version" ] ; then
          key="DreleaseVersion"
          val="$2"
          shift ; shift
        elif [ "$1" = "--next-snapshot-version" ] ; then
          key="DdevelopmentVersion"
          val="$2"
          shift ; shift
        else
          # must be a "-D*" or "-X*"
          key="${1%%=*}"
          key="${key#-}"
          val="${1#*=}"
          if [ "$val" = "$1" ] ; then
            # Couldn't find an '=' so the value is empty
            val=""
          fi
          shift
        fi
#        echo "Passed -$key=$val"
        if [ -n "${optsMap[$key]}" ] && [[ " ${concatValueOptKeys[*]} " =~ [[:space:]]${key}[[:space:]] ]] ; then
          if [ -n "$val" ] ; then
            optsMap[$key]="${optsMap[$key]} $val"
          fi
        else
          optsMap[$key]="$val"
        fi
        shift
#        echo "Found "'"'"-$key=${optsMap[$key]}"'"'
        ;;
      --*|-*)
        # these are maven args without values
        argsArr+=( "$1" ) ; shift
        ;;
      *)
        argsArr+=( "$( normalizeGoal $1 )" )
        shift # past argument
        ;;
    esac
  done

  argsArr+=( "-B" )
  for key in "${!optsMap[@]}"
  do
    val="${optsMap[${key}]}"
    if [ -n "${val}" ] ; then
      outArgsArr+=( "-${key}=${val}" )
    elif [[ ! " ${skipIfEmptyOptKeys[*]} " =~ [[:space:]]${key}[[:space:]] ]] ; then
      # unless explicitly restricted, add opt key with no value
      outArgsArr+=( "-${key}" )
    fi
  done

  outArgsArr+=( "${argsArr[@]}" )

  #  mvnDargumentsArr+=( "-Dmaven.javadoc.skip=true" )
  #  if [ ${#mvnDargumentsArr[@]} -gt 0 ] ; then mvnOptsArr+=( "-Darguments=${mvnDargumentsArr[*]}" ) ; fi

  #  cmdArgsArr+=( "${mvnOptsArr[@]}" )
  #  cmdArgsArr+=( "${mvnGoalsArr[@]}" )

  #  MAVEN_OPTS="$MAVEN_OPTS ${mvnOptsArr[*]}"
  #  MAVEN_ARGS="$MAVEN_ARGS ${mvnArgsArr[*]}"
}

declare -a cmdArgsArr
parseArguments "cmdArgsArr" "-Darguments=-Dmaven.javadoc.skip=true" "-Darguments=-DfailOnError=false" "$@"
execMvn "${cmdArgsArr[@]}"

cmdArgsArr=()
parseArguments "cmdArgsArr" --argument "-Dmaven.javadoc.skip=true" --argument "-Darguments=-DfailOnError=false" "$@"
execMvn "${cmdArgsArr[@]}"

#rc=$? ; if [ ${rc} -ne 0 ] ; then echo "Error, result code was $rc, exiting!" ; exit $rc ; fi

#mvnDargumentsArr+=( "-Dmaven.javadoc.skip=true" )
#if [ ${#mvnDargumentsArr[@]} -gt 0 ] ; then mvnOptsArr+=( "-Darguments=${mvnDargumentsArr[*]}" ) ; fi

#mvnArgsArr+=( "-B" )
#MAVEN_OPTS="$MAVEN_OPTS ${mvnOptsArr[*]}"
#MAVEN_ARGS="$MAVEN_ARGS ${mvnArgsArr[*]}"
#
#mvn "${mvnOptsArr[@]}" "${mvnArgsArr[@]}" "${mvnGoalsArr[@]}" "${mvnArgsArr[@]}"
#mvn "${mainArgs[@]}" $MAVEN_ARGS "${goalArgs[@]}"
#

#
#function foo {
#    # declare a local **reference variable** (hence `-n`) named `data_ref`
#    # which is a reference to the value stored in the first parameter
#    # passed in
#    local -n data_ref="$1"
#    echo "${data_ref[0]}"
#    echo "${data_ref[1]}"
#}
#
## declare a regular bash "indexed" array
#declare -a data
#data+=("Fred Flintstone")
#data+=("Barney Rubble")
#foo "data"
#
##if [ $# -eq 0 ] ; then
##  performRelease
##else
##  performGoals "$@"
##fi
