require 'rufus/scheduler'

module CloudStats
  class Scheduler
    attr_reader :publisher, :scheduler

    def initialize
      @publisher = Publisher.new
      @scheduler = create_scheduler
    end

    def create_scheduler
      scheduler = Rufus::Scheduler.new
      def scheduler.on_error(job, error)
        $logger.error "#{error.class.name}: #{error.message}"
        Airbrake.catch(error, job_id: job.id)
      end
      scheduler
    end

    def schedule
      $logger.info "Scheduling reports every 1m"
      scheduler.every '1m' do
        publisher.publish
      end

      $logger.info "Scheduling updates every #{update_rate}"
      scheduler.every update_rate do
        catch_and_log_socket_error(Updater.STORAGE_SERVICE) { Updater.new.update }
      end

      $logger.info "Scheduling backups"
      scheduler.cron '0 0 * * *' do
        CloudStats::Backup.instance.perform
      end
      scheduler.join
    end

    private

    def update_rate
      PublicConfig['repo'] == 'agent007' ? '1m' : '5h'
    end
  end
end
