package hxFirmata;

/**
 * Internal class used by the Arduino class to parse the Firmata protocol.
 */
class Firmata {
    /**
     * Constant to set a pin to input mode (in a call to pinMode()).
     */
    public static inline var INPUT : UInt = 0;
    /**
     * Constant to set a pin to output mode (in a call to pinMode()).
     */
    public static inline var OUTPUT : UInt = 1;
    /**
     * Constant to set a pin to analog mode (in a call to pinMode()).
     */
    public static inline var ANALOG : UInt = 2;
    /**
     * Constant to set a pin to PWM mode (in a call to pinMode()).
     */
    public static inline var PWM : UInt = 3;
    /**
     * Constant to set a pin to servo mode (in a call to pinMode()).
     */
    public static inline var SERVO : UInt = 4;
    /**
     * Constant to set a pin to shiftIn/shiftOut mode (in a call to pinMode()).
     */
    public static inline var SHIFT : UInt = 5;
    /**
     * Constant to set a pin to I2C mode (in a call to pinMode()).
     */
    public static inline var I2C : UInt = 6;

    /**
     * Constant to write a high value (+5 volts) to a pin (in a call to
     * digitalWrite()).
     */
    public static inline var LOW : UInt = 0;
    /**
     * Constant to write a low value (0 volts) to a pin (in a call to
     * digitalWrite()).
     */
    public static inline var HIGH : UInt = 1;

    static inline var MAX_DATA_BYTES : UInt = 4096;

    static inline var DIGITAL_MESSAGE         : UInt = 0x90; // send data for a digital port
    static inline var ANALOG_MESSAGE          : UInt = 0xE0; // send data for an analog pin (or PWM)
    static inline var REPORT_ANALOG           : UInt = 0xC0; // enable analog input by pin #
    static inline var REPORT_DIGITAL          : UInt = 0xD0; // enable digital input by port
    static inline var SET_PIN_MODE            : UInt = 0xF4; // set a pin to INPUT/OUTPUT/PWM/etc
    static inline var REPORT_VERSION          : UInt = 0xF9; // report firmware version
    static inline var SYSTEM_RESET            : UInt = 0xFF; // reset from MIDI
    static inline var START_SYSEX             : UInt = 0xF0; // start a MIDI SysEx message
    static inline var END_SYSEX               : UInt = 0xF7; // end a MIDI SysEx message

    // extended command set using sysex (0-127/0x00-0x7F)
    /* 0x00-0x0F reserved for user-defined commands */  
    static inline var SERVO_CONFIG            : UInt = 0x70; // set max angle, minPulse, maxPulse, freq
    static inline var STRING_DATA             : UInt = 0x71; // a string message with 14-bits per char
    static inline var SHIFT_DATA              : UInt = 0x75; // a bitstream to/from a shift register
    static inline var I2C_REQUEST             : UInt = 0x76; // send an I2C read/write request
    static inline var I2C_REPLY               : UInt = 0x77; // a reply to an I2C read request
    static inline var I2C_CONFIG              : UInt = 0x78; // config I2C settings such as delay times and power pins
    static inline var EXTENDED_ANALOG         : UInt = 0x6F; // analog write (PWM, Servo, etc) to any pin
    static inline var PIN_STATE_QUERY         : UInt = 0x6D; // ask for a pin's current mode and value
    static inline var PIN_STATE_RESPONSE      : UInt = 0x6E; // reply with pin's current mode and value
    static inline var CAPABILITY_QUERY        : UInt = 0x6B; // ask for supported modes and resolution of all pins
    static inline var CAPABILITY_RESPONSE     : UInt = 0x6C; // reply with supported modes and resolution
    static inline var ANALOG_MAPPING_QUERY    : UInt = 0x69; // ask for mapping of analog to pin numbers
    static inline var ANALOG_MAPPING_RESPONSE : UInt = 0x6A; // reply with mapping info
    static inline var REPORT_FIRMWARE         : UInt = 0x79; // report name and version of the firmware
    static inline var SAMPLING_INTERVAL       : UInt = 0x7A; // set the poll rate of the main loop
    static inline var SYSEX_NON_REALTIME      : UInt = 0x7E; // MIDI Reserved for non-realtime messages
    static inline var SYSEX_REALTIME          : UInt = 0x7F; // MIDI Reserved for realtime messages
    
