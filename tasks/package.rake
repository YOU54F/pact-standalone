
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

# Native gem versions
NATIVE_GEM_VERSIONS = {
  bigdecimal: '3.3.1',
  date: '3.5.0',
  eventmachine: '1.2.7',
  json: '2.16.0',
  mysql2: '0.5.7',
  nio4r: '2.7.5',
  nokogiri: '1.18.10',
  pg: '1.6.2',
  psych: '5.2.6',
  puma: '7.1.0',
  racc: '1.8.1',
  redcarpet: '3.6.1',
  stringio: '3.1.7',
  sqlite3: '2.8.0',
  thin: '2.0.1',
}
NATIVE_GEMS = NATIVE_GEM_VERSIONS.map { |k, v| "#{k}-#{v}" }

# Platform/target definitions
PLATFORMS = [
  { os: :linux,   arch: :x86_64, musl: false },
  { os: :linux,   arch: :arm64,  musl: false },
  { os: :linux,   arch: :x86_64, musl: true  },
  { os: :linux,   arch: :arm64,  musl: true  },
  { os: :macos,   arch: :x86_64, musl: false },
  { os: :macos,   arch: :arm64,  musl: false },
  { os: :windows, arch: :x86_64, musl: false },
  { os: :windows, arch: :arm64,  musl: false },
]

def platform_name(p)
  if p[:os] == :linux && p[:musl]
    "linux-musl-#{p[:arch]}"
  else
    "#{p[:os]}-#{p[:arch]}"
  end
end

def package_task_name(p)
  "package:#{platform_name(p)}"
end

def tarball_name(p)
  "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform_name(p)}.tar.gz"
end

# Generate all package tasks and file rules
PLATFORMS.each do |plat|
  desc "Package pact-standalone for #{platform_name(plat)}"
  task package_task_name(plat) => [ :bundle_install, tarball_name(plat) ] do
    create_package(TRAVELING_RUBY_VERSION, platform_name(plat), plat[:os] == :windows ? :windows : :unix)
  end

  file tarball_name(plat) do
    download_runtime(TRAVELING_RUBY_VERSION, platform_name(plat))
  end
end

# Meta tasks for groups
task "package:windows" => PLATFORMS.select { |p| p[:os] == :windows }.map { |p| package_task_name(p) }
task "package:linux"   => PLATFORMS.select { |p| p[:os] == :linux && !p[:musl] }.map { |p| package_task_name(p) }
task "package:linux:musl" => PLATFORMS.select { |p| p[:os] == :linux && p[:musl] }.map { |p| package_task_name(p) }
task "package:linux:glibc" => PLATFORMS.select { |p| p[:os] == :linux && !p[:musl] }.map { |p| package_task_name(p) }
task "package:macos"   => PLATFORMS.select { |p| p[:os] == :macos }.map { |p| package_task_name(p) }

desc "Package pact-standalone for all platforms"
task :package => PLATFORMS.map { |p| package_task_name(p) }

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

def create_package(version, target, os_type)
  package_dir = "#{PACKAGE_NAME}"
  package_name = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
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
  sh "tar -xzf build/traveling-ruby-#{version}-#{target}.tar.gz -C #{package_dir}/lib/ruby"
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
      if content =~ /^    nokogiri \(#{NATIVE_GEM_VERSIONS[ :nokogiri ]}\)/
        arch = target.include?("arm64") ? "-aarch64-mingw-ucrt" : "-x64-mingw-ucrt"
        patched = content.gsub(/^    nokogiri \(#{NATIVE_GEM_VERSIONS[ :nokogiri ]}\)/, "    nokogiri (#{NATIVE_GEM_VERSIONS[ :nokogiri ]}#{arch})")
        File.write(lockfile, patched)
      end
      end
    end
  
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"

  if target.include? 'windows'
    sh "sed -i.bak '41s/^/#/' #{package_dir}/lib/ruby/lib/ruby/#{RUBY_COMPAT_VERSION}/bundler/stub_specification.rb"
  else
    sh "sed -i.bak '41s/^/#/' #{package_dir}/lib/ruby/lib/ruby/site_ruby/#{RUBY_COMPAT_VERSION}/bundler/stub_specification.rb"
  end

  remove_unnecessary_files package_dir
  # ensure old native extensions are removed before adding the portable traveling-ruby ones
  download_and_unpack_ext(package_dir, target, NATIVE_GEMS) if ENV['WITH_NATIVE_EXT']

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
  NATIVE_GEMS.reject { |g| g.start_with?("json-") }.each do |native_gem| gem_name = native_gem.split('-').first
    sh "find #{package_dir}/lib/ruby/lib/ruby/*/*/#{gem_name}* -name '*.so' -delete || true"
    sh "find #{package_dir}/lib/ruby/lib/ruby/*/*/#{gem_name}* -name '*.bundle' -delete || true"
  end

  # Remove string_pattern Spanish data directory
  sh "rm -rf #{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems/string_pattern-*/data/spanish"

  # Remove sqlite3 ports/archives directory
  sqlite3_gem = NATIVE_GEMS.find { |g| g.start_with?("sqlite3-") }
  if sqlite3_gem
    sh "rm -rf #{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems/#{sqlite3_gem}/ports/archives"
  end

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

def download_and_unpack_ext(package_dir, target, native_gems)
  native_gems.each do |native_gem|
    is_windows = target.include?("windows")
    is_nokogiri = native_gem.start_with?("nokogiri-")
    tarball = "build/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-#{native_gem}.tar.gz"
    url = "https://github.com/YOU54F/traveling-ruby/releases/download/rel-#{TRAVELING_RUBY_PKG_DATE}/traveling-ruby-gems-#{TRAVELING_RUBY_VERSION}-#{target}-#{native_gem}.tar.gz"

    sh "curl -L --fail #{url} -o #{tarball}"

    if is_windows && is_nokogiri
      gem_dir = "#{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/gems"
      spec_dir = "#{package_dir}/lib/vendor/ruby/#{RUBY_COMPAT_VERSION}/specifications"
      sh "mkdir -p #{gem_dir} #{spec_dir}"
      # Unpack gem contents
      sh "rm -rf #{gem_dir}/#{native_gem}"
      sh "mkdir -p #{gem_dir}/#{native_gem}"
      wildcards_flag = RUBY_PLATFORM =~ /linux/ ? "--wildcards" : ""
      sh "tar -xzf #{tarball} #{wildcards_flag} --strip-components=1 -C #{gem_dir}/#{native_gem} 'nokogiri-*'"
      # Unpack gemspec
      sh "tar -xzf #{tarball} #{wildcards_flag} --strip-components=0 -C #{spec_dir} 'nokogiri-*.gemspec'"
    else
      sh "tar -xzf #{tarball} -C #{package_dir}/lib/vendor/ruby"
    end

    sh "rm #{tarball}"
  end
end