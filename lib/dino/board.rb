module Dino
  class Board
    attr_reader :digital_hardware, :analog_hardware, :one_wire_hardware, :dht22_hardware
    LOW, HIGH = 000, 255

    def initialize(io)
      @io, @digital_hardware, @analog_hardware, @one_wire_hardware, @dht22_hardware = io, [], [], [],[]
      io.add_observer(self)
      send_clearing_bytes
      start_heart_beat
      start_one_wire
      start_dht22
    end

    def update(pin, msg)
      (@digital_hardware + @analog_hardware + @one_wire_hardware + @dht22_hardware).each do |part|
        part.update(msg) if normalize_pin(pin) == normalize_pin(part.pin)
      end
    end

    def add_digital_hardware(part)
      set_pin_mode(part.pin, :in)
      @digital_hardware << part
    end

    def remove_digital_hardware(part)
      @digital_hardware.delete(part)
    end

    def add_analog_hardware(part)
      set_pin_mode(part.pin, :in)
      @analog_hardware << part
    end

    def remove_analog_hardware(part)
      @analog_hardware.delete(part)
    end

    def add_one_wire_hardware(part)
      set_pin_mode(part.pin, :in)
      @one_wire_hardware << part
    end

    def remove_one_wire_hardware(part)
      @one_wire_hardware.delete(part)
    end

    def add_dht22_hardware(part)
      set_pin_mode(part.pin, :in)
      @dht22_hardware << part
    end

    def remove_dht22_hardware(part)
      @dht22_hardware.delete(part)
    end

    def start_read
      @io.read
    end

    def stop_read
      @io.close_read
    end

    def write(msg, opts = {})
      formatted_msg = opts.delete(:no_wrap) ? msg : "!#{msg}."
      @io.write(formatted_msg)
    end

    def digital_write(pin, value)
      pin, value = normalize_pin(pin), normalize_value(value)
      write("01#{pin}#{value}")
    end

    def digital_read(pin)
      pin, value = normalize_pin(pin), normalize_value(0)
      write("02#{pin}#{value}")
    end

    def analog_write(pin, value)
      pin, value = normalize_pin(pin), normalize_value(value)
      write("03#{pin}#{value}")
    end

    def analog_read(pin)
      pin, value = normalize_pin(pin), normalize_value(0)
      write("04#{pin}#{value}")
    end

    def set_pin_mode(pin, mode)
      pin, value = normalize_pin(pin), normalize_value(mode == :out ? 1 : 0)
      write("00#{pin}#{value}")
    end

    def set_debug(on_off)
      pin, value = normalize_pin(0), normalize_value(on_off == :on ? 1 : 0)
      write("99#{pin}#{value}")
    end

    def normalize_pin(pin)
      raise Exception.new('pins can only be two digits') if pin.to_s.length > 2
      normalize(pin, 2)
    end

    def normalize_value(value)
      raise Exception.new('values are limited to three digits') if value.to_s.length > 3
      normalize(value, 3)
    end

    private

    def start_heart_beat
      @heart_beat ||= Thread.new do
        loop do
          sleep 1
          @digital_hardware.each do |part|
            digital_read(part.pin)
          end
          @analog_hardware.each do |part|
            analog_read(part.pin)
          end
        end
      end
    end

    def start_one_wire
      @one_wire ||= Thread.new do
        loop do     
          @one_wire_hardware.each do |part|
            pin = normalize_pin(part.pin)
            write("96#{pin}001") #read one_wire
          end
          sleep 2
        end
      end
    end
    def start_dht22
      @dht22 ||= Thread.new do
        loop do     
          @dht22_hardware.each do |part|
            pin = normalize_pin(part.pin)
            write("95#{pin}001") #read dht22
          end
          sleep 5
        end
      end
    end

    def normalize(pin, spaces)
      pin.to_s.rjust(spaces, '0')
    end

    def send_clearing_bytes
      write('00000000', no_wrap: true)
    end
  end
end