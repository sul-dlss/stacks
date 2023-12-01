# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetricsConcern do
  controller do
    # rubocop:disable RSpec/DescribedClass
    include MetricsConcern
    # rubocop:enable RSpec/DescribedClass

    def download
      track_download params[:druid], file: params[:file]
      head :ok
    end
  end

  let(:metrics_service) { instance_double(MetricsService) }
  let(:visit_cookie) { 'abc123' }
  let(:visitor_cookie) { 'xyz789' }

  before do
    allow(Settings.features).to receive(:metrics).and_return(true)
    allow(controller).to receive(:metrics_service).and_return(metrics_service)
    routes.draw { get 'download' => 'anonymous#download' }
    cookies[:ahoy_visit] = visit_cookie
    cookies[:ahoy_visitor] = visitor_cookie
  end

  describe '#track_download' do
    before do
      allow(metrics_service).to receive(:track_visit)
      allow(metrics_service).to receive(:track_event)
    end

    it 'tracks a download event with the druid' do
      get 'download', params: { druid: 'fd063dh3727' }
      expect(metrics_service).to have_received(:track_event).with(
        visit_token: visit_cookie,
        visitor_token: visitor_cookie,
        events: [
          {
            id: be_kind_of(String),
            time: be_kind_of(Time),
            name: 'download',
            properties: {
              druid: 'fd063dh3727'
            }
          }
        ]
      )
    end

    context 'when an individual file is passed' do
      it 'tracks the event with the druid and filename' do
        get 'download', params: { druid: 'fd063dh3727', file: 'file.txt' }
        expect(metrics_service).to have_received(:track_event).with(
          visit_token: visit_cookie,
          visitor_token: visitor_cookie,
          events: [
            {
              id: be_kind_of(String),
              time: be_kind_of(Time),
              name: 'download',
              properties: {
                druid: 'fd063dh3727',
                file: 'file.txt'
              }
            }
          ]
        )
      end
    end

    context 'when a visit is not in progress' do
      let(:visit_cookie) { nil }

      it 'creates a new visit' do
        get 'download', params: { druid: 'fd063dh3727' }
        expect(metrics_service).to have_received(:track_visit)
      end
    end
  end
end
