# frozen_string_literal: true

module Iiif
  module Auth
    # API to create IIIF Authentication access tokens
    module V2
      # Check access for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#probe-service
      class ProbeServiceController < ApplicationController
        # Example call:
        # /iiif/auth/v2/probe?id=https://stacks-uat.stanford.edu/file/druid:bb461xx1037/folder/SC0193_1982-013_b06_f01_1981-09-29.pdf
        def show
          stacks_uri = params[:id] # this is a fully qualified URI to the resource on the stacks that the user is requesting access to
          parsed_uri = parse_uri(stacks_uri)
          begin
            cocina = Cocina.find(parsed_uri[:druid])
            file = StacksFile.new(file_name: parsed_uri[:file_name], cocina:)
          rescue Purl::Exception
            return render json: AuthProbeResult2.not_found(parsed_uri[:druid])
          end

          render json: auth_probe_result(file, cocina)
        end

        def iiif_location(is_geo, stacks_file)
          if is_geo
            # 4 hour token
            token = JWT.encode({ data: 'geo_token', exp: Time.now.to_i + (4 * 3600) }, Settings.geo.proxy_secret, 'HS256')
            { id: "#{Settings.geo.proxy_url}?stacks_token=#{URI.encode_uri_component(token)}", type: 'Geo' }
          else
            stream_url = StacksMediaStream.new(stacks_file:).streaming_url
            { id: stream_url, type: 'Video' }
          end
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

        # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        def auth_probe_result(file, cocina)
          if !file.valid?
            AuthProbeResult2.bad_request(file.errors.full_messages)
          elsif !file.readable?
            AuthProbeResult2.not_found(cocina.druid)
          elsif can? :access, file
            if file.streamable? || cocina.geo?
              AuthProbeResult2.redirect(iiif_location(cocina.geo?, file))
            else
              AuthProbeResult2.ok
            end
          elsif file.stanford_restricted?
            AuthProbeResult2.unauthorized(**unauthorized_fields(file))
          else
            AuthProbeResult2.forbidden(**forbidden_fields(file))
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

        def forbidden_fields(file)
          if file.embargoed?
            { heading: I18n.t('probe_service.embargoed', date: file.embargo_release_date.to_date),
              icon: I18n.t('probe_service.embargoed_icon') }
          elsif file.restricted_by_location?
            { heading: I18n.t('probe_service.location', location: Settings.user.locations.labels.send(file.location)),
              icon: I18n.t('probe_service.location_icon') }
          else
            { heading: I18n.t("probe_service.no_download"), icon: I18n.t('probe_service.no_download_icon') }
          end
        end

        # add details to response for when stanford_restricted?
        def unauthorized_fields(file)
          if file.embargoed?
            { heading: I18n.t('probe_service.stanford_and_embargoed', date: file.embargo_release_date.to_date),
              icon: I18n.t('probe_service.embargoed_icon') }
          else
            { heading: I18n.t('probe_service.stanford'), icon: I18n.t('probe_service.stanford_icon') }
          end
        end

        # We expect the incoming stacks URI param to be URI encoded and we then
        # parse the stacks URI by removing the '/file/druid:' and then separating druid from filename (with paths)
        def parse_uri(uri)
          obj = begin
            URI(uri)
          rescue URI::InvalidURIError
            raise ActionDispatch::Http::Parameters::ParseError
          end
          druid, file_name = URI.decode_uri_component(obj.path.delete_prefix('/file/')).split('/', 2)
          raise ActionDispatch::Http::Parameters::ParseError, "Provided ID is not local" unless druid

          { druid: druid.delete_prefix('druid:'), file_name: }
        end
      end
    end
  end
end
