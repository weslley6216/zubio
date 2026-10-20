class Client::BaseController < ApplicationController
  include Client::CurrentClient

  private

  def browser_restricted? = false
end
