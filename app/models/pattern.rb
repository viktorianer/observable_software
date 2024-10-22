class Pattern < ApplicationRecord
  has_one_attached :preview

  def self.from_fcjson(fcjson_data)
    parsed_data = JSON.parse(fcjson_data)
    pattern = new(name: parsed_data["name"])

    pixels = [
      255, 0, 0,   # Red
      0, 255, 0,   # Green
      0, 0, 255,   # Blue
      255, 255, 0, # Yellow
      255, 0, 255, # Magenta
      0, 255, 255, # Cyan
      128, 128, 128, # Gray
      0, 0, 0,     # Black
      255, 255, 255 # White
    ]

    # Create the image using `import_pixels`
    image = MiniMagick::Image.import_pixels(pixels.pack("C*"), 3, 3, 8, "rgb", "png")
    temp_file = Tempfile.new([ "preview", ".png" ], "tmp")
    image.write(temp_file.path)
    temp_file.rewind

    pattern.preview.attach(io: temp_file, filename: "preview.png", content_type: "image/png")
    pattern.save!

    # Close and unlink the temporary file
    temp_file.close
    temp_file.unlink

    pattern
  end
end
