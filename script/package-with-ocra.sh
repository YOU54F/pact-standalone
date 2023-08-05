#!/bin/bash -e
set -e

gem install ocran
mkdir -p pkg
cd packaging
bundle install
ocran pact-broker.rb ca-bundle.crt --verbose --output pact-broker-cli.exe --gem-all --add-all-core --gem-full=openssl --dll ruby_builtin_dlls/zlib1.dll --dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/libyaml-0-2.dll --dll ruby_builtin_dlls/libssl-3-x64.dll --dll ruby_builtin_dlls/libcrypto-3-x64.dll
ocran pact.rb ca-bundle.crt --verbose --output pact-cli.exe --gem-all --add-all-core --gem-full=openssl --dll ruby_builtin_dlls/zlib1.dll --dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/libyaml-0-2.dll --dll ruby_builtin_dlls/libssl-3-x64.dll --dll ruby_builtin_dlls/libcrypto-3-x64.dll
ocran pact-message.rb ca-bundle.crt --verbose --output pact-message.exe --gem-all --add-all-core --gem-full=openssl --dll ruby_builtin_dlls/zlib1.dll --dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/libyaml-0-2.dll --dll ruby_builtin_dlls/libssl-3-x64.dll --dll ruby_builtin_dlls/libcrypto-3-x64.dll
ocran pact-mock-service.rb ca-bundle.crt --verbose --output pact-mock-service.exe --gem-all --add-all-core --gem-full=openssl --dll ruby_builtin_dlls/zlib1.dll --dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/libyaml-0-2.dll --dll ruby_builtin_dlls/libssl-3-x64.dll --dll ruby_builtin_dlls/libcrypto-3-x64.dll
ocran pact-provider-verifier.rb ca-bundle.crt --verbose --output pact-provider-verifier.exe --gem-all --add-all-core --gem-full=openssl --dll ruby_builtin_dlls/zlib1.dll --dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/libyaml-0-2.dll --dll ruby_builtin_dlls/libssl-3-x64.dll --dll ruby_builtin_dlls/libcrypto-3-x64.dll
ocran pact-stub-service.rb ca-bundle.crt --verbose --output pact-stub-service.exe --gem-all --add-all-core --gem-full=openssl --dll ruby_builtin_dlls/zlib1.dll --dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/libyaml-0-2.dll --dll ruby_builtin_dlls/libssl-3-x64.dll --dll ruby_builtin_dlls/libcrypto-3-x64.dll
gzip -c pact-broker-cli.exe > ../pkg/pact-broker-cli.exe.gz
gzip -c pact-cli.exe > ../pkg/pact-cli.exe.gz
gzip -c pact-message.exe > ../pkg/pact-message.exe.gz
gzip -c pact-mock-service.exe > ../pkg/pact-mock-service.exe.gz
gzip -c pact-provider-verifier.exe > ../pkg/pact-provider-verifier.exe.gz
gzip -c pact-stub-service.exe > ../pkg/pact-stub-service.exe.gz
cd ..
pushd pkg; for file in *.gz; do openssl dgst -sha256 -r "$file" > "${file}.sha256"; done; popd;
cat pkg/*.sha256 > pkg/pact-`cat VERSION`.sha256
