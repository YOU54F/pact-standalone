require 'erb'

puts ERB.new(ARGF.read).result(binding)
