require "zip"

class PatternsController < ApplicationController
  def new
    render :new
  end

  def create
    pattern = Pattern.create!(name: "Untitled", definition: params[:fcjson].read)
    pattern.start_generating_preview!
    CreatePreviewFromPatternJob.perform_later(pattern.id)
    redirect_to pattern_path(pattern)
  end

  def show
    @pattern = Pattern.find(params[:id])
    render :show
  end

  def update_progress
    @pattern = Pattern.find(params[:id])
    render partial: "patterns/progress_bar"
  end

  def composed_preview
    @pattern = Pattern.find(params[:id])
    @pattern.compose_on_background
    render :composed_preview
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
end
