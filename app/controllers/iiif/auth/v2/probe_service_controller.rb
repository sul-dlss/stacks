# frozen_string_literal: true

module Iiif
  module Auth
    # API to create IIIF Authentication access tokens
    module V2
      # Check access for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#probe-service
      class ProbeServiceController < ApplicationController
        def show # rubocop:disable Metrics:AbcSize
          # Example call:
          # /iiif/auth/v2/probe?id=https://stacks-uat.stanford.edu/file/druid:bb461xx1037/folder/SC0193_1982-013_b06_f01_1981-09-29.pdf
          stacks_uri = params[:id] # this is a fully qualified URI to the resource on the stacks that the user is requesting access to
          parsed_uri = parse_uri(stacks_uri)

          file = StacksFile.new(id: parsed_uri[:druid], file_name: parsed_uri[:file_name], download: true)

          json = { '@context': 'http://iiif.io/api/auth/2/context.json', type: 'AuthProbeResult2' }

          if !file.valid?
            json[:status] = 400
            json[:note] = { "en": file.errors.full_messages }
          elsif !file.readable?
            json[:status] = 404
          elsif can? :access, file
            if file.streamable?
              # See https://iiif.io/api/auth/2.0/#location
              json[:status] = 302
              json[:location] = {
                id: "#{file.streaming_url}?stacks_token=#{current_user.token}",
                type: "Video"
              }
            else
              json[:status] = 200
            end
          else
            json[:status] = 401
            json.merge!(add_detail(file))
          end

          render json:
        end

        # Because the probe request sets the Accept header, the browser is going to preflight the request.
        # Here we tell the browser, yes, we're good with this.
        def options_pre_flight
          response.headers['Access-Control-Allow-Origin'] = '*'
          response.headers['Access-Control-Allow-Methods'] = 'GET'
          response.headers['Access-Control-Allow-Headers'] = 'Authorization'
          response.headers['Access-Control-Max-Age'] = '1728000'
          head :no_content
        end

        private

        # add details to response for when access is denied
        # rubocop:disable Metrics/AbcSize
        def add_detail(file)
          detail = {}
          if file.stanford_restricted? && !file.embargoed?
            detail[:heading] = { en: [I18n.t('probe_service.stanford')] }
            detail[:auth_url] = iiif_auth_api_url
          elsif file.stanford_restricted? && file.embargoed?
            detail[:heading] = { en: [I18n.t('probe_service.stanford_and_embargoed', date: file.embargo_release_date.to_date)] }
          elsif file.embargoed?
            detail[:heading] = { en: [I18n.t('probe_service.embargoed', date: file.embargo_release_date.to_date)] }
          elsif file.restricted_by_location?
            detail[:heading] = { en: [I18n.t('probe_service.location', location: Settings.user.locations.labels.send(file.location))] }
          end
          detail[:note] = { en: [I18n.t('probe_service.access_restricted')] }
          detail
        end
        # rubocop:enable Metrics/AbcSize

        # We expect the incoming stacks URI param to be URI encoded and we then
        # parse the stacks URI by removing the '/file/druid:' and then separating druid from filename (with paths)
        def parse_uri(uri)
          obj = begin
            URI(uri)
          rescue URI::InvalidURIError
            raise ActionDispatch::Http::Parameters::ParseError
          end
          druid, file_name = URI.decode_uri_component(obj.path.delete_prefix('/file/')).split('/', 2)
          { druid: druid.delete_prefix('druid:'), file_name: }
        end
      end
    end
  end
end
