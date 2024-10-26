require 'rails_helper'

RSpec.describe Pattern, type: :model do
  describe "#create_preview" do
    it "creates a pattern with a preview image from FCJSON" do
      fcjson_data = File.read(Rails.root.join("spec/support/example.fcjson"))

      pattern = Pattern.create(definition: fcjson_data)
      pattern.create_preview

      expect(pattern.preview).to be_attached
      expect(pattern.preview.content_type).to start_with("image/")
      preview_image = MiniMagick::Image.read(pattern.preview.download)
      expect(preview_image.width).to eq(2 * 32)
      expect(preview_image.height).to eq(2 * 32)
      expect(pattern.name).to eq("Testing")
    end
  end

  describe "#add_border_to_preview" do
    it "adds a border to make the pattern 55x40" do
      fcjson_data = File.read(Rails.root.join("spec/support/example.fcjson"))
      pattern = Pattern.create(name: "Testing", definition: fcjson_data)
      pattern.create_preview

      pattern.add_border_to_preview

      expect(pattern.preview).to be_attached
      expect(pattern.preview.content_type).to start_with("image/")
      preview_image = MiniMagick::Image.read(pattern.preview.download)
      expect(preview_image.height).to eq(55 * 32)
      expect(preview_image.width).to eq(40 * 32)
    end
  end

  describe ".from_fcjson_to_threads" do
    it "returns an array of arrays of thread ids" do
      fcjson_data = File.read(Rails.root.join("spec/support/example.fcjson"))
      threads = Pattern.from_fcjson_to_threads(fcjson_data)
      expect(threads).to eq([
        [ "01", "307" ],
        [ "820", "blank" ]
      ])
    end
  end

  describe "#compose_on_background" do
    it "creates a distorted preview image" do
      pattern = create_the_bends_pattern

      pattern.compose_on_background

      pattern.reload
      expect(pattern.distorted_preview).to be_attached
      expect(pattern.distorted_preview.content_type).to start_with("image/")
      distorted_preview_image = MiniMagick::Image.read(pattern.distorted_preview.download)
      expect(distorted_preview_image.width).to eq(2000)
      expect(distorted_preview_image.height).to eq(2667)
    end
  end

  private

  def create_the_bends_pattern
    fcjson_data = File.read(Rails.root.join("spec/support/the_bends.fcjson"))
    pattern = Pattern.create!(name: "The Bends", definition: fcjson_data)
    pattern.preview.attach(io: File.open(Rails.root.join("spec/support/the_bends.png")), filename: "the_bends.png", content_type: "image/png")
    pattern.save!
    pattern
  end
end
