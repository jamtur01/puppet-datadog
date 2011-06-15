require 'puppet'
require 'yaml'

begin
  require 'dogapi'
rescue LoadError => e
  Puppet.info "You need the `dogapi` gem to use the DataDog report"
end

Puppet::Reports.register_report(:datadog) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "datadog.yaml"])
  raise(Puppet::ParseError, "DataDog report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  API_KEY = config[:datadog_api_key]
  ENV['DATADOG_HOST'] = 'http://app.datadoghq.com/'

  desc <<-DESC
  Send notification of metrics and events to DataDog
  DESC

  def process
    Puppet.debug "Sending status for #{self.host} to DataDog"
    self.metrics.each { |metric,data|
      data.values.each { |val| 
        name = "Puppet #{val[1]} #{metric}"
        if metric == 'time'
          unit = 'Seconds'
        else
          unit = 'Count'
        end
        value = val[2]
        opts = {}
        opts = {:metric_name => name, :namespace => 'Puppet', :value => value, :unit => unit, :dimensions => [{'Name' => 'Hostname', 'Value' => self.host}]}
        @dog = Dogapi::Client.new(API_KEY)
        @dog.emit_point 'some.metric.name', 50.0
      }
    }
  end
end
