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

      def after_bump
        send_message('knife spork bump', "#{organization}#{current_user} bumped from #{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join(" ")}")
      end

      def after_upload
        send_message('knife spork upload', "#{organization}#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}")
      end

      def after_promote_remote
        send_message('knife spork promote remote', "#{organization}#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environments.collect{ |e| "#{e.name}" }.join(", ")}")
      end

      def after_environmentfromfile
        send_message('knife spork environment from file', "#{organization}#{current_user} uploaded environment #{object_name}")
      end

      def after_environmentedit
        send_message('knife spork environment edit', "#{organization}#{current_user} edited environment #{object_name}")
      end

      def after_environmentcreate
        send_message('knife spork environment create', "#{organization}#{current_user} created environment #{object_name}")
      end

      def after_environmentdelete
        send_message('knife spork environment delete', "#{organization}#{current_user} deleted environment #{object_name}")
      end

      def after_rolefromfile
        send_message('knife spork role from file', "#{organization}#{current_user} uploaded role #{object_name}")
      end

      def after_roleedit
        send_message('knife spork role edit', "#{organization}#{current_user} edited role #{object_name}")
      end

      def after_rolecreate
        send_message('knife spork role create', "#{organization}#{current_user} created role #{object_name}")
      end

      def after_roledelete
        send_message('knife spork role delete', "#{organization}#{current_user} deleted role #{object_name}")
      end

      def after_databagedit
        send_message('knife spork data bag edit', "#{organization}#{current_user} edited data bag item #{object_name}:#{object_secondary_name}")
      end

      def after_databagcreate
        send_message('knife spork data bag create', "#{organization}#{current_user} created data bag #{object_name}")
      end

      def after_databagdelete
        send_message('knife spork data bag delete', "#{organization}#{current_user} deleted data bag #{object_name}")
      end

      def after_databagitemdelete
        send_message('knife spork data bag item delete', "#{organization}#{current_user} deleted data bag item #{object_name}:#{object_secondary_name}")
      end

      def after_databagfromfile
        send_message('knife spork data bag from file', "#{organization}#{current_user} uploaded data bag item #{object_name}:#{object_secondary_name}")
      end

      def after_nodeedit
        send_message('knife spork node edit', "#{organization}#{current_user} edited node #{object_name}")
      end

      def after_nodedelete
        send_message('knife spork node delete', "#{organization}#{current_user} deleted node #{object_name}")
      end

      def after_nodecreate
        send_message('knife spork node create', "#{organization}#{current_user} created node #{object_name}")
      end

      def after_nodefromfile
        send_message('knife spork node from file', "#{organization}#{current_user} uploaded node #{object_name}")
      end

      def after_noderunlistadd
        send_message('knife spork node runlist add', "#{organization}#{current_user} added run_list items to #{object_name}: #{object_secondary_name}")
      end

      def after_noderunlistremove
        send_message('knife spork node runlist remove', "#{organization}#{current_user} removed run_list items from #{object_name}: #{object_secondary_name}")
      end

      def after_noderunlistset
        send_message('knife spork node runlist set', "#{organization}#{current_user} set the run_list for #{object_name} to #{object_secondary_name}")
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
