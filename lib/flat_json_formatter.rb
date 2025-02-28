class FlatJsonFormatter < SemanticLogger::Formatters::Raw
  def initialize(time_format: :iso_8601, time_key: :timestamp, **args)
    super(time_format: time_format, time_key: time_key, **args)
  end

  def call(log, logger)
    log = super(log, logger)
    log.deep_merge!(log.delete(:payload) || {})
    log.deep_merge!(log.delete(:named_tags) || {})
    log.merge!(
      "service.name" => "minicrossstitching",
      "http.host" => log.delete(:host),
      "http.route" => log.delete(:path),
      "http.method" => log.delete(:method),
      "http.status_code" => log.delete(:status),
      "code.namespace" => log.delete(:controller),
      "code.action" => log.delete(:action),
      "error" => (log[:level].to_s == "error")
    )
    log.to_json
  end
end
