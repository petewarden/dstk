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

      default_options[:api_base] = ENV['DSTK_API_BASE'] if ENV['DSTK_API_BASE']

      default_options.each do |key, value|
        options[key] = value if !options.has_key?(key)
      end

      @dstk_api_base = options[:api_base]

      self.check_version() if options[:check_version]
    end

    ############### UTILITIES ###################
    # a short-hand method to URL encode a string. See http://web.elctech.com/?p=58
    def u(str)
      str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
    end

    # build the api url
    def api_url(endpoint)
      api_url = @dstk_api_base + endpoint
    end

    # convert payload to json if type json
    def prep_payload(data_payload, data_payload_type)
      data_payload_type == 'json' ? data_payload.to_json : data_payload
    end

    # item should be an array. if it's not, make it one
    def ensure_array(item)
      item.is_a?(Array) ? item : [item]
    end
    ############### end UTILITIES ###############

    def dstk_api_call(endpoint, arguments = {}, data_payload = nil, data_payload_type = 'json')
      response = if data_payload
                   HTTParty.post(api_url(endpoint),
                                 { :body => prep_payload(data_payload, data_payload_type),
                                   :query => arguments })
                 else
                   HTTParty.get(api_url(endpoint), query: arguments)
                 end

      unless response.body && response.code == 200
        raise "DSTK::dstk_api_call('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{response.request.uri.to_s}' failed with code #{response.code} : '#{response.message}'"
      end

      begin
        result = JSON.parse(response.body)
        !result.is_a?(Array) && result['error'] ? raise(result['error']) : result
      rescue JSON::ParseError => e
        raise "DSTK::dstk_api_call('#{endpoint}', #{arguments.to_json}, '#{data_payload}', '#{data_payload_type}') call to '#{response.request.uri.to_s}' failed to parse response '#{response.body}' as JSON - #{e.message}"
      end
    end

    def check_version
      required_version = 50
      response = dstk_api_call('/info')
      actual_version = response['version']
      if actual_version < required_version
        raise "DSTK: Version #{actual_version.to_s} found but #{required_version.to_s} is required"
      end
    end

    def geocode(address)
      dstk_api_call('/maps/api/geocode/json', { 'address' => address })
    end

    def ip2coordinates(ips)
      dstk_api_call('/ip2coordinates', {}, ensure_array(ips), 'json')
    end

    def street2coordinates(addresses)
      dstk_api_call('/street2coordinates', {}, ensure_array(addresses), 'json')
    end

    def coordinates2politics(coordinates)
      dstk_api_call('/coordinates2politics', {}, coordinates, 'json')
    end

    def text2places(text)
      dstk_api_call('/text2places', {}, text, 'string')
    end

    def file2text(inputfile)
      dstk_api_call('/file2text', {}, {:inputfile => inputfile}, 'file')
    end

    def text2sentences(text)
      dstk_api_call('/text2sentences', {}, text, 'string')
    end

    def html2text(html)
      dstk_api_call('/html2text', {}, html, 'string')
    end

    def html2story(html)
      dstk_api_call('/html2story', {}, html, 'string')
    end

    def text2people(text)
      dstk_api_call('/text2people', {}, text, 'string')
    end

    def text2times(text)
      dstk_api_call('/text2times', {}, text, 'string')
    end

    def text2sentiment(text)
      dstk_api_call('/text2sentiment', {}, text, 'string')
    end

    def coordinates2statistics(coordinates, statistics = nil)
      if statistics
        if !statistics.is_a?(Array) then statistics = [statistics] end
        arguments = { 'statistics' => statistics.join(',') }
      else
        arguments = {}
      end

      dstk_api_call('/coordinates2statistics', arguments, coordinates, 'json')
    end

    def twofishes(text)
      dstk_api_call('/twofishes', { 'query' => text })
    end

  end
end
