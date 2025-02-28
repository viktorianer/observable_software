require "semantic_logger"
require_relative "../../lib/flat_json_formatter"

SemanticLogger.add_appender(
  appender: :http,
  url: "https://api.honeycomb.io/1/events/minicrossstitching",
  formatter: FlatJsonFormatter.new,
  header: {
    "Content-Type" => "application/json",
    "X-Honeycomb-Team" => ENV.fetch("OTEL_EXPORTER_OTLP_HEADERS").split("=").last
  }
)
