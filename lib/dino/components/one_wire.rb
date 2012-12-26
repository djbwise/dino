module Dino
  module Components
    class OneWire < BaseComponent
      def after_initialize(options={})    	
        @data_callbacks = []
        @board.add_one_wire_hardware(self)
        @board.start_read
      end

      def when_data_received(callback)
        @data_callbacks << callback
      end

      def update(data)
        @data_callbacks.each do |callback|
          callback.call(data.to_f/100) #convert back to decimal.
        end
      end
    end
  end
end
