# frozen_string_literal: true

##
# Basic application landing pages
class StacksController < ApplicationController
  def index
    render file: "#{Rails.root}/public/index.html", layout: false

  end
end
