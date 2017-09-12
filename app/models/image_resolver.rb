# frozen_string_literal: true

# Represents a genereic type of Image Server adapter
class ImageResolver
  include ActiveModel::Model

  attr_accessor :name

  def initialize(params = {})
    @name = params[:name]
  end

  def config
    @config ||= Settings.stacks.adapter[@name]
  end

  def resolver
    config.module
  end
end
