class Pattern < ApplicationRecord
  has_one_attached :preview

  def self.from_fcjson(fcjson_data)
    parsed_data = JSON.parse(fcjson_data, symbolize_names: true)
    width = parsed_data.dig(:model, :images, 0, :width)
    height = parsed_data.dig(:model, :images, 0, :height)
    pattern = new(name: parsed_data.dig(:info, :title))
    threads = from_fcjson_to_threads(fcjson_data)
    combined_image = MiniMagick::Image.open(Rails.root.join("data", "blank.png"))
    combined_image.resize("#{width * 32}x#{height * 32}")

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

  def self.from_fcjson_to_threads(fcjson_data)
    parsed_data = JSON.parse(fcjson_data, symbolize_names: true)
    crosses = parsed_data.dig(:model, :images, 0, :layers, 0, :cross)
    width = parsed_data.dig(:model, :images, 0, :width)

    crosses.map do |cross|
      if cross == -1
        "aida"
      else
        floss_index = parsed_data.dig(:model, :images, 0, :crossIndexes, cross, :fi)
        floss_indices = parsed_data.dig(:model, :images, 0, :flossIndexes)
        floss = floss_indices.fetch(floss_index)
        floss.fetch(:id)
      end
    end.each_slice(width).to_a
  end
end
