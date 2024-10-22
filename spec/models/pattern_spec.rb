require 'rails_helper'

RSpec.describe Pattern, type: :model do
  describe ".from_fcjson" do
    it "creates a pattern with a preview image from FCJSON" do
      fcjson_data = {
        "type": "pattern",
        "version": "1.0",
        "name": "Test Pattern",
        "rows": [
          [ 1, 0, 1 ],
          [ 0, 1, 0 ],
          [ 1, 0, 1 ]
        ]
      }.to_json

      pattern = Pattern.from_fcjson(fcjson_data)
      expect(pattern).to be_a(Pattern)
      expect(pattern.preview).to be_attached
      expect(pattern.preview.content_type).to start_with("image/")
      expect(pattern.name).to eq("Test Pattern")
      expect(pattern.preview).to be_attached
      preview_image = MiniMagick::Image.read(pattern.preview.download)
      expect(preview_image.width).to eq(3)
      expect(preview_image.height).to eq(3)
      # Check pixel RGB values
      expected_colors = [
        [ 255, 0, 0 ],    # Red
        [ 0, 255, 0 ],    # Green
        [ 0, 0, 255 ],    # Blue
        [ 255, 255, 0 ], # Yellow
        [ 255, 0, 255 ], # Magenta
        [ 0, 255, 255 ], # Cyan
        [ 128, 128, 128 ], # Gray
        [ 0, 0, 0 ],     # Black
        [ 255, 255, 255 ] # White
      ]

      pixels = preview_image.get_pixels
      pixels.flatten.each_slice(3).with_index do |pixel, index|
        expect(pixel).to eq(expected_colors[index])
      end
    end
  end
end
