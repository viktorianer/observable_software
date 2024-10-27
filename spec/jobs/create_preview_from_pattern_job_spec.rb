require 'rails_helper'

RSpec.describe CreatePreviewFromPatternJob, type: :job do
  it "creates preview and distorted preview images" do
    pattern = create_the_bends_pattern

    CreatePreviewFromPatternJob.perform_now(pattern.id)

    expect(pattern.preview).to be_attached
    expect(pattern.images.count).to eq(5)
  end

  private

  def create_the_bends_pattern
    fcjson_data = File.read(Rails.root.join("spec/support/the_bends.fcjson"))
    Pattern.create!(name: "The Bends", definition: fcjson_data)
  end
end
