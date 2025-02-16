class Pattern < ApplicationRecord
  has_one_attached :preview
  has_one_attached :preview_with_border_small
  has_one_attached :preview_with_border_small_wide
  has_one_attached :preview_with_border_medium
  has_one_attached :preview_with_border_medium_tall
  has_one_attached :preview_with_border_medium_large
  has_one_attached :preview_with_border_large
  has_one_attached :preview_with_border_large_tall
  has_one_attached :distorted_preview
  has_many_attached :images

  enum :orientation, { portrait: "portrait", landscape: "landscape", square: "square" }

  STITCH_WIDTH = 32

  BORDER_SIZE_FOR_BACKGROUND = {
    portrait: {
      in_hand: :small_wide,
      nightstand: :small,
      chest_of_drawers: :medium,
      close_up: :medium_large,
      green_wall_with_stool: :small
    },
    square: {
      in_hand: :small,
      nightstand: :small,
      chest_of_drawers: :medium_tall,
      close_up: :large_tall,
      green_wall_with_stool: :medium
    },
    landscape: {
      in_hand: :small,
      nightstand: :small,
      chest_of_drawers: :medium_tall,
      close_up: :large_tall,
      green_wall_with_stool: :medium
    }
  }

  COMPOSE = {
    in_hand: "Over",
    nightstand: "DstOver",
    chest_of_drawers: "DstOver",
    close_up: "Over",
    green_wall_with_stool: "DstOver"
  }

  MARGIN = {
    in_hand: 0,
    nightstand: 5,
    chest_of_drawers: 5,
    close_up: 0,
    green_wall_with_stool: 5
  }

  BACKGROUND_CUTOUT_DIMENSIONS = {
    portrait: {
      in_hand: [
        [ 546, 710 ],
        [ 1476, 862 ],
        [ 355, 1878 ],
        [ 1290, 2030 ]
      ],
      green_wall_with_stool: [
        [ 870, 1157 ],
        [ 1132, 1157 ],
        [ 870, 1518 ],
        [ 1132, 1518 ]
      ],
      nightstand: [
        [ 1140, 1870 ],
        [ 1465, 1880 ],
        [ 1115, 2321 ],
        [ 1445, 2338 ]
      ],
      chest_of_drawers: [
        [ 315, 464 ],
        [ 653, 466 ],
        [ 310, 955 ],
        [ 651, 957 ]
      ],
      close_up: [
        [ 0, 0 ],
        [ 2000, 0 ],
        [ 0, 2666 ],
        [ 2000, 2666 ]
      ]
    },
    landscape: {
      in_hand: [
        [ 521, 835 ],
        [ 1505, 995 ],
        [ 366, 1800 ],
        [ 1351, 1958 ]
      ],
      green_wall_with_stool: [
        [ 920, 1157 ],
        [ 1280, 1157 ],
        [ 920, 1518 ],
        [ 1280, 1518 ]
      ],
      nightstand: [
        [ 1140, 1870 ],
        [ 1465, 1880 ],
        [ 1115, 2321 ],
        [ 1445, 2338 ]
      ],
      chest_of_drawers: [
        [ 315, 464 ],
        [ 653, 466 ],
        [ 310, 955 ],
        [ 651, 957 ]
      ],
      close_up: [
        [ 0, 0 ],
        [ 2000, 0 ],
        [ 0, 2666 ],
        [ 2000, 2666 ]
      ]
    },
    square: {
      in_hand: [
        [ 521, 835 ],
        [ 1505, 995 ],
        [ 366, 1800 ],
        [ 1351, 1958 ]
      ],
      green_wall_with_stool: [
        [ 920, 1157 ],
        [ 1280, 1157 ],
        [ 920, 1518 ],
        [ 1280, 1518 ]
      ],
      nightstand: [
        [ 1078, 1865 ],
        [ 1517, 1875 ],
        [ 1054, 2320 ],
        [ 1500, 2340 ]
      ],
      chest_of_drawers: [
        [ 315, 464 ],
        [ 653, 466 ],
        [ 310, 955 ],
        [ 651, 957 ]
      ],
      close_up: [
        [ 0, 0 ],
        [ 2000, 0 ],
        [ 0, 2666 ],
        [ 2000, 2666 ]
      ]
    }
  }

  PREVIEW_WITH_BORDER_DIMENSIONS = {
    portrait: {
      small: [ 40 * STITCH_WIDTH, 55 * STITCH_WIDTH ],
      small_wide: [ 40 * STITCH_WIDTH, 57 * STITCH_WIDTH ],
      medium: [ 55 * STITCH_WIDTH, 75 * STITCH_WIDTH ],
      medium_large: [ 65 * STITCH_WIDTH, 87 * STITCH_WIDTH ],
      medium_tall: [ 55 * STITCH_WIDTH, 75 * STITCH_WIDTH ],
      large: [ 75 * STITCH_WIDTH, 100 * STITCH_WIDTH ],
      large_tall: [ 65 * STITCH_WIDTH, 85 * STITCH_WIDTH ]
    },
    landscape: {
      small: [ 55 * STITCH_WIDTH, 40 * STITCH_WIDTH ],
      small_wide: [ 57 * STITCH_WIDTH, 40 * STITCH_WIDTH ],
      medium: [ 75 * STITCH_WIDTH, 55 * STITCH_WIDTH ],
      medium_large: [ 87 * STITCH_WIDTH, 65 * STITCH_WIDTH ],
      medium_tall: [ 75 * STITCH_WIDTH, 55 * STITCH_WIDTH ],
      large: [ 100 * STITCH_WIDTH, 75 * STITCH_WIDTH ],
      large_tall: [ 85 * STITCH_WIDTH, 65 * STITCH_WIDTH ]
    },
    square: {
      small: [ 43 * STITCH_WIDTH, 43 * STITCH_WIDTH ],
      small_wide: [ 55 * STITCH_WIDTH, 43 * STITCH_WIDTH ],
      medium: [ 55 * STITCH_WIDTH, 55 * STITCH_WIDTH ],
      medium_large: [ 65 * STITCH_WIDTH, 65 * STITCH_WIDTH ],
      medium_tall: [ 55 * STITCH_WIDTH, 75 * STITCH_WIDTH ],
      large: [ 75 * STITCH_WIDTH, 75 * STITCH_WIDTH ],
      large_tall: [ 65 * STITCH_WIDTH, 85 * STITCH_WIDTH ]
    }
  }

  enum :preview_status, { not_generating_preview: "not_generating_preview", generating_preview: "generating_preview", finished_generating_preview: "finished_generating_preview" }

  def distort(offset, top_left, transformed_top_left, top_right, transformed_top_right, bottom_left, transformed_bottom_left, bottom_right, transformed_bottom_right, background)
    preview_image_with_border = MiniMagick::Image.read(preview_with_border(background:).download)
    distorted_preview_image = MiniMagick::Image.create
    MiniMagick.convert do |c|
      c << preview_image_with_border.path
      c.virtual_pixel "transparent"
      c.distort("Perspective", "#{top_left.map(&:to_s).join(',')},#{transformed_top_left.join(',')} #{top_right.join(',')},#{transformed_top_right.join(',')} #{bottom_left.join(',')},#{transformed_bottom_left.join(',')} #{bottom_right.join(',')},#{transformed_bottom_right.join(',')}")
      c << distorted_preview_image.path
    end

    background_image(background).composite(distorted_preview_image) do |c|
      c.geometry "+#{offset[0]}+#{offset[1]}"
      c.matte
      c.virtual_pixel "transparent"
      c.compose COMPOSE.fetch(background)
    end
  end

  def background_image(background)
    orientation_specific_path = Rails.root.join("data", "backgrounds", orientation.to_s, "#{background}.png")
    default_path = Rails.root.join("data", "backgrounds", "#{background}.png")
    path = File.exist?(orientation_specific_path) ? orientation_specific_path : default_path
    MiniMagick::Image.open(path)
  end

  def preview_with_border(background:)
    send("preview_with_border_#{BORDER_SIZE_FOR_BACKGROUND.fetch(orientation.to_sym).fetch(background)}")
  end

  def add_image_for(background)
    four_corners = BACKGROUND_CUTOUT_DIMENSIONS.fetch(orientation.to_sym).fetch(background)
    preview_image = MiniMagick::Image.read(preview_with_border(background:).download)
    preview_image_width = preview_image.width
    preview_image_height = preview_image.height
    top_left = [ 0, 0 ]
    top_right = [ preview_image_width, 0 ]
    bottom_left = [ 0, preview_image_height ]
    bottom_right = [ preview_image_width, preview_image_height ]

    x_offset = four_corners.map { |x, y| x }.min
    y_offset = four_corners.map { |x, y| y }.min
    offset = [ x_offset, y_offset ]
    margin = MARGIN.fetch(background)
    transformed_top_left = [ four_corners[0][0], four_corners[0][1] ].then { |x, y| [ x - offset[0] - margin, y - offset[1] - margin ] }
    transformed_top_right = [ four_corners[1][0], four_corners[1][1] ].then { |x, y| [ x - offset[0] + margin, y - offset[1] - margin ] }
    transformed_bottom_left = [ four_corners[2][0], four_corners[2][1] ].then { |x, y| [ x - offset[0] - margin, y - offset[1] + margin ] }
    transformed_bottom_right = [ four_corners[3][0], four_corners[3][1] ].then { |x, y| [ x - offset[0] + margin, y - offset[1] + margin ] }
    composite_image = distort(offset, top_left, transformed_top_left, top_right, transformed_top_right, bottom_left, transformed_bottom_left, bottom_right, transformed_bottom_right, background)
    composite_image.write(Rails.root.join("tmp", "composite_image_#{background}.png"))
    temp_file = Tempfile.new([ "distorted_preview", ".png" ], "tmp")
    composite_image.write(temp_file.path)
    temp_file.rewind
    number_of_images = images.count
    images.attach(io: temp_file, filename: "#{(number_of_images + 1).to_s.ljust(2, "0")}_preview_image.png", content_type: "image/png")
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

  def update_name_from_fcjson!
    update!(name: (parsed_data.dig(:info, :title) || "").gsub("_png", ""))
  end

  def strip_images_from_definition!
    update!(definition: parsed_data.except(:srcs).to_json)
  end

  def guess_orientation!
    update!(orientation: determine_orientation)
  end

  def determine_orientation
    if width_and_height_are_close_to_square?
      :square
    elsif width > height
      :landscape
    else
      :portrait
    end
  end

  def width_and_height_are_close_to_square?
    (width - height).abs.to_f / [ width, height ].max <= 0.05
  end

  def create_preview
    threads = Pattern.from_fcjson_to_threads(definition)
    combined_image = MiniMagick::Image.create(".png")

    files = threads.flat_map do |row|
      row.map { |thread_id| Rails.root.join("data", "threads", "#{thread_id}.png").to_s }
    end

    MiniMagick::Tool::Montage.new do |montage|
      files.each do |file|
        montage << file
      end
      montage.tile "#{width}x#{height}"
      montage.geometry "#{STITCH_WIDTH}x#{STITCH_WIDTH}+0+0"
      montage.background "none"
      montage << "-virtual-pixel" << "transparent"
      montage << "-font" << "DejaVu-Sans"
      montage << combined_image.path
    end

    combined_image.combine_options do |i|
      i.brightness_contrast "-12x20"
    end

    temp_file = Tempfile.new([ "preview", ".png" ], "tmp")
    combined_image.write(temp_file.path)
    temp_file.rewind

    preview.attach(io: temp_file, filename: "preview.png", content_type: "image/png")
    save!

    temp_file.close
    temp_file.unlink

    self
  end

  def add_border_to_preview(size)
    SemanticLogger.tagged(
      "app.pattern.id" => id,
      "app.pattern.height" => height,
      "app.pattern.width" => width,
      "code.namespace" => "Pattern",
      "code.function.name" => "add_border_to_preview",
      "app.code.args.size" => size,
      "app.pattern.orientation" => orientation
    ) do
      preview_image = MiniMagick::Image.read(preview.download)
      preview_image_width = preview_image.data.dig("geometry", "width")
      preview_image_height = preview_image.data.dig("geometry", "height")
      aida_background = MiniMagick::Image.create(".png")
      aida_image = MiniMagick::Image.open(Rails.root.join("data", "threads", "aida_grey.png"))
      width_with_border, height_with_border = PREVIEW_WITH_BORDER_DIMENSIONS.dig(orientation.to_sym, size)
      MiniMagick.convert do |c|
        c.size "#{width_with_border}x#{height_with_border}"
        c << "tile:#{aida_image.path}"
        c.colorspace "sRGB"
        c.type "TrueColor"
        c << "PNG24:#{aida_background.path}"
      end
      preview_image_on_aida = aida_background.composite(preview_image) do |c|
        c.compose "Over"
        x_offset = ((width_with_border - preview_image_width) / (STITCH_WIDTH * 2)).floor * STITCH_WIDTH
        y_offset = ((height_with_border - preview_image_height) / (STITCH_WIDTH * 2)).floor * STITCH_WIDTH
        c.geometry "+#{x_offset}+#{y_offset}"
      end
      temp_file = Tempfile.new([ "preview_image_on_aida", ".png" ], "tmp")
      preview_image_on_aida.write(temp_file.path)
      temp_file.rewind
      send("preview_with_border_#{size}").attach(io: temp_file, filename: "preview_image_on_aida.png", content_type: "image/png")
      save!
      temp_file.close
      temp_file.unlink

      Rails.logger.info(
          message: "Border added to preview",
          "event.name" => "app.pattern.border_added_to_preview",
        )
    rescue StandardError => e
      Rails.logger.error(
        message: "Error adding border to preview",
        "event.name" => "app.pattern.border_added_to_preview",
        exception: e,
      )
      raise e
    end
  end

  def has_blank_stitches?
    parsed_data.dig(:model, :images, 0, :layers, 0, :cross).include?(-1)
  end

  def self.from_fcjson_to_threads(fcjson_data)
    parsed_data = JSON.parse(fcjson_data, symbolize_names: true)
    crosses = parsed_data.dig(:model, :images, 0, :layers, 0, :cross)
    width = parsed_data.dig(:model, :images, 0, :width)

    crosses.map do |cross|
      if cross == -1
        "_"
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

  def definition_without_images
    parsed_data.except(:srcs)
  end

  def copy_name_into_definition!
    parsed_definition_with_name_as_title = parsed_data.deep_merge(info: { title: name })
    update!(definition: parsed_definition_with_name_as_title.to_json)
  end
end
