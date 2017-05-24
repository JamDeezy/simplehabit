Rails.application.routes.draw do
  namespace :api, defaults: {format: :json} do
    get 'recommendations', to: "recommendation#recommendations"
  end

  # Forward route for solution correctness
  get 'recommendations', to: "api/recommendation#recommendations"
end
