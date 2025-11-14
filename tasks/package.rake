# For Bundler.with_unbundled_env
require 'bundler/setup'

PACKAGE_NAME = "pact"
VERSION = File.read('VERSION').strip
TRAVELING_RUBY_VERSION = "20251107-3.4.7"
TRAVELING_RUBY_PKG_DATE = TRAVELING_RUBY_VERSION.split("-").first
TRAVELING_RB_VERSION = TRAVELING_RUBY_VERSION.split("-").last
RUBY_COMPAT_VERSION = TRAVELING_RB_VERSION.split(".").first(2).join(".") + ".0"
RUBY_MAJOR_VERSION = TRAVELING_RB_VERSION.split(".").first.to_i
RUBY_MINOR_VERSION = TRAVELING_RB_VERSION.split(".")[1].to_i
BIGDECIMAL_VERSION = '3.3.1'
DATE_VERSION = '3.5.0'
EVENTMACHINE_VERSION = '1.2.7'
JSON_VERSION = '2.16.0'
NIO4R_VERSION = '2.7.5'
NOKOGIRI_VERSION = '1.18.10'
PG_VERSION = '1.6.2'
PSYCH_VERSION = '5.2.6'
PUMA_VERSION = '7.1.0'
RACC_VERSION = '1.8.1'
REDCARPET_VERSION = '3.6.1'
STRINGIO_VERSION = '3.1.7'
SQLITE3_VERSION = '2.8.0'
THIN_VERSION = '2.0.1'

# Native extensions
NATIVE_GEMS = [
  "bigdecimal-#{BIGDECIMAL_VERSION}",
  "date-#{DATE_VERSION}",
  "eventmachine-#{EVENTMACHINE_VERSION}",
  "json-#{JSON_VERSION}",
  "nio4r-#{NIO4R_VERSION}",
  "nokogiri-#{NOKOGIRI_VERSION}",
  "pg-#{PG_VERSION}",
  "psych-#{PSYCH_VERSION}",
  "puma-#{PUMA_VERSION}",
  "racc-#{RACC_VERSION}",
  "redcarpet-#{REDCARPET_VERSION}",
  "stringio-#{STRINGIO_VERSION}",
  "sqlite3-#{SQLITE3_VERSION}",
  "thin-#{THIN_VERSION}",
]

desc "Package pact-standalone for Linux, MacOS, Windows (x86_64 and arm64)"
task :package => [
  'package:linux:x86_64',
  'package:linux:arm64',
  'package:linux:musl:x86_64',
  'package:linux:musl:arm64',
  'package:macos:x86_64',
  'package:macos:arm64',
  'package:windows:x86_64',
  'package:windows:arm64']

task "package:windows" => [
  'package:windows:x86_64',
  'package:windows:arm64']
task "package:linux" => [
  'package:linux:x86_64',
  'package:linux:arm64',
  'package:linux:musl:x86_64',
  'package:linux:musl:arm64']
task "package:linux:musl" => [
  'package:linux:musl:x86_64',
  'package:linux:musl:arm64']
task "package:linux:glibc" => [
  'package:linux:x86_64',
  'package:linux:arm64']
task "package:macos" => [
  'package:macos:x86_64',
  'package:macos:arm64']


