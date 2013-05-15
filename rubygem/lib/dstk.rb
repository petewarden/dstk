# Client interface to the Data Science Toolkit API
# See http://www.datasciencetoolkit.org/developerdocs for details
# By Pete Warden, pete@petewarden.com

require 'rubygems' if RUBY_VERSION < '1.9'

require 'json'
require 'httparty'
require 'httmultiparty'

module DSTK
  class DSTK
    def initialize(options = {})
      default_options = {
        :api_base => 'http://www.datasciencetoolkit.org',
        :check_version => true,
      }

      if ENV['DSTK_API_BASE']
        default_options[:api_base] = ENV['DSTK_API_BASE']
      end

      default_options.each do |key, value|
        if !options.has_key?(key)
          options[key] = value
        end
      end
          
      @api_base = options[:api_base]

      if options[:check_version]:
        self.check_version()
      end
    end

    # A short-hand method to URL encode a string. See http://web.elctech.com/?p=58
    def u(str)
      str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
    end

    def json_api_call(endpoint, arguments = {}, data_payload = nil, data_payload_type = 'json')

      api_url = @api_base + endpoint
      arguments_list = arguments.map do |name, value|
        name + '=' + u(value)
      end
      if arguments_list.length > 0
        arguments_string = '?' + arguments_list.join('&')
        api_url += arguments_string
      end
      response = nil
      if !data_payload
        response = HTTParty.get(api_url)
      else
        if data_payload_type == 'json'
          data_payload_value = data_payload.to_json
        else
          data_payload_value = data_payload
        end
        response = HTTParty.post(api_url, { :body => data_payload_value })
      end

      if !response.body or response.code != 200
        raise "DSTK::json_api_call('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{api_url}' failed with code #{response.code} : '#{response.message}'"
      end

      json_string = response.body
      result = nil
      begin
        result = JSON.parse(json_string)
      rescue JSON::ParseError => e
        raise "DSTK::json_api_call('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{api_url}' failed to parse response '#{json_string}' as JSON - #{e.message}"
      end
      if !result.is_a?(Array) and result['error']
        raise result['error']
      end
      result
    end

    def check_version
      required_version = 50
      response = json_api_call('/info')
      actual_version = response['version']
      if actual_version < required_version:
        raise "DSTK: Version #{actual_version.to_s} found but #{required_version.to_s} is required"
      end
    end

    def ip2coordinates(ips)
      if !ips.is_a?(Array) then ips = [ips] end
      response = json_api_call('/ip2coordinates', {}, ips)
      response
    end

    def street2coordinates(addresses)
      if !addresses.is_a?(Array) then addresses = [addresses] end
      response = json_api_call('/street2coordinates', {}, addresses)
      response
    end
      
    def coordinates2politics(coordinates)
      response = json_api_call('/coordinates2politics', {}, coordinates)
      response
    end

    def text2places(text)
      response = json_api_call('/text2places', {}, text, 'string')
      response
    end

    def file2text(inputfile)
      response = json_api_call('/text2places', {}, {:inputfile => inputfile}, 'file')
      response
    end

    def text2sentences(text)
      response = json_api_call('/text2sentences', {}, text, 'string')
      response
    end

    def html2text(html)
      response = json_api_call('/html2text', {}, html, 'string')
      response
    end

    def html2story(html)
      response = json_api_call('/html2story', {}, html, 'string')
      response
    end

    def text2people(text)
      response = json_api_call('/text2people', {}, text, 'string')
      response
    end

    def text2times(text)
      response = json_api_call('/text2times', {}, text, 'string')
      response
    end

    def text2sentiment(text)
      response = json_api_call('/text2sentiment', {}, text, 'string')
      response
    end

    def coordinates2statistics(coordinates, statistics = nil)
      if statistics
        if !statistics.is_a?(Array) then statistics = [statistics] end
        arguments = { 'statistics' => statistics.join(',') }
      else
        arguments = {}
      end
      response = json_api_call('/coordinates2statistics', arguments, coordinates)
      response
    end

  end
end