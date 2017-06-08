class Class
  def load_for_delayed_job(arg)
    self
  end
  
  def dump_for_delayed_job
    name
  end
end

module Delayed
  class PerformableMethod
    STRING_FORMAT = /^LOAD\;([A-Z][\w\:]+)(?:\;(\w+))?$/
    
    class LoadError < StandardError
    end

    attr_accessor :object, :method_name, :args

    def initialize(object, method_name, args)
      raise NoMethodError, "undefined method `#{method_name}' for #{object.inspect}" unless object.respond_to?(method_name, true)

      if object.respond_to?(:persisted?) && !object.persisted?
        raise(ArgumentError, "job cannot be created for non-persisted record: #{object.inspect}")
      end

      self.object       = object
      self.args         = args
      self.method_name  = method_name.to_sym
    end
    
    def display_name
      if STRING_FORMAT === object
        "#{$1}#{$2 ? '#' : '.'}#{method_name}"
      else
        "#{object.class}##{method_name}"
      end
    end
    
    def perform
      load(object).send(method_name, *args.map{|a| load(a)})
    rescue PerformableMethod::LoadError
      # We cannot do anything about objects that can't be loaded
      true
    end

    private

    def load(obj)
      if STRING_FORMAT === obj
        $1.constantize.load_for_delayed_job($2)
      else
        obj
      end
    rescue => e
      Delayed::Worker.logger.warn "Could not load object for job: #{e.message}"
      raise PerformableMethod::LoadError
    end

    def dump(obj)
      if obj.respond_to?(:dump_for_delayed_job)
        "LOAD;#{obj.dump_for_delayed_job}"
      else
        obj
      end
    end
  end
end

