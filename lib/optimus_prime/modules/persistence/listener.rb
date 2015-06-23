module OptimusPrime
  module Modules
    module Persistence
      class Listener
        attr_reader :options, :db

        def initialize(dsn:)
          @db = Sequel.connect(dsn)
          run_migrations
          @pipeline_name = nil
          @operation_id = nil
          @jobs = {}
        end

        def run_migrations
          Sequel::Migrator.run(@db, "migrations")
        end

        def operation
          @operation ||= Operation.new(@db)
        end

        def load_job
          @load_job ||= LoadJob.new(@db)
        end

        def pipeline_started(pipeline)
          @pipeline_name = pipeline.name
          @operation_id = operation.create pipeline_id: pipeline.name.to_s,
                                           start_time: Time.now,
                                           status: 'started'
        end

        def pipeline_finished(pipeline)
          operation.update id: @operation_id,
                           end_time: Time.now,
                           status: 'finished'
        end

        def pipeline_failed(pipeline, error)
          operation.update id: @operation_id,
                           end_time: Time.now,
                           status: 'failed',
                           error: error
        end

        def load_job_started(job)
          @jobs[job.uris.first] = load_job.create identifier: job.uris.first,
                                                  job_id: job.job_id,
                                                  operation_id: @operation_id,
                                                  uris: job.uris.join(','),
                                                  category: job.id,
                                                  status: 'started',
                                                  start_time: Time.now
        end

        def load_job_finished(job)
          load_job.update id: @jobs[job.uris.first],
                          status: 'finished',
                          end_time: Time.now
        end

        def load_job_failed(job, error)
          load_job.update id: @jobs[job.uris.first],
                          status: 'failed',
                          end_time: Time.now
        end

      end
    end
  end
end
