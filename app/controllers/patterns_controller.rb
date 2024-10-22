class PatternsController < ApplicationController
  def new
    render :new
  end

  def create
    pattern = Pattern.create(name: "Untitled", definition: params[:fcjson].read)
    CreatePatternFromFcjsonJob.perform_later(pattern.id)
    redirect_to pattern_path(pattern)
  end

  def show
    pattern = Pattern.find(params[:id])
    render :show, locals: { pattern: }
  end
end
