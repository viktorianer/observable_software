class Pattern < ApplicationRecord
  has_one_attached :preview
  has_one_attached :distorted_preview

  enum :preview_status, { not_generating_preview: "not_generating_preview", generating_preview: "generating_preview", finished_generating_preview: "finished_generating_preview" }

  def distort(offset, top_left, transformed_top_left, top_right, transformed_top_right, bottom_left, transformed_bottom_left, bottom_right, transformed_bottom_right)
    distorted_preview_image = MiniMagick::Image.read(preview.download)
    distorted_preview_image.write(Rails.root.join("tmp", "preview.png"))

    preview_image = MiniMagick::Image.read(preview.download)
    distorted_preview_image = MiniMagick::Image.create
    MiniMagick.convert do |c|
      c << preview_image.path
      c.virtual_pixel "transparent"
      c.distort("Perspective", "#{top_left.map(&:to_s).join(',')},#{transformed_top_left.join(',')} #{top_right.join(',')},#{transformed_top_right.join(',')} #{bottom_left.join(',')},#{transformed_bottom_left.join(',')} #{bottom_right.join(',')},#{transformed_bottom_right.join(',')}")
      c << distorted_preview_image.path
    end

    background_image = MiniMagick::Image.open(Rails.root.join("data", "backgrounds", "#{BACKGROUND}.png"))
    background_image.composite(distorted_preview_image) do |c|
      c.geometry "+#{offset[0]}+#{offset[1]}"
      c.matte
      c.virtual_pixel "transparent"
      c.compose "DstOver"
    end
  end

  BACKGROUND_CUTOUT_DIMENSIONS = {
    nightstand: [
      [ 1140, 1870 ],
      [ 1465, 1880 ],
      [ 1115, 2321 ],
      [ 1445, 2338 ]
    ],
    chest_of_drawers: [
      [ 216, 658 ],
      [ 616, 671 ],
      [ 207, 1180 ],
      [ 600, 1216 ]
    ]
  }

  BACKGROUND = :nightstand

  def compose_on_background
    four_corners = BACKGROUND_CUTOUT_DIMENSIONS.fetch(BACKGROUND)
    preview_image = MiniMagick::Image.read(preview.download)
    preview_image_width = preview_image.width
    preview_image_height = preview_image.height
    top_left = [ 0, 0 ]
    top_right = [ preview_image_width, 0 ]
    bottom_left = [ 0, preview_image_height ]
    bottom_right = [ preview_image_width, preview_image_height ]

    x_offset = four_corners.map { |x, y| x }.min
    y_offset = four_corners.map { |x, y| y }.min
    offset = [ x_offset, y_offset ]
    margin = 5
    transformed_top_left = [ four_corners[0][0], four_corners[0][1] ].then { |x, y| [ x - offset[0] - margin, y - offset[1] - margin ] }
    transformed_top_right = [ four_corners[1][0], four_corners[1][1] ].then { |x, y| [ x - offset[0] + margin, y - offset[1] - margin ] }
    transformed_bottom_left = [ four_corners[2][0], four_corners[2][1] ].then { |x, y| [ x - offset[0] - margin, y - offset[1] + margin ] }
    transformed_bottom_right = [ four_corners[3][0], four_corners[3][1] ].then { |x, y| [ x - offset[0] + margin, y - offset[1] + margin ] }
    composite_image = distort(offset, top_left, transformed_top_left, top_right, transformed_top_right, bottom_left, transformed_bottom_left, bottom_right, transformed_bottom_right)
    temp_file = Tempfile.new([ "distorted_preview", ".png" ], "tmp")
    composite_image.write(temp_file.path)
    temp_file.rewind
    distorted_preview.attach(io: temp_file, filename: "distorted_preview.png", content_type: "image/png")
    save!
    temp_file.close
    temp_file.unlink
  end

  def start_generating_preview!
    generating_preview!
    update!(percentage_converted: 0)
  end

  def finish_generating_preview!
    finished_generating_preview!
    update!(percentage_converted: 100)
  end

  def height
    parsed_data.dig(:model, :images, 0, :height)
  end

  def width
    parsed_data.dig(:model, :images, 0, :width)
  end

  def parsed_data
    JSON.parse(definition, symbolize_names: true)
  end

  def create_preview
    start_generating_preview!
    update!(name: parsed_data.dig(:info, :title))
    threads = Pattern.from_fcjson_to_threads(definition)
    combined_image = MiniMagick::Image.open(Rails.root.join("data", "blank.png"))
    combined_image.resize("#{width * 32}x#{height * 32}!")

    pixel_percentage_progress_fraction = 100.0 / (width * height)
    current_pixel_index = 0

    thread_images = {}
    threads.each_with_index do |row, y|
      row.each_with_index do |thread_id, x|
        next if thread_id == "blank"
        thread_image_path = Rails.root.join("data", "threads", "#{thread_id}.png")

        unless File.exist?(thread_image_path)
          raise "Thread image not found: #{thread_id}.png"
        end

        thread_images[thread_id] ||= MiniMagick::Image.open(thread_image_path)

        combined_image = combined_image.composite(thread_images[thread_id]) do |c|
          c.compose "Over"
          c.geometry "+#{x*32}+#{y*32}"
        end

        current_pixel_index += 1
      end

      update!(percentage_converted: current_pixel_index * pixel_percentage_progress_fraction)
    end

    # Final update to ensure 100%
    update!(percentage_converted: 100)

    temp_file = Tempfile.new([ "preview", ".png" ], "tmp")
    combined_image.write(temp_file.path)
    temp_file.rewind

    preview.attach(io: temp_file, filename: "preview.png", content_type: "image/png")
    save!

    temp_file.close
    temp_file.unlink

    self
  end

  def add_border_to_preview
    preview_image = MiniMagick::Image.read(preview.download)
    preview_image_width = preview_image.data.dig("geometry", "width")
    preview_image_height = preview_image.data.dig("geometry", "height")
    aida_background = MiniMagick::Image.create(".png")

    aida_image = MiniMagick::Image.open(Rails.root.join("data", "threads", "aida_grey.png"))

    MiniMagick.convert do |c|
      c.size "#{40 * 32}x#{55 * 32}"
      c << "tile:#{aida_image.path}"
      c.colorspace "sRGB"
      c.type "TrueColor"
      c << "PNG24:#{aida_background.path}"
    end

    aida_background.write(Rails.root.join("tmp", "aida_background.png"))

    preview_image_on_aida = aida_background.composite(preview_image) do |c|
      c.compose "Over"
      x_offset = ((40 * 32 - preview_image_width) / 64).floor * 32
      y_offset = ((55 * 32 - preview_image_height) / 64).floor * 32
      c.geometry "+#{x_offset}+#{y_offset}"
    end

    preview_image_on_aida.write(Rails.root.join("tmp", "preview_image_on_aida.png"))

    # Save the new image
    temp_file = Tempfile.new([ "preview_image_on_aida", ".png" ], "tmp")
    preview_image_on_aida.write(temp_file.path)
    temp_file.rewind

    preview.attach(io: temp_file, filename: "preview_with_border.png", content_type: "image/png")
    finish_generating_preview!
    save!

    # temp_file.close
    # temp_file.unlink
    # preview_image.resize("55x40")
  end

  def self.from_fcjson_to_threads(fcjson_data)
    parsed_data = JSON.parse(fcjson_data, symbolize_names: true)
    crosses = parsed_data.dig(:model, :images, 0, :layers, 0, :cross)
    width = parsed_data.dig(:model, :images, 0, :width)

    crosses.map do |cross|
      if cross == -1
        "blank"
      else
        floss_index = parsed_data.dig(:model, :images, 0, :crossIndexes, cross, :fi)
        floss_indices = parsed_data.dig(:model, :images, 0, :flossIndexes)
        floss = floss_indices.fetch(floss_index)
        floss.fetch(:id)
      end
    end.each_slice(width).to_a
  end

  def generate_preview
    CreatePreviewFromPatternJob.perform_later(id)
  end
end