namespace :package do
  namespace :linux do
    desc "Package pact-standalone for Linux x86_64"
    task :x86_64 => [:bundle_install, 
    "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz",
    ] do
      create_package(TRAVELING_RUBY_VERSION, "linux-x86_64", "linux-x86_64", :unix)
    end

    desc "Package pact-standalone for Linux arm64"
    task :arm64 => [:bundle_install, 
    "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-arm64.tar.gz",
    ] do
      create_package(TRAVELING_RUBY_VERSION, "linux-arm64", "linux-arm64", :unix)
    end

    namespace :musl do
      desc "Package pact-standalone for Linux musl x86_64"
      task :x86_64 => [:bundle_install, 
      "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-musl-x86_64.tar.gz",
      ] do
        create_package(TRAVELING_RUBY_VERSION, "linux-musl-x86_64", "linux-musl-x86_64", :unix)
      end

      desc "Package pact-standalone for Linux musl arm64"
      task :arm64 => [:bundle_install, 
      "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-musl-arm64.tar.gz",
      ] do
        create_package(TRAVELING_RUBY_VERSION, "linux-musl-arm64", "linux-musl-arm64", :unix)
      end
    end
  end

  namespace :macos do
  desc "Package pact-standalone for MacOS x86_64"
  task :x86_64 => [:bundle_install, 
  "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-macos-x86_64.tar.gz",
  ] do
    create_package(TRAVELING_RUBY_VERSION, "macos-x86_64", "macos-x86_64", :unix)
    end

  desc "Package pact-standalone for MacOS arm64"
  task :arm64 => [:bundle_install, 
  "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-macos-arm64.tar.gz", 
  ] do
    create_package(TRAVELING_RUBY_VERSION, "macos-arm64", "macos-arm64", :unix)
    end
  end
  namespace :windows do
    desc "Package pact-standalone for windows x86_64"
    task :x86_64 => [
      :bundle_install,
      "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-windows-x86_64.tar.gz",
    ] do
      create_package(TRAVELING_RUBY_VERSION, "windows-x86_64", "windows-x86_64", :windows)
    end
    desc "Package pact-standalone for windows arm64"
    task :arm64 => [
      :bundle_install,
      "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-windows-arm64.tar.gz",
      ] do
      create_package(TRAVELING_RUBY_VERSION, "windows-arm64", "windows-arm64", :windows)
    end
  end

  desc "Install gems to local directory. Usage: rake package:bundle_install[platform] (e.g. linux, windows, macos)"
  task :bundle_install do
    if RUBY_VERSION !~ /^#{RUBY_MAJOR_VERSION}\.#{RUBY_MINOR_VERSION}\./
      abort "You can only 'bundle install' using Ruby #{TRAVELING_RB_VERSION}, because that's what Traveling Ruby uses. \n You are using Ruby #{RUBY_VERSION}."
    end
    sh "rm -rf build/tmp"
    sh "mkdir -p build/tmp"
    sh "cp packaging/Gemfile packaging/Gemfile.lock build/tmp/"
    sh "mkdir -p build/tmp/lib/pact/mock_service"
    Bundler.with_unbundled_env do
      sh "cd build/tmp && env bundle config set --local path '../vendor' && env BUNDLE_DEPLOYMENT=true bundle install --verbose"
      generate_readme
    end
    sh "rm -rf build/tmp"
    sh "rm -rf build/vendor/*/*/cache/*"
    sh "rm -rf build/vendor/ruby/*/extensions" # remove host built extensions
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

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "linux-x86_64")
end

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-arm64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "linux-arm64")
end

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-musl-x86_64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "linux-musl-x86_64")
end

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-musl-arm64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "linux-musl-arm64")
end

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-macos-x86_64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "macos-x86_64")
end

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-macos-arm64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "macos-arm64")
end

file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-windows-x86_64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "windows-x86_64")
end
file "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-windows-arm64.tar.gz" do
  download_runtime(TRAVELING_RUBY_VERSION, "windows-arm64")
end

