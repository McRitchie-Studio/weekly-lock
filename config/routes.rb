Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  get "weeks/:week" => "locks#show", as: :week, constraints: { week: /\d+/ }
  root "locks#index"
end
