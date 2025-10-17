# For Bundler.with_unbundled_env
require 'bundler/setup'

PACKAGE_NAME = "pact"
VERSION = File.read('VERSION').strip
TRAVELING_RUBY_VERSION = "20250625-3.3.9"
TRAVELING_RUBY_PKG_DATE = TRAVELING_RUBY_VERSION.split("-").first
TRAVELING_RB_VERSION = TRAVELING_RUBY_VERSION.split("-").last
RUBY_COMPAT_VERSION = TRAVELING_RB_VERSION.split(".").first(2).join(".") + ".0"
RUBY_MAJOR_VERSION = TRAVELING_RB_VERSION.split(".").first.to_i
RUBY_MINOR_VERSION = TRAVELING_RB_VERSION.split(".")[1].to_i
PLUGIN_CLI_VERSION = "0.1.3" # https://github.com/pact-foundation/pact-plugins/releases
MOCK_SERVER_CLI_VERSION = "1.0.6" # https://github.com/pact-foundation/pact-core-mock-server/releases
VERIFIER_CLI_VERSION = "1.2.0" # https://github.com/pact-foundation/pact-reference/releases
STUB_SERVER_CLI_VERSION = "0.6.2" # https://github.com/pact-foundation/pact-stub-server/releases
PACT_BROKER_CLI_VERSION = "0.2.0" # https://github.com/pact-foundation/pact-broker-cli/releases
PACT_CLI_VERSION = "0.6.0" # https://github.com/you54f/pact-cli/releases

desc "Package pact-standalone for OSX, Linux x86_64 and windows x86_64"
task :package => ['package:linux:x86_64','package:linux:arm64', 'package:osx:x86_64', 'package:osx:arm64','package:windows:x86_64', 'package:windows:arm64']

namespace :package do
  namespace :linux do
    desc "Package pact-standalone for Linux x86_64"
    task :x86_64 do
      create_package(TRAVELING_RUBY_VERSION, "linux-x86_64", "linux-x86_64", :unix)
    end

    desc "Package pact-standalone for Linux arm64"
    task :arm64 do
      create_package(TRAVELING_RUBY_VERSION, "linux-arm64", "linux-arm64", :unix)
    end
  end

  namespace :osx do
  desc "Package pact-standalone for OS X x86_64"
  task :x86_64 do
    create_package(TRAVELING_RUBY_VERSION, "osx-x86_64", "osx-x86_64", :unix)
    end

  desc "Package pact-standalone for OS X arm64"
  task :arm64 do
    create_package(TRAVELING_RUBY_VERSION, "osx-arm64", "osx-arm64", :unix)
    end
  end
  namespace :windows do
    desc "Package pact-standalone for windows x86_64"
    task :x86_64 do
      create_package(TRAVELING_RUBY_VERSION, "windows-x86_64", "windows-x86_64", :windows)
    end
  end
  namespace :windows do
    desc "Package pact-standalone for windows arm64"
    task :arm64 do
      create_package(TRAVELING_RUBY_VERSION, "windows-arm64", "windows-arm64", :windows)
    end
  end
  desc "Install gems to local directory"
  task :bundle_install do
    if RUBY_VERSION !~ /^#{RUBY_MAJOR_VERSION}\.#{RUBY_MINOR_VERSION}\./
      abort "You can only 'bundle install' using Ruby #{TRAVELING_RB_VERSION}, because that's what Traveling Ruby uses. \n You are using Ruby #{RUBY_VERSION}."
    end
    sh "rm -rf build/tmp"
    sh "mkdir -p build/tmp"
    sh "cp packaging/Gemfile packaging/Gemfile.lock build/tmp/"
    sh "mkdir -p build/tmp/lib/pact/mock_service"
    # sh "cp lib/pact/mock_service/version.rb build/tmp/lib/pact/mock_service/version.rb"
    Bundler.with_unbundled_env do
      sh "cd build/tmp && env bundle lock --add-platform x64-mingw32 && bundle config set --local path '../vendor' && env BUNDLE_DEPLOYMENT=true bundle install"
      generate_readme
    end
    sh "rm -rf build/tmp"
    sh "rm -rf build/vendor/*/*/cache/*"
  end

  task :generate_readme do
    Bundler.with_unbundled_env do
      sh "mkdir -p build/tmp"
      sh "cp packaging/Gemfile packaging/Gemfile.lock build/tmp/"
      sh "cd build/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development"
      generate_readme
    end
  end
