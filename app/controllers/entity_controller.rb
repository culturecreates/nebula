class EntityController < ApplicationController
  # Show an entity /entity?uri=
  def show
   @entity = params[:uri] ||= "Gregory"

  end
end
