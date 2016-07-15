Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :documents

  get 'search', to: 'documents#search'

  root 'documents#index'
end
