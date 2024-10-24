class PatternsController < ApplicationController
  def new
    render :new
  end

  def create
    pattern = Pattern.create!(name: "Untitled", definition: params[:fcjson].read)
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

  def distort_preview
    @pattern = Pattern.find(params[:id])
    @pattern.distort_preview
    render :distorted_preview
  end
end
