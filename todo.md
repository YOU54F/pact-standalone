1. bigdecimal native extension removed in 3.4.x
2. match extension version with traveling ruby
3. download traveling ruby extension
4. move extension specifications from to pkg/pact/lib/ruby/lib/ruby/gems/3.4.0/specifications to pkg/pact/lib/ruby/lib/ruby/gems/3.4.0/specifications/default
5. comment out pkg/pact/lib/ruby/lib/ruby/site_ruby/3.4.0/bundler/stub_specification.rb line 41
   1. ` warn "Source #{source} is ignoring`