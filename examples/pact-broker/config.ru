# frozen_string_literal: true

require "sequel"
require "fileutils"
require "logger"
require "pact_broker"
# Create a real database, and set the credentials for it here
# It is highly recommended to set the encoding to utf8 (varchar foreign keys may blow up otherwise)

# Check if PACT_BROKER_DB_PROVIDER == postgres or sqlite and set up the credentials accordingly
DATABASE_CREDENTIALS = if ENV.fetch("PACT_BROKER_DB_PROVIDER", "none") == "postgres"
                         require "pg" # for postgres

                         { adapter: "postgres",
                           database: ENV.fetch("PACT_BROKER_DATABASE_NAME", "pact_broker"),
                           username: ENV.fetch("PACT_BROKER_DATABASE_USERNAME", "pact_broker"),
                           password: ENV.fetch("PACT_BROKER_DATABASE_PASSWORD", "pact_broker"),
                           encoding: "utf8" }

                       elsif ENV.fetch("PACT_BROKER_DB_PROVIDER", "none") == "mysql"
                         # For mysql:
                         DATABASE_CREDENTIALS = { adapter: "mysql2",
                                                  database: ENV.fetch("PACT_BROKER_DATABASE_NAME", "pact_broker"),
                                                  username: ENV.fetch("PACT_BROKER_DATABASE_USERNAME", "pact_broker"),
                                                  password: ENV.fetch("PACT_BROKER_DATABASE_PASSWORD", "pact_broker"),
                                                  encoding: "utf8" }.freeze
                       else
                         { adapter: "sqlite", database: "pact_broker_database.sqlite3", encoding: "utf8" }
                       end

# For postgres:
# $ psql postgres
# > create database pact_broker;
# > CREATE USER pact_broker WITH PASSWORD 'pact_broker';
# > GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker;

# Have a look at the Sequel documentation to make decisions about things like connection pooling
# and connection validation.
# run PactBroker::App.new
app = PactBroker::App.new do |config|
  config.base_urls = "http://localhost:9292 http://127.0.0.1:9292 http://0.0.0.0:9292 https://localhost:9292 https://127.0.0.1:9292 https://0.0.0.0:9292"
  # config.base_url = 'http://0.0.0.0:9292'
  # change these from their default values if desired
  # config.log_dir = "./log"
  # config.log_level = "debug"
  # config.allow_public_read = true
  config.log_stream = "stdout"
  config.auto_migrate_db = true
  config.auto_migrate_db_data = true
  config.use_hal_browser = true
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(logger: config.logger))
  # config.database_connection = "postgres://pact_broker:pact_broker@localhost:5432/pact_broker"
  # config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(logger: config.logger))
end
run app
