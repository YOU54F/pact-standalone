# frozen_string_literal: true

require "net/http"
require "uri"
require "webrick"
require "pact/ffi/verifier"
require "pact/ffi/logger"
PactFfi::Logger.log_to_buffer(PactFfi::Logger::LogLevel["INFO"])
RSpec.describe "pactffi verifier spec" do
  # before(:all) do
  #   @server_thread = Thread.new do
  #     server = WEBrick::HTTPServer.new(Port: 8000, BindAddress: "localhost")
  #     trap "INT" do server.shutdown end
  #     server.mount_proc("/api/books") do |req, res|
  #       res.body = if req.request_method == "POST"
  #                    "Received POST request with body: This is the request body."
  #                  else
  #                    "This is the foo page."
  #                  end
  #     end
  #     server.start
  #   end
  # end
  after(:all) do
    @server_thread.kill
  end
  let(:verifier) { PactFfi::Verifier.new_for_application("pact-ruby", "1.0.0") }
  after do
    PactFfi::Verifier.shutdown(verifier)
  end
  it "should respond verify with pact" do
    uri = URI("http://127.0.0.1:8000/api/books")
    req = Net::HTTP::Post.new(uri)
    req.body = "This is the request body."
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    expect(response.code).to eq("200")
    expect(response.body).to eq("Received POST request with body: This is the request body.")
    PactFfi::Verifier.set_provider_info(verifier, "http-provider", "http", "localhost", 8000, "")
    PactFfi::Verifier.set_verification_options(verifier, 0, 1000)
    PactFfi::Verifier.add_file_source(verifier,
                                      "pacts/http-consumer-1-http-provider.json")
    result = PactFfi::Verifier.execute(verifier)
    puts PactFfi::Verifier.logs(verifier)
    puts result
    # expect(result).to be PactFfi::Verifier::Response["VERIFICATION_SUCCESSFUL"]
  end
end

# # frozen_string_literal: true

# require "httparty"
# require "pact/ffi/verifier"
# require "pact/ffi/logger"
# require "fileutils"
# require "webrick"

# PactFfi::Logger.log_to_buffer(PactFfi::Logger::LogLevel["INFO"])
# RSpec.describe "pactffi verifier spec" do
#   describe "with mismatching requests" do
#     # after do
#     #   PactFfi::Verifier.shutdown(verifier)
#     # end
#     before do
#       @server_thread = Thread.new do
#         server = WEBrick::HTTPServer.new(Port: 8000)
#         puts "starting server"
#         trap 'INT' do server.shutdown end
#         server.mount_proc("/api/books") do |req, res|
#           puts "got request" + req.inspect
#           res.body = "This is the foo page."
#         end
#         server.start
#       end
#     end
#     after do
#       PactFfi::Verifier.shutdown(verifier)
#       @server_thread.kill
#     end
#     # it "fails when no file source is found" do
#     #   PactFfi::Verifier.set_provider_info(verifier, "http-provider", "http", "127.0.0.1", 8000, "/")
#     #   PactFfi::Verifier.add_file_source(verifier, "foo") # doesnt fail if no file sources.
#     #   result = PactFfi::Verifier.execute(verifier)
#     #   expect(result).to be PactFfi::Verifier::Response["VERIFICATION_FAILED"]
#     # end
#     it "executes the pact verifier with no information and fails 2" do
#       # PactFfi::Verifier.set_filter_info(verifier, "", "book", 0)
#       # PactFfi::Verifier.set_provider_state(verifier, "http://127.0.0.1:8000/change-state", 1, 1)
#       # PactFfi::Verifier.set_verification_options(verifier, 0, 5000)
#       # PactFfi::Verifier.set_publish_options(verifier, "1.0.0", nil, nil, 0, "some-branch")
#       # ffi.pactffi_verifier_set_publish_options(handle, '1.0.0', nil,tags, tags.length, 'some-branch');
#       # PactFfi::Verifier.set_consumer_filters(verifier, nil, 0)
#       # ffi.pactffi_verifier_set_consumer_filters(handle, getCData(consumers), count(consumers));
#       # app = proc do
#       #   ['200', {'Content-Type' => 'text/html'}, ["Hello world! The time is #{Time.now}"]]
#       # end
#       # app.run

#       # server = WEBrick::HTTPServer.new(Port: 8000)
#       # trap 'INT' do server.shutdown end
#       # server.mount_proc("/api/books") do |req, res|
#       #   res.body = "This is the foo page."
#       # end
#       # server.start

#       # server.listen

#       # app.listen(8000)
#       PactFfi::Verifier.set_provider_info(verifier, "http-provider", "http", "127.0.0.1", 8000, "/")
#       PactFfi::Verifier.add_file_source(verifier,
#                                         "pacts/http-consumer-1-http-provider.json")
#       result = PactFfi::Verifier.execute(verifier)
#       puts PactFfi::Verifier.logs(verifier)
#       expect(result).to be PactFfi::Verifier::Response["VERIFICATION_FAILED"]
#     end
#   end
# end

# # /*
# #  * | Error | Description |
# #  * |-------|-------------|
# #  * | 1 | The verification process failed, see output for errors |
# #  * | 2 | A null pointer was received |
# #  * | 3 | The method panicked |
# #  * | 4 | Invalid arguments were provided to the verification process |
# #  */
# # FfiVerifyProviderResponse = Hash[
# #   "VERIFICATION_SUCCESSFUL" => 0,
# #   "VERIFICATION_FAILED" => 1,
# #   "NULL_POINTER_RECEIVED" => 2,
# #   "METHOD_PANICKED" => 3,
# #   "INVALID_ARGUMENTS" => 4,
# # ]
