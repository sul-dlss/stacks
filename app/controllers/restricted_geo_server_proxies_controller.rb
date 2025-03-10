# frozen_string_literal: true

# Proxy restricted geoserver
class RestrictedGeoServerProxiesController < ApplicationController
  def show
    self.status = proxied_response.status
    send_data proxied_response.body, type: proxied_response.headers['Content-Type'], disposition: 'inline'
  end

  def request_url
    request.url.gsub(Settings.geo.proxy_url, Settings.geo.restricted_wms_url)
  end

  def proxied_response
    @proxied_response ||= benchmark "Fetch #{request_url}" do
      HTTP.get(request_url)
    end
  end
end
