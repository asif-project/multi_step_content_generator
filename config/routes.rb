Rails.application.routes.draw do
  # The page with the idea box
  root "contents#new"

  # The Generate button sends the form here
  post "/generate", to: "contents#create", as: :generate
end