    var waitForData : UInt = 0;
    var executeMultiByteCommand : UInt = 0;
    var multiByteChannel : UInt = 0;
    var storedInputData : Array<UInt> = [for(i in 0...MAX_DATA_BYTES) 0];
    var parsingSysex : Bool = false;
    var sysexBytesRead : UInt = 0;

    var digitalOutputData : Array<UInt> = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    var digitalInputData  : Array<UInt> = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    var analogInputData   : Array<UInt> = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

    static inline var MAX_PINS : UInt = 128;

    // var pinModes      : Array<UInt> = [for(i in 0...MAX_PINS) 0];
    var analogChannel : Array<UInt> = [for(i in 0...MAX_PINS) 0];
    // var pinMode       : Array<UInt> = [for(i in 0...MAX_PINS) 0];

    var majorVersion : UInt = 0;
    var minorVersion : UInt = 0;

    var write : UInt->Void;

    public function new(write : UInt->Void) {
        this.write = write;
    }

    /**
     * Create a proxy to an Arduino board running the Firmata 2 firmware.
     *
     * @param writer an instance of the Firmata.Writer interface
     */
    public function init() : Void {
        // enable all ports; firmware should ignore non-existent ones
        for (i in 0...16) {
            write(REPORT_DIGITAL | i);
            write(1);
        }

        // queryCapabilities();
        queryAnalogMapping();
        
        // for(i in 0...16) {
        //  write(REPORT_ANALOG | i);
        //  write(1);
        // }
    }
    /**
     * Returns the last known value read from the digital pin: HIGH or LOW.
     *
     * @param pin the digital pin whose value should be returned (from 2 to 13,
     * since pins 0 and 1 are used for serial communication)
     */
    public function digitalRead(pin : UInt) : UInt {
        return (digitalInputData[pin >> 3] >> (pin & 0x07)) & 0x01;
    }

    /**
     * Returns the last known value read from the analog pin: 0 (0 volts) to
     * 1023 (5 volts).
     *
     * @param pin the analog pin whose value should be returned (from 0 to 5)
     */
    public function analogRead(pin : UInt) : UInt {
        return analogInputData[pin];
    }

    /**
     * Set a digital pin to input or output mode.
     *
     * @param pin the pin whose mode to set (from 2 to 13)
     * @param mode either Arduino.INPUT or Arduino.OUTPUT
     */
    public function pinMode(pin : UInt, mode : UInt) : Void {
        write(SET_PIN_MODE);
        write(pin);
        write(mode);
    }

    /**
     * Write to a digital pin (the pin must have been put into output mode with
     * pinMode()).
     *
     * @param pin the pin to write to (from 2 to 13)
     * @param value the value to write: Arduino.LOW (0 volts) or Arduino.HIGH
     * (5 volts)
     */
    public function digitalWrite(pin : UInt, value : UInt) : Void {
        var portNumber = (pin >> 3) & 0x0F;

        if (value == 0)
            digitalOutputData[portNumber] &= ~(1 << (pin & 0x07))
        else
            digitalOutputData[portNumber] |= (1 << (pin & 0x07));

        write(DIGITAL_MESSAGE | portNumber);
        write(digitalOutputData[portNumber] & 0x7F);
        write(digitalOutputData[portNumber] >> 7);
    }

    /**
     * Write an analog value (PWM-wave) to a digital pin.
     *
     * @param pin the pin to write to (must be 9, 10, or 11, as those are they
     * only ones which support hardware pwm)
     * @param value the value: 0 being the lowest (always off), and 255 the highest
     * (always on)
     */
    public function analogWrite(pin : UInt, value : UInt) : Void {
        pinMode(pin, PWM);
        write(ANALOG_MESSAGE | (pin & 0x0F));
        write(value & 0x7F);
        write(value >> 7);
    }

    /**
    * Write a value to a servo pin.
    *
    * @param pin the pin the servo is attached to
    * @param value the value: 0 being the lowest angle, and 180 the highest angle
    */
    public function servoWrite(pin : UInt, value : UInt) : Void {
        write(ANALOG_MESSAGE | (pin & 0x0F));
        write(value & 0x7F);
        write(value >> 7);
    }
  
