require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/all"

OpenTelemetry::SDK.configure do |c|
  c.use_all(
    "OpenTelemetry::Instrumentation::ActiveJob" => {
      propagation_style: :child,
      span_naming: :job_class
    }
  )
  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    "service.commit_sha" => `git rev-parse HEAD`.strip
  )
end
