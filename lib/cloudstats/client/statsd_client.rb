require 'statsd-ruby'
require_relative './report_client'

module CloudStats
  class StatsdClient < ReportClient
    def initialize
      @host = Statsd.new(
        PublicConfig['statsd_host'] || 'data1.cloudstats.me',
        PublicConfig['statsd_port'] || 8125,
        (PublicConfig['statsd_protocol'] || 'udp').to_sym
      )
    end

    def send(payload)
      [
        :services, :ps, :remote_calls_enabled, :agent_version, :os, :uptime,
        :kernel, :release, :hostname, :vms, :disk_smart, :disks, :interfaces
      ].each do |el|
        payload[:server].delete(el)
      end

      payload[:server][:processes][0..9].each do |k|
        @host.gauge "process_cpu.#{AgentApi.server_id}.#{k[:command]}", k[:cpu]
        @host.gauge "process_mem.#{AgentApi.server_id}.#{k[:command]}", k[:mem]
      end
      payload[:server].delete(:processes)

      # payload[:server][:disks].each do |k, used, available|
      #   @host.gauge "#{k}_used.#{server_key}.#{PublicConfig['key']}", used
      #   @host.gauge "#{k}_available.#{server_key}.#{PublicConfig['key']}", available
      # end
      #
      # payload[:server].delete(:disks)

      # payload[:server][:interfaces].each do |k, rx, tx|
      #   @host.gauge "#{k}_rx.#{server_key}.#{PublicConfig['key']}", rx
      #   @host.gauge "#{k}_tx.#{server_key}.#{PublicConfig['key']}", tx
      # end
      #
      # payload[:server].delete(:interfaces)

      payload[:server].each do |k, v|
        # puts "#{server_key}_#{k} #{v}\n"
        @host.gauge "#{k}.#{AgentApi.server_id}", v
      end
    end

    { ok: true }
  end
end
