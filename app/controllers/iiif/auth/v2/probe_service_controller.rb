# frozen_string_literal: true

# API to create IIIF Authentication access tokens
module Iiif
  module Auth
    module V2
      # Check access for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#probe-service
      class ProbeServiceController < ApplicationController
        def show
          stacks_uri = params[:id] # this is a fully qualified URI to the resource on the stacks that the user is requesting access to
          druid, file_name = stacks_uri.split('/').last(2) # need the druid (without prefix) and the filename in order to check for access

          file = StacksFile.new(id: druid.delete_prefix('druid:'), file_name:, download: true)

          response = { '@context': 'http://iiif.io/api/auth/2/context.json', type: 'AuthProbeResult2' }

          if can? :access, file
            response[:status] = 200
          else
            # TODO: check restrictions on file object and include details in response e.g. like in MediaController#hash_for_auth_check
            response[:status] = 401
            response[:heading] = { en: ["You can't see this"] }
            response[:note] = { en: ["Sorry"] }
          end

          render json: response
        end
      end
    end
  end
end
