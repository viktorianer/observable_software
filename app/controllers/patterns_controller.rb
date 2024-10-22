class PatternsController < ApplicationController
  def new
    render :new
  end

  def create
    pattern = Pattern.create!(name: "Untitled", definition: params[:fcjson].read)
    CreatePatternFromFcjsonJob.perform_later(pattern.id)
    redirect_to pattern_path(pattern), turbo: false
  end

  def show
    @pattern = Pattern.find(params[:id])
    render :show
  end

  def update_progress
    @pattern = Pattern.find(params[:id])
    render partial: "patterns/progress_bar"
  end
end
