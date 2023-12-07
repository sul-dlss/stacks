# frozen_string_literal: true

# API to create IIIF Authentication access tokens
module Iiif
  module Auth
    module V2
      # Check access for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#probe-service
      class ProbeServiceController < ApplicationController
        # rubocop:disable Metrics/AbcSize
        def show
          stacks_uri = params[:id] # this is a fully qualified URI to the resource on the stacks that the user is requesting access to
          druid, file_name = stacks_uri.split('/').last(2) # need the druid (without prefix) and the filename in order to check for access

          file = StacksFile.new(id: druid.delete_prefix('druid:'), file_name:, download: true)

          response = { '@context': 'http://iiif.io/api/auth/2/context.json', type: 'AuthProbeResult2' }

          if can? :access, file
            response[:status] = 200
          else
            response[:status] = 401
            if file.stanford_restricted?
              response[:heading] = { en: ["Stanford-affiliated? Login to play"] }
              response[:auth_url] = iiif_auth_api_url
            elsif file.embargoed?
              response[:heading] = { en: ["Content is embargoed until #{file.embargo_release_date}"] }
            elsif file.restricted_by_location?
              response[:heading] = { en: ["Content is restricted to location #{Settings.user.locations.labels.send(file.location)}"] }
            end
            response[:note] = { en: ["Access restricted"] }
          end

          render json: response
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
