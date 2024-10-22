class CreatePatternFromFcjsonJob < ApplicationJob
  queue_as :default

  def perform(pattern_id)
    pattern = Pattern.find(pattern_id)
    pattern.create_preview
  end
end
