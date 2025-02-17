# frozen_string_literal: true

module Goldiloader
  module CustomPreloads
    def initialize
      super
      @custom_preloads = nil
    end

    def preloaded(model, cache_name:, key:, &block)
      unless preloaded?(cache_name)
        ids = models.map do |record|
          record.public_send(key)
        end

        # We're using instance_exec instead of a simple yield to make sure that the
        # given block does not have any references to the model instance as this might
        # lead to unexpected results. The block will be executed in the context of the
        # class of the model instead.
        block_context = models.first.class
        preloaded_hash = block_context.instance_exec(ids, &block)
        store_preloaded(cache_name, preloaded_hash)
      end
      fetch_preloaded(cache_name, model, key: key)
    end

    private

    def store_preloaded(cache_name, preloaded_hash)
      @custom_preloads ||= {}
      @custom_preloads[cache_name] = preloaded_hash
    end

    def fetch_preloaded(cache_name, instance, key:)
      @custom_preloads&.dig(cache_name, instance.public_send(key))
    end

    def preloaded?(cache_name)
      @custom_preloads&.key?(cache_name)
    end
  end
end
