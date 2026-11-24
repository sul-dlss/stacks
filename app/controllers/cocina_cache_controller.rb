# frozen_string_literal: true

# Lets applications like purl-fetcher manually purge the cocina cache
class CocinaCacheController < ApplicationController
  skip_forgery_protection

  def destroy
    authorize! :purge, Cocina

    Cocina.expire(params[:id], version: params[:version_id])
    head :no_content
  end
end
