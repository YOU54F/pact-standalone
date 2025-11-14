#!/bin/bash -eu
set -eu # This needs to be here for windows bash, which doesn't read the #! line above

detected_os=$(uname -sm)
echo detected_os = $detected_os
BINARY_OS=${BINARY_OS:-}
BINARY_ARCH=${BINARY_ARCH:-}
FILE_EXT=${FILE_EXT:-}

if [ "$BINARY_OS" == "" ] || [ "$BINARY_ARCH" == "" ] ; then 
    case ${detected_os} in
    'Darwin arm64')
        BINARY_OS=macos
        BINARY_ARCH=arm64
        ;;
    'Darwin x86' | 'Darwin x86_64' | "Darwin"*)
        BINARY_OS=macos
        BINARY_ARCH=x86_64
        ;;
    "Linux aarch64"* | "Linux arm64"*)
        BINARY_OS=linux
        BINARY_ARCH=arm64
        if ldd /bin/ls >/dev/null 2>&1; then
            ldd_output=$(ldd /bin/ls)
            case "$ldd_output" in
                *musl*) 
                    BINARY_OS='linux-musl'
                    ;;
            esac
        fi
        ;;
    'Linux x86_64' | "Linux"*)
        BINARY_OS=linux
        BINARY_ARCH=x86_64
        if ldd /bin/ls >/dev/null 2>&1; then
            ldd_output=$(ldd /bin/ls)
            case "$ldd_output" in
                *musl*) 
                    BINARY_OS='linux-musl'
                    ;;
            esac
        fi
        ;;
    "MINGW64*ARM64"*)
        BINARY_OS=windows
        BINARY_ARCH=arm64
        ;;
    "Windows"* | "MINGW64"*)
        BINARY_OS=windows
        BINARY_ARCH=x86_64
        ;;
      *)
      echo "Sorry, os not determined"
      exit 1
        ;;
    esac;
fi
echo BINARY_OS = $BINARY_OS
echo BINARY_ARCH = $BINARY_ARCH
if [ "$BINARY_OS" != "windows" ] ; then PATH_SEPERATOR=/ ; else PATH_SEPERATOR=\\; fi
PATH_TO_BIN=.${PATH_SEPERATOR}pkg${PATH_SEPERATOR}pact${PATH_SEPERATOR}bin${PATH_SEPERATOR}

tools=(
  pact-broker
  pact-message
  pact-mock-service
  pact-provider-verifier
  pact-stub-service
  pactflow
  pact-broker-app
)

test_cmd=""
for tool in ${tools[@]}; do
  echo testing $tool
  if [ "$BINARY_OS" = "windows" ] ; then FILE_EXT=.bat; fi
  if [ "$tool" = "pact-mock-service" ]; then  test_cmd="--help" ; fi
    if [ "$tool" = "pact-broker-app" ]; then  test_cmd="--version" ; fi
  echo executing ${tool}${FILE_EXT} 
  ${PATH_TO_BIN}${tool}${FILE_EXT} ${test_cmd};
done