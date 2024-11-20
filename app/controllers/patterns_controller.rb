require "zip"

class PatternsController < ApplicationController
  def new
    render :new
  end

  def create
    pattern = Pattern.create!(definition: params[:fcjson].read)
    pattern.strip_images_from_definition!
    pattern.update_name_from_fcjson!
    pattern.guess_orientation!
    redirect_to edit_pattern_path(pattern)
  end

  def edit
    @pattern = Pattern.find(params[:id])
  end

  def update
    @pattern = Pattern.find(params[:id])
    @pattern.update!(pattern_params)
    @pattern.copy_name_into_definition!
    @pattern.start_generating_preview!
    CreatePreviewFromPatternJob.perform_later(@pattern.id)

    redirect_to pattern_path(@pattern), notice: "Creating preview..."
  end

  def show
    @pattern = Pattern.find(params[:id])
    render :show
  end

  def update_progress
    @pattern = Pattern.find(params[:id])
    render partial: "patterns/progress_bar"
  end

  def download_pdf
    @pattern = Pattern.find(params[:id])
    response = HTTParty.post(
      "#{pdf_service_host}/download_pdf",
      body: { pattern: @pattern.definition_without_images }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    if response.success?
      send_data response.body, filename: "#{@pattern.name.parameterize}_pattern.pdf", type: "application/pdf", disposition: "inline"
    else
      Rails.logger.info("Download PDF response: #{response.body}")
      render :show, status: :unprocessable_entity
    end
  end

  def pdf_service_host
    if Rails.env.development?
      "http://localhost:3004"
    else
      "http://pdf_service:3004"
    end
  end

  def download
    @pattern = Pattern.find(params[:id])

    if @pattern.finished_generating_preview?
      compressed_filestream = Zip::OutputStream.write_buffer do |zos|
        @pattern.images.each_with_index do |image, index|
          zos.put_next_entry "#{(index + 1).to_s.rjust(2, "0")}_#{@pattern.name.parameterize}_preview_image.png"
          zos.print IO.binread(ActiveStorage::Blob.service.path_for(image.key))
        end
      end

      compressed_filestream.rewind
      send_data compressed_filestream.read, filename: "#{@pattern.name.parameterize}_images.zip", type: "application/zip"
    else
      flash[:alert] = "Preview generation is not yet complete."
      redirect_to pattern_path(@pattern)
    end
  end

  private

  def pattern_params
    params.require(:pattern).permit(:name, :orientation)
  end

  def calculate_dimensions(fcjson_data)
    width = fcjson_data["width"]
    height = fcjson_data["height"]
    { width: width, height: height }
  end

  def determine_orientation(dimensions)
    if dimensions[:width] == dimensions[:height]
      "square"
    elsif dimensions[:width] > dimensions[:height]
      "landscape"
    else
      "portrait"
    end
  end
end
