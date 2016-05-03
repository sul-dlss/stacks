require 'rails_helper'

describe FileController, vcr: { record: :new_episodes } do
  before do
    controller.instance_variable_set(:@file, file)
  end

  let(:file) { StacksFile.new(id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2') }

  describe '#show' do
    subject { get :show, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' }

    before do
      allow(file).to receive_messages(exist?: true, mtime: Time.zone.now, path: File.join(Rails.root, 'Gemfile'))
    end

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(file.path).and_call_original
      subject
    end

    context 'additional params' do
      subject { get :show, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', ignored: 'ignored', host: 'host' }
      it 'ignored when instantiating StacksFile' do
        expect { assigns(:file) }.not_to raise_exception
        expect(assigns(:file)).to be_a StacksFile
      end
    end

    context 'for a missing file' do
      before do
        expect(controller).to receive(:send_file).with(file.path).and_raise ActionController::MissingFile
      end

      it 'returns a 404 Not Found' do
        expect(subject.status).to eq 404
      end
    end

    context 'for a restricted image' do
      before do
        allow(controller).to receive(:authorize!).and_raise CanCan::AccessDenied
      end

      context 'with an authenticated user' do
        let(:user) { User.new }

        before do
          allow(controller).to receive(:current_user).and_return(user)
        end

        it 'fails' do
          expect(subject.status).to eq 403
        end
      end

      context 'with an unauthenticated user' do
        it 'redirects to the webauth login endpoint' do
          expect(subject).to redirect_to auth_file_url(controller.params.symbolize_keys)
        end
        context 'additional params' do
          subject { get :show, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', ignored: 'ignored' }
          it 'ignored when redirecting' do
            expect(subject).not_to redirect_to(auth_file_url(controller.params.symbolize_keys))
            expect(subject).to redirect_to(auth_file_url(controller.send(:allowed_params).symbolize_keys))
            expect(subject).not_to redirect_to('/file/auth/xf680rd3068/xf680rd3068_1.jp2?ignored=ignored')
            expect(subject).to redirect_to('/file/auth/xf680rd3068/xf680rd3068_1.jp2')
          end
        end
      end
    end
  end
end
