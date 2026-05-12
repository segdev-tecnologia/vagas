Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post   "fixtures/policies",       to: "fixtures#generate_policies"
  get    "fixtures/policy_holders", to: "fixtures#policy_holders"
  post   "importations",            to: "importations#create"
  delete "nuke",                    to: "nuke#destroy"

  root to: redirect("/index.html")
end
