require 'pact/mock_service/cli'

class Thor
  module Base
    module ClassMethods

      def basename
        # chomps the trailing .rb so it doesn't show in the help text
        File.basename($PROGRAM_NAME).split(" ").first.chomp(".rb")
      end
    end
  end
end

# Ocran will allow use to include our own cert file at packaging time
# this points to the CA cert bundle take from traveling-ruby
if (ENV['AIBIKA_EXECUTABLE'] || ENV['AIBIKA_EXECUTABLE'] != '') && ENV['SSL_CERT_FILE'].nil?
  ENV['SSL_CERT_FILE'] = File.join(File.dirname($0), 'ca-bundle.crt')
end

Pact::MockService::CLI.start unless defined?(Aibika)
