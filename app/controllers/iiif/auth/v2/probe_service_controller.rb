# frozen_string_literal: true

module Iiif
  module Auth
    # API to create IIIF Authentication access tokens
    module V2
      # Check access for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#probe-service
      class ProbeServiceController < ApplicationController
        def show
          # Example call:
          # /iiif/auth/v2/probe?id=https://stacks-uat.stanford.edu/file/druid:bb461xx1037/folder/SC0193_1982-013_b06_f01_1981-09-29.pdf
          stacks_uri = params[:id] # this is a fully qualified URI to the resource on the stacks that the user is requesting access to
          parsed_uri = parse_uri(stacks_uri)

          file = StacksFile.new(id: parsed_uri[:druid], file_name: parsed_uri[:file_name], download: true)

          response = { '@context': 'http://iiif.io/api/auth/2/context.json', type: 'AuthProbeResult2' }

          if can? :access, file
            response[:status] = 200
          else
            response[:status] = 401
            response.merge!(add_detail(file))
          end

          render json: response
        end

        private

        # add details to response for when access is denied
        def add_detail(file)
          detail = {}
          if file.stanford_restricted? && !file.embargoed?
            detail[:heading] = { en: ["Stanford-affiliated? Login to play"] }
            detail[:auth_url] = iiif_auth_api_url
          elsif file.stanford_restricted? && file.embargoed?
            detail[:heading] = { en: ["Content is both Stanford restricted and embargoed until #{file.embargo_release_date.to_date}"] }
          elsif file.embargoed?
            detail[:heading] = { en: ["Content is embargoed until #{file.embargo_release_date.to_date}"] }
          elsif file.restricted_by_location?
            detail[:heading] = { en: ["Content is restricted to location #{Settings.user.locations.labels.send(file.location)}"] }
          end
          detail[:note] = { en: ["Access restricted"] }
          detail
        end

        # parse the stacks resource URI by taking just full path, removing the '/file/' and then separating druid from filename (with paths)
        def parse_uri(uri)
          uri_parts = URI(uri).path.delete_prefix('/file/').split('/')
          druid = uri_parts.first.delete_prefix('druid:')
          file_name = uri_parts[1..].join('/')
          { druid:, file_name: }
        end
      end
    end
  end
end
