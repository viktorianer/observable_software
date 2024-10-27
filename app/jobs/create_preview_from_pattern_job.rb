class CreatePreviewFromPatternJob < ApplicationJob
  queue_as :default

  def perform(pattern_id)
    pattern = Pattern.find(pattern_id)
    pattern.start_generating_preview!
    pattern.create_preview
    pattern.add_border_to_preview(:small)
    pattern.add_border_to_preview(:small_wide)
    pattern.add_border_to_preview(:medium)
    pattern.add_border_to_preview(:large)
    pattern.add_image_for(:nightstand)
    pattern.add_image_for(:chest_of_drawers)
    pattern.finish_generating_preview!
  end
end
