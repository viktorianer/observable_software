class CreatePreviewFromPatternJob < ApplicationJob
  queue_as :default

  def perform(pattern_id)
    pattern = Pattern.find(pattern_id)
    pattern.start_generating_preview!
    pattern.create_preview
    pattern.add_border_to_preview(:small)
    pattern.add_border_to_preview(:small_wide)
    pattern.add_image_for(:in_hand)
    pattern.finish_generating_preview!
  end
end
