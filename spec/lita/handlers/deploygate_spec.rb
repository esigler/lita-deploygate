require 'spec_helper'

describe Lita::Handlers::Deploygate, lita_handler: true do
  let(:members_empty) do
    File.read('spec/files/members_empty.json')
  end

  let(:members_full) do
    File.read('spec/files/members_full.json')
  end

  let(:members_add) do
    File.read('spec/files/members_add.json')
  end

  let(:members_remove) do
    File.read('spec/files/members_remove.json')
  end

  def grab_request(method, status, body)
    response = double('Faraday::Response', status: status, body: body)
    expect_any_instance_of(Faraday::Connection).to \
      receive(method.to_sym).and_return(response)
  end

  %w(deploygate dg).each do |name|
    it do
      is_expected.to route_command("#{name} add username abc123").to(:add)
      is_expected.to route_command("#{name} add foo@example.com abc123")
        .to(:add)
      is_expected.to route_command("#{name} remove username abc123").to(:remove)
      is_expected.to route_command("#{name} remove foo@example.com abc123")
        .to(:remove)
      is_expected.to route_command("#{name} list abc123").to(:list)
    end
  end

  describe '.default_config' do
    it 'sets user_name to nil' do
      expect(Lita.config.handlers.deploygate.user_name).to be_nil
    end

    it 'sets api_key to nil' do
      expect(Lita.config.handlers.deploygate.api_key).to be_nil
    end

    it 'sets app_names to nil' do
      expect(Lita.config.handlers.deploygate.app_names).to be_nil
    end
  end

  describe 'without valid config' do
    it 'errors out on any command' do
      Lita.config.handlers.deploygate.app_names = { 'abc123' =>
                                                    'path/to/places' }
      expect { send_command('dg list abc123') }.to raise_error('Missing ' \
                                                               'config')
    end
  end

  describe 'with valid config' do
    before do
      Lita.config.handlers.deploygate.user_name = 'foo'
      Lita.config.handlers.deploygate.api_key = 'bar'
      Lita.config.handlers.deploygate.app_names = { 'abc123' =>
                                                    'path/to/places' }
    end

    describe '#add' do
      it 'shows an ack when a username is added' do
        grab_request('post', 200, members_add)
        send_command('deploygate add username abc123')
        expect(replies.last).to eq('abc123: username added')
      end

      it 'shows an ack when an email is added' do
        grab_request('post', 200, members_add)
        send_command('deploygate add foo@example.com abc123')
        expect(replies.last).to eq('abc123: foo@example.com added')
      end

      it 'shows a warning if the app name does not exist' do
        send_command('deploygate add username doesnotexist')
        expect(replies.last).to eq('doesnotexist: unknown application name')
      end

      it 'shows an error if there was an issue with the request' do
        grab_request('post', 500, nil)
        send_command('deploygate add username abc123')
        expect(replies.last).to eq('There was an error making the request ' \
                                   'to DeployGate')
      end
    end

    describe '#remove' do
      it 'shows an ack when a username is removed' do
        grab_request('delete', 200, members_remove)
        send_command('deploygate remove username abc123')
        expect(replies.last).to eq('abc123: username removed')
      end

      it 'shows an ack when an email is removed' do
        grab_request('delete', 200, members_remove)
        send_command('deploygate remove foo@example.com abc123')
        expect(replies.last).to eq('abc123: foo@example.com removed')
      end

      it 'shows a warning if the app name does not exist' do
        send_command('deploygate remove username doesnotexist')
        expect(replies.last).to eq('doesnotexist: unknown application name')
      end

      it 'shows an error if there was an issue with the request' do
        grab_request('delete', 500, nil)
        send_command('deploygate remove username abc123')
        expect(replies.last).to eq('There was an error making the request ' \
                                   'to DeployGate')
      end
    end

    describe '#list' do
      it 'shows a list of users when there are any' do
        grab_request('get', 200, members_full)
        send_command('deploygate list abc123')
        expect(replies.last).to eq('abc123: username, role: 1')
      end

      it 'shows an empty list of users when there arent any' do
        grab_request('get', 200, members_empty)
        send_command('deploygate list abc123')
        expect(replies.last).to eq('abc123: No users')
      end

      it 'shows a warning if the app name does not exist' do
        send_command('deploygate list doesnotexist')
        expect(replies.last).to eq('doesnotexist: unknown application name')
      end

      it 'shows an error if there was an issue with the request' do
        grab_request('get', 500, nil)
        send_command('deploygate list abc123')
        expect(replies.last).to eq('There was an error making the request ' \
                                   'to DeployGate')
      end
    end
  end
end
