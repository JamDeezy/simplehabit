require 'recommendation_engine'

class API::RecommendationController < ApplicationController

  def recommendations
    render json: RecommendationEngine.recommend(params[:subtopic])
  end

end
