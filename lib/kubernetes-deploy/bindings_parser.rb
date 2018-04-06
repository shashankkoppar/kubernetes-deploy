# frozen_string_literal: true
require 'json'
require 'yaml'
require 'csv'

module KubernetesDeploy
  module BindingsParser
    extend self

    def parse(string)
      bindings = parse_file(string) || parse_json(string) || parse_csv(string)

      unless bindings
        raise ArgumentError, "Failed to parse bindings."
      end

      bindings
    end

    private

    def parse_file(string)
      return unless string =~ /\A@/

      begin
        file_path = string.gsub(/\A@/, '')

        case File.extname(file_path)
        when '.json'
          bindings = parse_json(File.read(file_path))
        when '.yaml', '.yml'
          bindings = YAML.load(File.read(file_path))
        else
          raise ArgumentError, "Supplied file does not appear to be JSON or YAML"
        end

        bindings
      rescue Errno::ENOENT
        raise ArgumentError, "Supplied file does not exist: #{string}"
      end
    end

    def parse_json(string)
      bindings = JSON.parse(string)

      unless bindings.is_a?(Hash)
        raise ArgumentError, "Expected JSON data to be a hash."
      end

      bindings
    rescue JSON::ParserError
      nil
    end

    def parse_csv(string)
      lines = CSV.parse(string)
      bindings = {}

      lines.each do |line|
        line.each do |binding|
          key, value = binding.split('=', 2)

          if key.blank?
            raise ArgumentError, "key is blank"
          end

          bindings[key] = value
        end
      end

      bindings
    rescue CSV::MalformedCSVError
      nil
    end
  end
end
