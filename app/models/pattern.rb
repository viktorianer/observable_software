class Pattern < ApplicationRecord
  has_one_attached :preview

  enum :preview_status, { not_generating_preview: "not_generating_preview", generating_preview: "generating_preview", finished_generating_preview: "finished_generating_preview" }

  def start_generating_preview!
    generating_preview!
    update!(percentage_converted: 0)
  end

  def finish_generating_preview!
    finished_generating_preview!
    update!(percentage_converted: 100)
  end

  def create_preview
    start_generating_preview!
    parsed_data = JSON.parse(definition, symbolize_names: true)
    width = parsed_data.dig(:model, :images, 0, :width)
    height = parsed_data.dig(:model, :images, 0, :height)
    update!(name: parsed_data.dig(:info, :title))
    threads = Pattern.from_fcjson_to_threads(definition)
    combined_image = MiniMagick::Image.open(Rails.root.join("data", "blank.png"))
    combined_image.resize("#{width * 32}x#{height * 32}")

    pixel_percentage_progress_fraction = 100.0 / (width * height)
    current_pixel_index = 0

    threads.each_with_index do |row, y|
      row.each_with_index do |thread_id, x|
        thread_image_path = Rails.root.join("data", "threads", "#{thread_id}.png")

        if File.exist?(thread_image_path)
          thread_image = MiniMagick::Image.open(thread_image_path)
          combined_image = combined_image.composite(thread_image) do |c|
            c.compose "Over"
            c.geometry "+#{x*32}+#{y*32}"
          end
          current_pixel_index += 1
          update!(percentage_converted: current_pixel_index * pixel_percentage_progress_fraction)
        else
          Rails.logger.warn "Thread image not found: #{thread_id}.png"
        end
      end
    end

    temp_file = Tempfile.new([ "preview", ".png" ], "tmp")
    combined_image.write(temp_file.path)
    temp_file.rewind

    preview.attach(io: temp_file, filename: "preview.png", content_type: "image/png")
    finish_generating_preview!
    save!

    temp_file.close
    temp_file.unlink

    self
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
