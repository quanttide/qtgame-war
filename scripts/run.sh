#!/usr/bin/env bash
cd "$(dirname "$0")/../src/studio"

case "$1" in
  linux|lin)
    exec flutter run -d linux
    ;;
  web)
    exec flutter run -d web "$@"
    ;;
  "")
    exec flutter run
    ;;
  *)
    exec flutter run "$@"
    ;;
esac