def create_package(version, source_target, package_target, os_type)
  package_dir = "#{PACKAGE_NAME}"
  package_name = "#{PACKAGE_NAME}-#{VERSION}-#{package_target}"
  sh "rm -rf #{package_dir}"
  sh "mkdir #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/app"
  sh "mkdir -p #{package_dir}/bin"
  sh "cp build/README.md #{package_dir}"
  sh "cp packaging/pact*.rb #{package_dir}/lib/app"

  # copy pact broker files
  sh "cp packaging/config.ru #{package_dir}/lib/app/"
  sh "cp packaging/GettingStartedOrderWeb-GettingStartedOrderApi.json #{package_dir}/lib/app/"

  sh "mkdir #{package_dir}/lib/ruby"
  sh "tar -xzf build/traveling-ruby-#{version}-#{source_target}.tar.gz -C #{package_dir}/lib/ruby"
  # From https://curl.se/docs/caextract.html
  sh "cp packaging/cacert.pem #{package_dir}/lib/ruby/lib/ca-bundle.crt"

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

  sh "cp -pR build/vendor #{package_dir}/lib/"
  sh "cp packaging/Gemfile packaging/Gemfile.lock #{package_dir}/lib/vendor/"

    # If packaging for Windows, patch Gemfile.lock for nokogiri platform as we are building platform specific gems with rake-compiler-dock
    if os_type == :windows
      lockfile = "#{package_dir}/lib/vendor/Gemfile.lock"
      if File.exist?(lockfile)
      content = File.read(lockfile)
      if content =~ /^    nokogiri \(#{NOKOGIRI_VERSION}\)/
        arch = package_target.include?("arm64") ? "-aarch64-mingw-ucrt" : "-x64-mingw-ucrt"
        patched = content.gsub(/^    nokogiri \(#{NOKOGIRI_VERSION}\)/, "    nokogiri (#{NOKOGIRI_VERSION}#{arch})")
        File.write(lockfile, patched)
      end
      end
    end
  
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"

  if package_target.include? 'windows'
    sh "sed -i.bak '41s/^/#/' #{package_dir}/lib/ruby/lib/ruby/#{RUBY_COMPAT_VERSION}/bundler/stub_specification.rb"
  else
    sh "sed -i.bak '41s/^/#/' #{package_dir}/lib/ruby/lib/ruby/site_ruby/#{RUBY_COMPAT_VERSION}/bundler/stub_specification.rb"
  end

  remove_unnecessary_files package_dir
  # ensure old native extensions are removed before adding the portable traveling-ruby ones
  download_and_unpack_ext(package_dir, source_target, NATIVE_GEMS) if ENV['WITH_NATIVE_EXT']

  if !ENV['DIR_ONLY']
    sh "mkdir -p pkg"

  # https://unix.stackexchange.com/questions/282055/a-lot-of-files-inside-a-tar
  sh "#{RUBY_PLATFORM =~ /darwin/ ? 'COPYFILE_DISABLE=1' : ''} tar -czf pkg/#{package_name}.tar.gz #{package_dir}"

  sh "rm -rf #{package_dir}"
  end
end

def remove_unnecessary_files package_dir
  ## Reduce distribution - https://github.com/phusion/traveling-ruby/blob/master/REDUCING_PACKAGE_SIZE.md
  # Remove tests
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/test"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/tests"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/spec"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/features"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/benchmark"

  # Remove documentation"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/README*"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/CHANGE*"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/Change*"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/COPYING*"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/LICENSE*"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/MIT-LICENSE*"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/TODO"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/*.txt"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/*.md"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/*.rdoc"
  
  # Issue 134 - Remove rdoc gemspec
  sh "find #{package_dir}/lib -name 'rdoc*gemspec' | xargs rm -f"

  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/doc"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/docs"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/example"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/examples"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/sample"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/doc-api"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.md' | xargs rm -f"

  # Remove misc unnecessary files"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/.gitignore"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/.travis.yml"

  # Remove leftover native extension sources and compilation objects"
  # make sure this in run before installing native extensions from traveling-ruby
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/ext/Makefile"
  sh "rm -f #{package_dir}/lib/vendor/ruby/*/gems/*/ext/*/Makefile"
  sh "rm -rf #{package_dir}/lib/vendor/ruby/*/gems/*/ext/*/tmp"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.c' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.cpp' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.h' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.rl' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby -name 'extconf.rb' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby/*/gems -name '*.o' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby/*/gems -name '*.so' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby/*/gems -name '*.bundle' | xargs rm -f"
  sh "find #{package_dir} -name '*.dSYM' | xargs rm -rf"
  sh "find #{package_dir}/lib/vendor/ruby/*/extensions -name '*.o' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby/*/extensions -name '*.so' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby/*/extensions -name '*.bundle' | xargs rm -f"

  # Remove .so and .bundle files for native gems in architecture-specific directories
  (NATIVE_GEMS - ["json-#{JSON_VERSION}"]).each do |native_gem|
    gem_name = native_gem.split('-').first
    sh "find #{package_dir}/lib/ruby/lib/ruby/*/*/#{gem_name}* -name '*.so' -delete || true"
    sh "find #{package_dir}/lib/ruby/lib/ruby/*/*/#{gem_name}* -name '*.bundle' -delete || true"
  end

  # Remove string_pattern Spanish data directory
  sh "rm -rf #{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems/string_pattern-*/data/spanish"

  # Remove sqlite3 ports/archives directory
  sh "rm -rf #{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems/sqlite3-#{SQLITE3_VERSION}/ports/archives"

  # Remove Java files. They're only used for JRuby support"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.java' | xargs rm -f"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.class' | xargs rm -f"

  # Ruby Docs
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/rdoc*"

  # Website files
  sh "find #{package_dir}/lib/vendor/ruby -name '*.html'"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.css'"
  sh "find #{package_dir}/lib/vendor/ruby -name '*.svg'"
  require 'pathname'

  # Exclude pact_broker gem directory from file removal
  # due to public folder containing required website assets
  pact_broker_gem_dir = Pathname.new("#{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems").children.find do |child|
    child.basename.to_s =~ /\Apact_broker-\d/ && !child.basename.to_s.start_with?("pact_broker-client")
  end

  exclude_path = pact_broker_gem_dir ? pact_broker_gem_dir.to_s : nil
  puts "Excluding pact_broker gem directory from HTML/CSS/SVG removal: #{exclude_path}"
  [
    '*.html',
    '*.css',
    '*.svg'
  ].each do |pattern|
    if exclude_path
      sh "find #{package_dir}/lib/vendor/ruby -name '#{pattern}' ! -path '#{exclude_path}/*' | xargs rm -f"
    else
      sh "find #{package_dir}/lib/vendor/ruby -name '#{pattern}' | xargs rm -f"
    end
  end

  # Remove unused Gemfile.lock files
  sh "find #{package_dir}/lib/vendor/ruby -name 'Gemfile.lock' | xargs rm -f"

  # Uncommonly used encodings
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/cp949*"
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/euc_*"
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/shift_jis*"
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/koi8_*"
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/emacs*"
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/gb*"
  sh "rm -rf #{package_dir}/lib/ruby/lib/ruby/*/*/enc/big5*"
  # sh "rm -f #{package_dir}/lib/ruby/lib/ruby/*/*/enc/windows*"
  # sh "rm -f #{package_dir}/lib/ruby/lib/ruby/*/*/enc/utf_16*"
  # sh "rm -f #{package_dir}/lib/ruby/lib/ruby/*/*/enc/utf_32*"
end

def generate_readme
  template = File.absolute_path('packaging/README.md.template')
  script = File.absolute_path('packaging/generate_readme_contents.rb')
  Bundler.with_unbundled_env do
    sh "cd build/tmp && env VERSION=#{VERSION} bundle exec ruby #{script} #{template} > ../README.md"
  end
end

def download_runtime(version, target)
  sh "cd build && curl -L -O --fail " +
     "https://github.com/YOU54F/traveling-ruby/releases/download/rel-#{TRAVELING_RUBY_PKG_DATE}/traveling-ruby-#{version}-#{target}.tar.gz"
end

def download_and_unpack_ext(package_dir, package_target, native_gems)
  native_gems.each do |native_gem|
    is_windows = package_target.include?("windows")
    is_nokogiri = native_gem.start_with?("nokogiri-")
    tarball = "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{package_target}-#{native_gem}.tar.gz"
    url = "https://github.com/YOU54F/traveling-ruby/releases/download/rel-#{TRAVELING_RUBY_PKG_DATE}/traveling-ruby-gems-#{TRAVELING_RUBY_VERSION}-#{package_target}-#{native_gem}.tar.gz"

    sh "curl -L --fail #{url} -o #{tarball}"

    if is_windows && is_nokogiri
      gem_dir = "#{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems"
      spec_dir = "#{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/specifications"
      sh "mkdir -p #{gem_dir} #{spec_dir}"
      # Unpack gem contents
      sh "rm -rf #{gem_dir}/#{native_gem}"
      sh "mkdir -p #{gem_dir}/#{native_gem}"
      sh "tar -xzf #{tarball} --strip-components=1 -C #{gem_dir}/#{native_gem} 'nokogiri-*'"
      # Unpack gemspec
      sh "tar -xzf #{tarball} --strip-components=0 -C #{spec_dir} 'nokogiri-*.gemspec'"
    else
      sh "tar -xzf #{tarball} -C #{package_dir}/lib/vendor/ruby"
    end

    sh "rm #{tarball}"
  end
end