class PatternsController < ApplicationController
  def new
    render :new
  end

  def create
    pattern = Pattern.from_fcjson(params[:fcjson].read)
    redirect_to pattern_path(pattern)
  end

  def show
    pattern = Pattern.find(params[:id])
    render :show, locals: { pattern: }
  end
end
