require 'spec_helper'
require 'savon'
require "savon/mock/spec_helper"
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)


describe Celltrust do

  let(:error_response) {"<?xml version=\"1.0\" ?>
                        <SecureSMSResponse><Error><ErrorCode>206</ErrorCode>
                        <ErrorString>Username is not valid.</ErrorString></Error>
                        </SecureSMSResponse>"
                        }

  let(:success_response) {"<TxTNotifyResponse>
                           <MsgResponseList>
                           <MsgResponse type=\"SMS\">
                           <Status>ACCEPTED</Status>
                           <MessageId>AAXF505566459PM14</MessageId>
                           </MsgResponse>
                           </MsgResponseList>
                           </TxTNotifyResponse>"
                          }

  describe Celltrust::SimpleSMSClient do

    before do
      @sms_client = Celltrust::SimpleSMSClient.new('username', 'secret')
    end

    describe 'http client' do
      it 'shoud use ssl' do
        expect(@sms_client.client).to be_an_instance_of(Net::HTTP)
        expect(@sms_client.client.use_ssl?).to be_truthy
      end

      it 'should point to TxtNotifier' do
        expect(@sms_client.path).not_to be_empty
        expect(@sms_client.path).to eq("/TxTNotify/TxTNotify")
      end
    end

    describe 'client' do

      context "no nickname" do
        it 'nickname should be equal username' do
          expect(@sms_client.nickname).not_to be_empty
          expect(@sms_client.nickname).to eq('username')
        end
      end

      context "nickname provided" do
        before(:each) do
          @sms_client = Celltrust::SimpleSMSClient.new('username', 'secret', 'nicknammeee')
        end

        it 'nickname should be equal username' do
          expect(@sms_client.nickname).not_to be_empty
          expect(@sms_client.nickname).to eq('nicknammeee')
        end
      end
    end

    describe 'send_sms method' do
      it 'posts to the sms resource and returns a response object' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return(:status => 200, :body => "", :headers => {})

        expect(@sms_client.send_sms('destination','message')).to be_an_instance_of(Celltrust::Response)
      end

      it 'returns response with status and message_id' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return({ :body => success_response })

        response = @sms_client.send_sms('destination','message')
        expect(response.message_id).to eq("AAXF505566459PM14")
        expect(response.status).to eq("ACCEPTED")
      end

    end

    describe 'send_sms bang method' do
      it 'raises an exception if the response code is not expected' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return(:status => 500)

        expect{ @sms_client.send_sms!('destination','message')}.to raise_error(Celltrust::Error)
      end

      it 'raises an exception if the response body contains an error' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return({ :body => error_response })

        expect{@sms_client.send_sms!('destination','message')}.to raise_error(Celltrust::Error)
      end

      it 'returns message_id' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return({ :body => success_response })

        expect(@sms_client.send_sms!('destination','message')).to eq("AAXF505566459PM14")
      end
    end
  end

  describe Celltrust::SecureSMSClient do

    before do
      @sms_client = Celltrust::SecureSMSClient.new('username', 'secret')
    end

    describe 'http client' do
      it 'shoud use ssl' do
        expect(@sms_client.client).to be_an_instance_of(Net::HTTP)
        expect(@sms_client.client.use_ssl?).to be_truthy
      end

      it 'should point to SecureSMS' do
        expect(@sms_client.path).not_to be_empty
        expect(@sms_client.path).to eq("/TxTNotify/SecureSMS")
      end
    end

    describe 'client' do

      context "no nickname" do
        it 'nickname should be equal username' do
          expect(@sms_client.nickname).not_to be_empty
          expect(@sms_client.nickname).to eq('username')
        end
      end

      context "nickname provided" do
        before(:each) do
          @sms_client = Celltrust::SimpleSMSClient.new('username', 'secret', 'nicknammeee')
        end

        it 'nickname should be equal username' do
          expect(@sms_client.nickname).not_to be_empty
          expect(@sms_client.nickname).to eq('nicknammeee')
        end
      end
    end

    describe 'send_sms method' do
      it 'posts to the sms resource and returns a response object' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return(:status => 200, :body => "", :headers => {})

        expect(@sms_client.send_sms('destination','message')).to be_an_instance_of(Celltrust::Response)
      end

      it 'returns response with status and message_id' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return({ :body => success_response })

        response = @sms_client.send_sms('destination','message')
        expect(response.message_id).to eq("AAXF505566459PM14")
        expect(response.status).to eq("ACCEPTED")
      end

    end

    describe 'send_sms bang method' do
      it 'raises an exception if the response code is not expected' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return(:status => 500)

        expect{ @sms_client.send_sms!('destination','message')}.to raise_error(Celltrust::Error)
      end

      it 'raises an exception if the response body contains an error' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return({ :body => error_response })

        expect{@sms_client.send_sms!('destination','message')}.to raise_error(Celltrust::Error)
      end

      it 'returns message_id' do
        stub_request(:post, /.*gateway.celltrust.net.*/)
        .to_return({ :body => success_response })

        expect(@sms_client.send_sms!('destination','message')).to eq("AAXF505566459PM14")
      end
    end
  end


  describe Celltrust::SoapClient do
    subject(:soap_client) { Celltrust::SoapClient.new(username, password, nickname) }

    let(:username) { 'username' }
    let(:password) { 'password' }
    let(:nickname) { 'nickname' }

    # let(:input) { 'something.' }
    # let(:output) { subject.process(input) }

    it 'internal client should be Savon::Client' do
      expect(soap_client.client.class).to eq Savon::Client
    end

    it 'should have operations' do
      operations = [:send_message,:send_sms,:send_email,:schedule_message,:send_wap_push_message,:send_message_as_template,:schedule_message_as_template]
      expect(soap_client.client.operations).not_to be_empty
      expect(soap_client.client.operations).to match_array(operations)
    end

    it 'should have a nickname defined' do
      expect(soap_client.nickname).not_to be_empty
    end

    it 'shoud send_sms' do

    end

    it 'shoud fail with Security Violation when send_sms' do
      expect{soap_client.send_sms('123', 'abc')}.to raise_error
    end
  end


end
