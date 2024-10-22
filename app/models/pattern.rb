class Pattern < ApplicationRecord
  has_one_attached :preview

  def self.from_fcjson(fcjson_data)
    parsed_data = JSON.parse(fcjson_data)
    pattern = new(name: parsed_data.dig("info", "title"))
    threads = [
      [ "01", "307" ],
      [ "820", "aida" ]
    ]
    combined_image = MiniMagick::Image.open(Rails.root.join("data", "blank.png"))
    combined_image.resize("64x64")

    threads.each_with_index do |row, y|
      row.each_with_index do |thread_id, x|
        thread_image_path = Rails.root.join("data", "threads", "#{thread_id}.png")

        if File.exist?(thread_image_path)
          thread_image = MiniMagick::Image.open(thread_image_path)
          combined_image = combined_image.composite(thread_image) do |c|
            c.compose "Over"
            c.geometry "+#{x*32}+#{y*32}"
          end
        else
          Rails.logger.warn "Thread image not found: #{thread_id}.png"
        end
      end
    end

    temp_file = Tempfile.new([ "preview", ".png" ], "tmp")
    combined_image.write(temp_file.path)
    temp_file.rewind

    pattern.preview.attach(io: temp_file, filename: "preview.png", content_type: "image/png")
    pattern.save!

    temp_file.close
    temp_file.unlink

    pattern
  end
end