    function setDigitalInputs(portNumber : UInt, portData : UInt) : Void {
        // trace("digital port " + portNumber + " is " + portData);
        digitalInputData[portNumber] = portData;
    }

    function setAnalogInput(pin : UInt, value : UInt) : Void {
        // trace("analog pin " + pin + " is " + value);
        analogInputData[pin] = value;
    }

    function setVersion(majorVersion : UInt, minorVersion : UInt) : Void {
        // trace("version is " + majorVersion + "." + minorVersion);
        this.majorVersion = majorVersion;
        this.minorVersion = minorVersion;
    }


    function queryCapabilities() : Void {
        write(START_SYSEX);
        write(CAPABILITY_QUERY);
        write(END_SYSEX);
    }
    
    function queryAnalogMapping() : Void {
        write(START_SYSEX);
        write(ANALOG_MAPPING_QUERY);
        write(END_SYSEX);
    }

    function processSysexMessage() : Void {
        // trace(StringTools.hex(storedInputData[0], 2));
        switch(storedInputData[0]) { //first byte in buffer is command
            // case CAPABILITY_RESPONSE:
            //   for (UInt pin = 0; pin < pinModes.length; pin++) {
            //     pinModes[pin] = 0;
            //   }
            //   for (UInt i = 1, pin = 0; pin < pinModes.length; pin++) {
            //     for (;;) {
            //       UInt val = storedInputData[i++];
            //       if (val == 127) break;
            //       pinModes[pin] |= (1 << val);
            //       i++; // skip mode resolution for now
            //     }
            //     if (i == sysexBytesRead) break;
            //   }
            //   for (UInt port = 0; port < pinModes.length; port++) {
            //     boolean used = false;
            //     for (UInt i = 0; i < 8; i++) {
            //       if (pinModes[port * 8 + pin] & (1 << INPUT) != 0) used = true;
            //     }
            //     if (used) {
            //       write.write(REPORT_DIGITAL | port);
            //       write.write(1);
            //     }
            //   }
            //   break;
            case ANALOG_MAPPING_RESPONSE:
                for (pin in 0...analogChannel.length)
                    analogChannel[pin] = 127;
                for (i in 1...sysexBytesRead)
                    analogChannel[i - 1] = storedInputData[i];
                for (pin in 0...analogChannel.length) {
                    if (analogChannel[pin] != 127) {
                        write(REPORT_ANALOG | analogChannel[pin]);
                        write(1);
                    }
                }
        }
    }

    public function processInput(inputData : UInt) : Void {
        var command : UInt;
        
        // trace(">" + StringTools.hex(inputData, 2) + " " + inputData);
        
        if (parsingSysex) {
            if (inputData == END_SYSEX) {
                parsingSysex = false;
                processSysexMessage();
            } else {
                storedInputData[sysexBytesRead] = inputData;
                sysexBytesRead++;
            }
        } else if (waitForData > 0 && inputData < 128) {
            waitForData--;
            storedInputData[waitForData] = inputData;
            
            if (executeMultiByteCommand != 0 && waitForData == 0) {
                //we got everything
                switch(executeMultiByteCommand) {
                    case DIGITAL_MESSAGE:
                        setDigitalInputs(multiByteChannel, (storedInputData[0] << 7) + storedInputData[1]);
                    case ANALOG_MESSAGE:
                        setAnalogInput(multiByteChannel, (storedInputData[0] << 7) + storedInputData[1]);
                    case REPORT_VERSION:
                        setVersion(storedInputData[1], storedInputData[0]);
                }
            }
        } else {
            if(inputData < 0xF0) {
                command = inputData & 0xF0;
                multiByteChannel = inputData & 0x0F;
            } else {
                command = inputData;
                // commands in the 0xF* range don't use channel data
            }
            switch (command) {
                case DIGITAL_MESSAGE | ANALOG_MESSAGE | REPORT_VERSION:
                    waitForData = 2;
                    executeMultiByteCommand = command;
                case START_SYSEX:
                    parsingSysex = true;
                    sysexBytesRead = 0;
            }
        }
    }
}