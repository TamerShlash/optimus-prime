module OptimusPrime
  module Modules
    class ModuleLoader
      MODULES = [:persistence, :exceptional]
      attr_reader :persistence, :exceptional, :subscribers
      
      def initialize(pipeline, modules)
        @pipeline = pipeline
        @subscribers = []
        @modules = modules
        register_modules
      end
      
      private
      
      def register_modules
        MODULES.each do |mod|
          send("register_#{mod}")
        end
      end
      
      def register_persistence
        return unless @modules[:persistence]
        raise 'Pipeline name required for persistence' unless @pipeline.name
        @persistence = Persistence.new(@modules[:persistence]['options'])
        @subscribers << @persistence
      end
      
      def register_exceptional
        return unless @modules[:exceptional]
        adapter_name = "Modules::Exceptional::Adapters::#{errors_config['adapter'].capitalize}Adapter"
        @exceptional = if Object.const_defined?(adapter_name)
          adapter_name.constantize.new(@modules[:exceptional]['options'])
        end
      end
    end
  end
end
