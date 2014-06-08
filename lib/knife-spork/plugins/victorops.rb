require 'knife-spork/plugins/plugin'
require 'json'
require 'uri'

module KnifeSpork
  module Plugins
    class Victorops < Plugin
      name :victorops

      def perform; end

      def after_check
        cookbooks.each do |cookbook|
          send_message('knife spork check', "#{organization}#{current_user} checked #{cookbook.name}")
        end
      end

      private

      def send_message(entity, message)
        event_data = {
          :message_type => 'INFO',
          :monitoring_tool => 'knife',
          :entity_id => entity,
          :state_message => message
        }
        send_2_victor(event_data.to_json)
      end

      def send_2_victor(event_data)
        begin
          uri = URI.parse(config.url)
        rescue Exception => e
          ui.error 'Could not parse URI for VictorOps.'
          ui.error e.to_s
          return
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = config.read_timeout || 5
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
        request.body = event_data

        begin
          response = http.request(request)
          ui.error "VictorOps API returned bad response at #{config.url}." if response.code != '200'
        rescue Timeout::Error
          ui.error "VictorOps API timed out connecting to #{config.url}. Is that URL accessible?"
        rescue Exception => e
          ui.error 'VictorOps API error.'
          ui.error e.to_s
        end
      end
    end
  end
end
