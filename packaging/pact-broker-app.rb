unless ARGV.any? { |arg| arg =~ /\.ru$/ }
  ARGV.push("#{File.dirname(__FILE__)}/config.ru")
end
load Gem.bin_path("rackup", "rackup")
