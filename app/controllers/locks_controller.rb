class LocksController < ApplicationController
  before_action :set_season

  def index
    @lock = @season.this_week
  end

  def show
    @lock = @season.find(params[:week].to_i) or raise ActionController::RoutingError, "No week #{params[:week]}"
    @previous = @season.find(@lock.week - 1)
    @next = @season.find(@lock.week + 1)
  end

  private

  def set_season
    @season = Season.current.as_of(Date.current)
  end
end
