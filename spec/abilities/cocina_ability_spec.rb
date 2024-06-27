# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe CocinaAbility, type: :model do
  subject(:ability) { described_class.new(user) }

  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
    allow(image).to receive_messages(image_width: 11_957, image_height: 15_227)
  end

  let(:user) { nil }

  let(:public_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => files
            }
          }
        ]
      }
    }
  end
  let(:files) do
    [file_json, image_json, media_json]
  end

  let(:file_json) do
    {
      'filename' => 'file.csv',
      'access' => access,
      'hasMimeType' => 'text/csv'
    }
  end

  let(:image_json) do
    {
      'filename' => 'image.jpg',
      'access' => access,
      'hasMimeType' => 'image/jp2'
    }
  end

  let(:media_json) do
    {
      'filename' => 'movie.mp4',
      'access' => access,
      'hasMimeType' => 'video/mp4'
    }
  end

  let(:file) do
    StacksFile.new(id: 'xxxxxxx', file_name: 'file.csv')
  end
  let(:image) do
    StacksImage.new(id: 'yx350pf4616', file_name: 'image.jpg')
  end
  let(:media) do
    StacksMediaStream.new(id: 'xxxxxxx', file_name: 'movie.mp4')
  end

  let(:thumbnail_transformation) { IIIF::Image::OptionDecoder.decode(region: 'full', size: '!400,400') }
  let(:thumbnail) { Projection.new(image, thumbnail_transformation) }
  let(:best_fit_thumbnail_transformation) { IIIF::Image::OptionDecoder.decode(region: 'full', size: '!600,500') }
  let(:best_fit_thumbnail) { Projection.new(image, best_fit_thumbnail_transformation) }
  let(:square_transformation) { IIIF::Image::OptionDecoder.decode(region: 'square', size: '!400,400') }
  let(:square_thumbnail) { Projection.new(image, square_transformation) }
  let(:tile_transformation) { IIIF::Image::OptionDecoder.decode(region: '0,0,100,100', size: '256,256') }
  let(:tile) { Projection.new(image, tile_transformation) }

  let(:big_transform) { IIIF::Image::OptionDecoder.decode(region: 'full', size: '748,') }
  let(:big_image) { Projection.new(image, big_transform) }

  context 'with a stanford webauth user' do
    let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w[stanford:stanford]) }

    context 'with a world-readable file' do
      let(:access) do
        {
          'view' => 'world',
          'download' => 'world'
        }
      end

      it { is_expected.to be_able_to(:download, file) }
      it { is_expected.to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
      it { is_expected.to be_able_to(:read, big_image) }
    end

    context 'with a stanford-only file' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'stanford'
        }
      end

      it { is_expected.to be_able_to(:download, file) }
      it { is_expected.to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
      it { is_expected.to be_able_to(:read, big_image) }
    end

    context 'with read rights but not download' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'none'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, big_image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, best_fit_thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with a file with no read access' do
      let(:access) do
        {
          'view' => 'none',
          'download' => 'none'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, tile) }
      it { is_expected.not_to be_able_to(:stream, media) }
      it { is_expected.not_to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end
  end

  context 'with a non-stanford webauth user' do
    let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w[stanford:sponsored]) }

    context 'with a world-readable file' do
      let(:access) do
        {
          'view' => 'world',
          'download' => 'world'
        }
      end

      it { is_expected.to be_able_to(:download, file) }
      it { is_expected.to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with a stanford-only file' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'stanford'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, tile) }
      it { is_expected.not_to be_able_to(:stream, media) }
      it { is_expected.not_to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with a stanford-only file that is not the thumbnail' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'stanford'
        }
      end
      let(:true_thumbnail) do
        {
          'filename' => 'x/y.jpg',
          'access' => access,
          'hasMimeType' => 'image/jp2'
        }
      end
      let(:files) do
        [file_json, true_thumbnail, image_json, media_json]
      end

      it { is_expected.not_to be_able_to(:read, thumbnail) }
      it { is_expected.not_to be_able_to(:read, square_thumbnail) }
    end

    context 'with a stanford-only file that is the first image in an object without an explicit thumbnail' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'stanford'
        }
      end

      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with read rights but not download' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'none'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, tile) }
      it { is_expected.not_to be_able_to(:stream, media) }
      it { is_expected.not_to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end
  end

  context 'with a no-download file that is not the thumbnail' do
    let(:access) do
      {
        'view' => 'world',
        'download' => 'none'
      }
    end
    let(:true_thumbnail) do
      {
        'filename' => 'x/y.jpg',
        'access' => access,
        'hasMimeType' => 'image/jp2'
      }
    end
    let(:files) do
      [file_json, true_thumbnail, image_json, media_json]
    end

    it { is_expected.to be_able_to(:read, thumbnail) }
    it { is_expected.to be_able_to(:read, square_thumbnail) }
  end

  context 'with location-based access restrictions' do
    let(:access) do
      {
        'view' => 'location-based',
        'download' => 'location-based',
        'location' => 'location1'
      }
    end

    context 'with an anonymous user from a configured location' do
      let(:user) { User.new(ip_address: 'ip.address2') }

      it { is_expected.to be_able_to(:download, file) }
      it { is_expected.to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with an anonymous user not in the configured location' do
      let(:user) { User.new(ip_address: 'some.unknown.ip') }

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, tile) }
      it { is_expected.not_to be_able_to(:stream, media) }
      it { is_expected.not_to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with media that allows read but not download' do
      let(:access) do
        {
          'view' => 'location-based',
          'download' => 'none',
          'location' => 'location1'
        }
      end

      context 'with an anonymous user from a configured location' do
        let(:user) { User.new(ip_address: 'ip.address2') }

        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with an anonymous user not in the configured location' do
        let(:user) { User.new(ip_address: 'some.unknown.ip') }

        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end
    end
  end

  context 'with an anonymous user' do
    context 'with a world-readable file' do
      let(:access) do
        {
          'view' => 'world',
          'download' => 'world'
        }
      end

      it { is_expected.to be_able_to(:download, file) }
      it { is_expected.to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with a stanford-only file' do
      let(:access) do
        {
          'view' => 'stanford',
          'download' => 'stanford'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, tile) }
      it { is_expected.not_to be_able_to(:stream, media) }
      it { is_expected.not_to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with a an unreadable file' do
      let(:access) do
        {
          'view' => 'none',
          'download' => 'none'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.not_to be_able_to(:read, tile) }
      it { is_expected.not_to be_able_to(:stream, media) }
      it { is_expected.not_to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with read rights but not download' do
      let(:access) do
        {
          'view' => 'world',
          'download' => 'none'
        }
      end

      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end
  end

  context 'with world (no-download), and full access for stanford users' do
    let(:access) do
      {
        'view' => 'world',
        'download' => 'stanford'
      }
    end

    context 'with an anonymous user' do
      it { is_expected.not_to be_able_to(:download, file) }
      it { is_expected.not_to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end

    context 'with a stanford webauth user' do
      let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w[stanford:stanford]) }

      it { is_expected.to be_able_to(:download, file) }
      it { is_expected.to be_able_to(:download, image) }
      it { is_expected.to be_able_to(:read, tile) }
      it { is_expected.to be_able_to(:stream, media) }
      it { is_expected.to be_able_to(:access, file) }
      it { is_expected.to be_able_to(:read_metadata, image) }
      it { is_expected.to be_able_to(:read, thumbnail) }
      it { is_expected.to be_able_to(:read, square_thumbnail) }
    end
  end
end
