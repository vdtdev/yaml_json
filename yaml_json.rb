require 'YAML'
require 'Json'

##
# Command-line conversion from JSON to YAML and back
#
# Released under MIT license
# http://github.com/vdtdev
#
# @author Wade H. <vdtdev@gmail.com>
module YamlJson
    ##
    # Processes arguments and executes conversion
    class Runner
        EXPECTED_SWITCHES = {
            convert: [:in, :out, :from],
            help: [:help]
        }

        @options = {}
        @base_arguments = []
        def initialize(arguments = [])
            @base_arguments = arguments
            parse_options
            validate_switches
        end

        def get_switch(switch)
            @options.fetch(switch.to_sym, nil)
        end

        private

        def parse_options
            @options = {}
            args = @base_arguments.join(" ").split("--").select{|a| a!=""}.compact
            args.each do |arg|
                parts = arg.split(":").map{|p| p.strip()}
                @options[parts[0].to_sym] = parts[1]
            end
        end

        def validate_switches
            convert = @options.keys
                .select { |k| EXPECTED_SWITCHES[:convert].include?(k)}
                .select { |k| k }.length == EXPECTED_SWITCHES[:convert].length
            help = @options.keys.include?(EXPECTED_SWITCHES[:help])

            if convert && !help
                do_conversion
            else
                do_help
            end

        end

        def do_help
            puts "Switch format: " + ctext("--switch", 32,1) + ": value"
            puts "Expected switches: #{ctext('--from',32,1)}: " +
                " (yaml|json) #{ctext('--in',32,1)}: file #{ctext('--out',32,1)}: file"
        end

        def do_conversion
            from = :json if (get_switch(:from) == "json")
            from = :yaml if (get_switch(:from) == "yaml")
            files = {
                in: get_switch(:in),
                out: get_switch(:out)
            }
            Converter.convert(files, from)
        end

        def ctext(text, c, m=0, reset_c = 37, reset_m = 0)
            return "\033[#{c};#{m}m#{text}\033[#{reset_c};#{reset_m}m"
        end

    end
    ##
    # Module with conversion methods
    module Converter

        JSON_FORMAT = {
            indent: "\t",
            object_nl: "\n",
            array_nl: "\n"
        }

        ##
        # Called by convert with a Proc that handles conversion
        # This method handles opening and reading from src, opening and writing to dest
        def self.process(files, operation)
            File.open(files[:in]) do |i|
                File.open(files[:out], 'w') do |o|
                    o.write(operation.call(i.read()))
                end
            end
        end

        ##
        # Calls process with Proc appropriate for from type
        def self.convert(files, from)
            from_json = Proc.new{ |j| JSON.load(j).to_yaml }
            from_yaml = Proc.new{ |y| JSON.generate(YAML.load(y), JSON_FORMAT) }
            case from
                when :json
                    puts "Converting JSON #{files[:in]} to YAML #{files[:out]}"
                    process(files, from_json)
                when :yaml
                    puts "Converting YAML #{files[:in]} to JSON #{files[:out]}"
                    process(files, from_yaml)
            end
        end

    end
end

# Run program
YamlJson::Runner.new(ARGV)
# puts("hi")