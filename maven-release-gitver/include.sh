#!/usr/bin/env bash

catIfExists() {
  if [ -f "$1" ]; then
    cat "$1"
  else
    echo "WARNING: File $1 does not exist"
  fi
}
