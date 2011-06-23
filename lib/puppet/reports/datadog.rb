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
  ENV['DATADOG_HOST'] = 'https://app.datadoghq.com/'

  desc <<-DESC
  Send notification of metrics to DataDog
  DESC

  def process
    Puppet.debug "Sending metrics for #{self.host} to DataDog"
    self.metrics.each { |metric,data|
      data.values.each { |val|
        name = "Puppet #{val[1]} #{metric}"
        value = val[2]
        dog = Dogapi::Client.new(API_KEY, 'https://app.datadoghq.com/')
        dog.emit_point("#{name}", value, :host => "#{self.host}")
      }
    }
  end
end
