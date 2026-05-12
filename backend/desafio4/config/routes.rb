Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post   "fixtures/policies",       to: "fixtures#generate_policies"
  get    "fixtures/policy_holders", to: "fixtures#policy_holders"
  post   "importations",            to: "importations#create"
  delete "nuke",                    to: "nuke#destroy"

  get    "simulations", to: "simulations#show"
  post   "simulations", to: "simulations#create"
  delete "simulations", to: "simulations#destroy"

  get    "simulations/activity", to: "activity_simulations#show"
  post   "simulations/activity", to: "activity_simulations#create"
  delete "simulations/activity", to: "activity_simulations#destroy"

  root to: redirect("/index.html")
end
