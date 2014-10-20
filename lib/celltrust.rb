require "celltrust/version"
require 'savon'

# Celtrust module
module Celltrust

    # Base for HTTP clients
    module BaseSMSClient

        SECURE_URL = 'https://gateway.celltrust.net/TxTNotify/SecureSMS'
        STANDARD_URL = 'https://gateway.celltrust.net/TxTNotify/TxTNotify'

        attr_accessor :nickname, :client, :path

        def build_client(service_url)
            url = URI.parse(service_url)
            @path = url.path
            @client = Net::HTTP.new(url.host, Net::HTTP.https_default_port)
            @client.use_ssl = true
            @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        def send_sms!(destination, message, params = {})
            response = send_sms(destination, message, params)

            if response.ok?
                unless response.error?
                    response.message_id
                else
                    raise Error, "#{response.error_details} (error_code=#{response.error_details['error_code']})"
                end
            else
                raise Error, "Unexpected HTTP response (code=#{response.code})"
            end
        end

        private

        def get(params = {})
            http_response = @client.get(request_uri(add_auth_params(params)))
            decode(http_response)
        end

        def post(params)
            puts request_uri(add_auth_params(params))
            http_response = @client.post(request_uri(add_auth_params(params)), '')
            decode(http_response)
        end

        def decode(http_response)
            response = Response.new(http_response)
        end

        def request_uri(hash = {})
            if hash.empty?
                @path
            else
                query_params = hash.map do |key, values|
                    Array(values).map { |value| "#{escape(key)}=#{escape(value)}" }
                end

                @path + '?' + query_params.flatten.join('&')
            end
        end

        def escape(component)
            CGI.escape(component.to_s)
        end

    end

    # Simple SMSClient
    # Sends standard Sms
    #  Syntax
    #   https://gateway.celltrust.net/TxTNotify/TxTNotify?
    #       <PhoneDestination=[Phone #]&
    #       carrierId=[carrierID]&
    #       Username=[username]&
    #       Password=[password]&
    #       Message=[message]&
    #       Nickname=[nickname]>
    #       { TemplateName=[template name]&
    #       Subject=[subject]&
    #       EmailDestination=[email address]&
    #       WapPushURL=[url]&
    #       AdminEmail=[email address]&
    #       DestPort=[port number]&
    #       XMLResponse=[true|false]&
    #       Shortcode=[shortcode]&
    #       PricePoint =[amount]&
    #       DoubleOptin =[true|false]&
    #       redirectURL=[url]}
    class SimpleSMSClient
        include BaseSMSClient

        def initialize(username = ENV['CELLTRUST_USERNAME'], password = ENV['CELLTRUST_PASSWORD'], nickname = ENV['CELLTRUST_NICKNAME'])
            @username, @password = username, password
            @nickname = nickname || username
            build_client(BaseSMSClient::STANDARD_URL)
        end

        def send_sms(destination, message, params = {})
            post(params.merge(:PhoneDestination => destination, :Message => message))
        end

        def add_auth_params(params = {})
            params.merge(:Username => @username, :Password => @password, :Nickname => @nickname, :XMLResponse => true)
        end
    end

    # SecureSMS API

    # http://gateway.celltrust.net/TxTNotify/SecureSMS?
    #       <SMSDestination=[Phone #]&
    #       Username=[username]&
    #       Password=[password]&
    #       CustomerNickname=[nickname]&
    #       CarrierId =[carrier ID]&
    #       Message=[message]>
    #       { AllowInsecure=[true|false]&
    #       DeliveryAck=[true|false]&
    #       ReadAck=[true|false]&
    #       Shortcode=[shortcode]}>
    class SecureSMSClient
        include BaseSMSClient

        def initialize(username = ENV['CELLTRUST_USERNAME'], password = ENV['CELLTRUST_PASSWORD'], nickname = ENV['CELLTRUST_NICKNAME'])
            @username, @password = username, password
            @nickname = nickname || username
            build_client(BaseSMSClient::SECURE_URL)
        end

        def send_sms(destination, message, params = {})
            post(params.merge(:SMSDestination => destination, :Message => message))
        end

        def add_auth_params(params = {})
            params.merge(:Username => @username, :Password => @password, :CustomerNickname => @nickname, :XMLResponse => true)
        end
    end


    # API
    # Success Response Example
    # <?xml version=\"1.0\"?>
    # <TxTNotifyResponse>
    #     <MsgResponseList>
    #         <MsgResponse type='SMS'>
    #         <Status>ACCEPTED</Status>
    #         <MessageId>BAXF1413829823019-904538</MessageId>
    #         </MsgResponse>
    #     </MsgResponseList>
    # </TxTNotifyResponse>

    # Real world
    # <?xml version=\"1.0\" ?>
    # <SecureSMSResponse><Error><ErrorCode>206</ErrorCode>
    # <ErrorString>Username is not valid.</ErrorString></Error>
    # </SecureSMSResponse>
    class Response
        def initialize(http_response, options = {})
            @http_response = http_response
        end

        def respond_to_missing?(name, include_private = false)
            @http_response.respond_to?(name)
        end

        def method_missing(name, *args, &block)
            @http_response.send(name, *args, &block)
        end

        def ok?
            code.to_i == 200
        end

        def message_id
            if /<MessageId>(.+?)<\/MessageId>/ =~ @http_response.body
                sms_id = Regexp.last_match(1)
                sms_id
            end
        end

        def status
            if /<Status>(.+?)<\/Status>/ =~ @http_response.body
                status = Regexp.last_match(1)
                status
            end
        end

        def error?
            @http_response.body.include?("<Error>")
        end

        def error_details
            details = {}
            if /<ErrorCode>(.+?)<\/ErrorCode>/ =~ @http_response.body
                error_code = Regexp.last_match(1)
                details["error_code"] = error_code
            end
            #api says its ErrorMessage
            if /<ErrorString>(.+?)<\/ErrorString>/ =~ @http_response.body
                error_message = Regexp.last_match(1)
                details["error_message"] = error_message
            end
            details
        end

    end

    class Error < StandardError
    end


    #  Basic SOAP client for the TxtMessageService.
    #  Not finished.
    class SoapClient

        WSDL_FILE = File.join(File.dirname(__FILE__),"wsdl/TxtMessageService.wsdl")

        attr_accessor :nickname, :client

        def initialize(username = ENV['CELLTRUST_USERNAME'], password = ENV['CELLTRUST_PASSWORD'], nickname = ENV['CELLTRUST_NICKNAME'])
            @username, @password = username, password
            @nickname = nickname || username
            @client = Savon.client(wsdl: WSDL_FILE, soap_header: { "Username" => username, "Password" => password })
        end

        # String nickname, String subject, String message,
        # Recipient[] recipients, String adminEmail, ExtraParams params
        def send_message(subject, message, recipients, adminEmail, params)
            # execute_operation(:send_message, { nickname: nickname, subject: subject, recipients: recipients, message: message, adminEmail: adminEmail params: params })
            raise RuntimeError, 'Not implemented'
        end

        #  String nickname, String destination, String message, ExtraParams params
        def send_sms(destination, message, params = {})
            execute_operation(:send_sms, { destination: destination, message: message, params: params } )
        end

        def execute_operation(opration_name, message)
            begin
                message[:nickname] = @nickname
                client.call(opration_name, message: message.compact )
            rescue Savon::SOAPFault => error
                fault_code = error.to_hash[:fault][:faultcode]
                raise Error, fault_code
            end
        end

    end



end

class Hash
    def compact
        delete_if { |k, v| v.nil? }
    end
end
