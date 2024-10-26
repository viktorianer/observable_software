class CreatePreviewFromPatternJob < ApplicationJob
  queue_as :default

  def perform(pattern_id)
    pattern = Pattern.find(pattern_id)
    pattern.start_generating_preview!
    pattern.create_preview
    pattern.add_border_to_preview
    pattern.compose_on_background
    pattern.finish_generating_preview!
  end
end
