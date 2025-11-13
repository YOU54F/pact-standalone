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
        ;;
    'Linux x86_64' | "Linux"*)
        BINARY_OS=linux
        BINARY_ARCH=x86_64
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
cd pkg
rm -rf pact
ls

tar xvf *$BINARY_OS-$BINARY_ARCH.tar.gz
if [ "$BINARY_OS" != "windows" ] ; then PATH_SEPERATOR=/ ; else PATH_SEPERATOR=\\; fi
PATH_TO_BIN=.${PATH_SEPERATOR}pact${PATH_SEPERATOR}bin${PATH_SEPERATOR}
PACT_TO_RUBY_BINS=.${PATH_SEPERATOR}pact${PATH_SEPERATOR}lib${PATH_SEPERATOR}ruby${PATH_SEPERATOR}bin${PATH_SEPERATOR}

tools=(
#   pact-broker
  pact-message
  pact-mock-service
  pact-provider-verifier
  pact-stub-service
#   pactflow
)
# ruby version check
ruby_version=$(${PACT_TO_RUBY_BINS}ruby.bat -e 'print RUBY_VERSION')
echo "Ruby version: $ruby_version"
${PACT_TO_RUBY_BINS}gem.bat list

test_cmd=""
for tool in ${tools[@]}; do
  echo testing $tool
  if [ "$BINARY_OS" = "windows" ] ; then FILE_EXT=.bat; fi
  if [ "$tool" = "pact-mock-service" ]; then  test_cmd="--help" ; fi
  echo executing ${tool}${FILE_EXT} 
  ${PATH_TO_BIN}${tool}${FILE_EXT} ${test_cmd};
done