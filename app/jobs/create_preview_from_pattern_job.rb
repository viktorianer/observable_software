class CreatePreviewFromPatternJob < ApplicationJob
  queue_as :default

  def perform(pattern_id)
    pattern = Pattern.find(pattern_id)
    pattern.create_preview
    pattern.add_border_to_preview
  end
end
