package hxFirmata;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

import hxSerial.Serial;

class Arduino {
    /**
     * Constant to set a pin to input mode (in a call to pinMode()).
     */
    public static inline var INPUT : Int = 0;
    /**
     * Constant to set a pin to output mode (in a call to pinMode()).
     */
    public static inline var OUTPUT : Int = 1;
    /**
     * Constant to set a pin to analog mode (in a call to pinMode()).
     */
    public static inline var ANALOG : Int = 2;
    /**
     * Constant to set a pin to PWM mode (in a call to pinMode()).
     */
    public static inline var PWM : Int = 3;
    /**
     * Constant to set a pin to servo mode (in a call to pinMode()).
     */
    public static inline var SERVO : Int = 4;
    /**
     * Constant to set a pin to shiftIn/shiftOut mode (in a call to pinMode()).
     */
    public static inline var SHIFT : Int = 5;
    /**
     * Constant to set a pin to I2C mode (in a call to pinMode()).
     */
    public static inline var I2C : Int = 6;

    /**
     * Constant to write a high value (+5 volts) to a pin (in a call to
     * digitalWrite()).
     */
    public static inline var LOW : Int = 0;
    /**
     * Constant to write a low value (0 volts) to a pin (in a call to
     * digitalWrite()).
     */
    public static inline var HIGH : Int = 1;

    public static function list() : Array<String> {
        return Serial.getDeviceList();
    }

    var serial : Serial;
    var firmata : Firmata;
    var thread : Thread;

    public function new(iname : String, irate : Int = 57600) {
        firmata = new Firmata(write);
        serial = new Serial(iname, irate, true);

        try {
            Sys.sleep(3); // let bootloader timeout
        } catch(e : Dynamic) { }
        firmata.init();

        thread = Thread.create(processInput);
    }

    function write(val : Int) : Void {
        serial.writeByte(val);
    }

    function processInput() : Void {
        while(true) {
            while(serial.available() > 0) {
                firmata.processInput(serial.readByte());
            }
        }
    }

    public function dispose() : Void {
        serial.close();
    }

    /**
     * Returns the last known value read from the digital pin: HIGH or LOW.
     *
     * @param pin the digital pin whose value should be returned (from 2 to 13,
     * since pins 0 and 1 are used for serial communication)
     */
    public function digitalRead(pin : Int) : Int {
        return firmata.digitalRead(pin);
    }
    
    /**
     * Returns the last known value read from the analog pin: 0 (0 volts) to
     * 1023 (5 volts).
     *
     * @param pin the analog pin whose value should be returned (from 0 to 5)
     */
    public function analogRead(pin : Int) : Int {
        return firmata.analogRead(pin);
    }
    
    /**
     * Set a digital pin to input or output mode.
     *
     * @param pin the pin whose mode to set (from 2 to 13)
     * @param mode either Arduino.INPUT or Arduino.OUTPUT
     */
    public function pinMode(pin : Int, mode : Int) : Void {
        try {
            firmata.pinMode(pin, mode);
        } catch (e : Dynamic) {
            throw "Error inside Arduino.pinMode()";
        }
    }
    
    /**
     * Write to a digital pin (the pin must have been put into output mode with
     * pinMode()).
     *
     * @param pin the pin to write to (from 2 to 13)
     * @param value the value to write: Arduino.LOW (0 volts) or Arduino.HIGH
     * (5 volts)
     */
    public function digitalWrite(pin : Int, value : Int) : Void {
        try {
            firmata.digitalWrite(pin, value);
        } catch (e : Dynamic) {
            throw "Error inside Arduino.digitalWrite()";
        }
    }
    
    /**
     * Write an analog value (PWM-wave) to a digital pin.
     *
     * @param pin the pin to write to (must be 9, 10, or 11, as those are they
     * only ones which support hardware pwm)
     * @param value the value: 0 being the lowest (always off), and 255 the highest
     * (always on)
     */
    public function analogWrite(pin : Int, value : Int) : Void {
        try {
            firmata.analogWrite(pin, value);
        } catch (e : Dynamic) {
            throw "Error inside Arduino.analogWrite()";
        }
    }
    
    /**
     * Write a value to a servo pin.
     *
     * @param pin the pin the servo is attached to
     * @param value the value: 0 being the lowest angle, and 180 the highest angle
     */
    public function servoWrite(pin : Int, value : Int) : Void {
        try {
            firmata.servoWrite(pin, value);
        } catch (e : Dynamic) {
            throw "Error inside Arduino.servoWrite()";
        }
    }
}