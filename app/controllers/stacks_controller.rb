# frozen_string_literal: true

##
# Basic application landing pages
class StacksController < ApplicationController
  def index
    # render file: "#{Rails.root}/public/index.html", layout: false
    send_file '/public/index.html', type: 'text/html; charset=utf-8'
  end
end
