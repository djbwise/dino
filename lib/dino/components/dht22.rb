module Dino
  module Components
    class DHT22 < BaseComponent
      def after_initialize(options={})    	
        @data_callbacks = []
        @board.add_dht22_hardware(self)
        @board.start_read
      end

      def when_data_received(callback)
        @data_callbacks << callback
      end

      def update(data)
        @data_callbacks.each do |callback|
          callback.call(data) #convert back to decimal.
        end
      end
    end
  end
end
