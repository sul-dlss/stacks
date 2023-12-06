# frozen_string_literal: true

# API to create IIIF Authentication access tokens
module Iiif
  module Auth
    module V2
      # Check access for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#probe-service
      class ProbeServiceController < ApplicationController
        def show
          # The HTTP status code that the client should expect to receive if it were to issue
          # the same request to the resource
          status = 200
          response = {
            '@context' => 'http://iiif.io/api/auth/2/context.json',
            type: 'AuthProbeResult2',
            status:
          }

          render json: response
        end
      end
    end
  end
end