end


def create_package(version, source_target, package_target, os_type)
  package_dir = "#{PACKAGE_NAME}"
  package_name = "#{PACKAGE_NAME}-#{VERSION}-#{package_target}"
  sh "rm -rf #{package_dir}"
  sh "mkdir -p build"
  sh "mkdir -p build/tmp"
  sh "mkdir #{package_dir}"
  sh "mkdir -p #{package_dir}/bin"
  generate_readme
  sh "cp build/README.md #{package_dir}"

  case os_type
  when :unix
    Dir.chdir('packaging'){ Dir['pact*.sh'] }.each do | name |
      sh "cp packaging/#{name} #{package_dir}/bin/#{name.chomp('.sh')}"
    end
  when :windows
    sh "cp packaging/pact*.bat #{package_dir}/bin"
  else
    raise "We don't serve their kind (#{os_type}) here!"
  end
  install_pact_cli package_dir, package_target
  # install_plugin_cli package_dir, package_target
  # install_mock_server_cli package_dir, package_target
  # install_verifier_cli package_dir, package_target
  # install_stub_server_cli package_dir, package_target
  # install_broker_cli package_dir, package_target

  if !ENV['DIR_ONLY']
    sh "mkdir -p pkg"

  if os_type == :unix
    sh "tar -czf pkg/#{package_name}.tar.gz #{package_dir}"
  else
    sh "zip -9rq pkg/#{package_name}.zip #{package_dir}"
  end

  sh "rm -rf #{package_dir}"
  end
end


def generate_readme
  template = File.absolute_path('packaging/README.md.template')
  script = File.absolute_path('packaging/generate_readme_contents.rb')
  Bundler.with_unbundled_env do
    sh "cd build/tmp && env VERSION=#{VERSION} bundle exec ruby #{script} #{template} > ../README.md"
  end
end


def install_pact_cli(package_dir, package_target)
  case package_target
  when "linux-x86_64"
    sh "curl --fail -L -o #{package_dir}/bin/pact https://github.com/you54f/pact-cli/releases/download/v#{PACT_CLI_VERSION}/pact-x86_64-linux-musl"
    sh "chmod +x #{package_dir}/bin/pact"
  when "linux-arm64"
    sh "curl --fail -L -o #{package_dir}/bin/pact https://github.com/you54f/pact-cli/releases/download/v#{PACT_CLI_VERSION}/pact-aarch64-linux-musl"
    sh "chmod +x #{package_dir}/bin/pact"
  when "osx-x86_64"
    sh "curl --fail -L -o #{package_dir}/bin/pact https://github.com/you54f/pact-cli/releases/download/v#{PACT_CLI_VERSION}/pact-x86_64-macos"
    sh "chmod +x #{package_dir}/bin/pact"
  when "osx-arm64"
    sh "curl --fail -L -o #{package_dir}/bin/pact https://github.com/you54f/pact-cli/releases/download/v#{PACT_CLI_VERSION}/pact-aarch64-macos"
    sh "chmod +x #{package_dir}/bin/pact"
  when "windows-x86_64"
    sh "curl --fail -L -o #{package_dir}/bin/pact.exe https://github.com/you54f/pact-cli/releases/download/v#{PACT_CLI_VERSION}/pact-x86_64-windows-gnu.exe"
    sh "chmod +x #{package_dir}/bin/pact.exe"
  when "windows-arm64"
    sh "curl --fail -L -o #{package_dir}/bin/pact.exe https://github.com/you54f/pact-cli/releases/download/v#{PACT_CLI_VERSION}/pact-aarch64-windows-msvc.exe"
    sh "chmod +x #{package_dir}/bin/pact.exe"
  end
end
