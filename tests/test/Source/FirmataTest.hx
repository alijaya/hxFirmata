package ;

import hxFirmata.Arduino;

class FirmataTest {

    var arduino : Arduino;
    
    public function new() {
        arduino = new Arduino(Arduino.list()[5]);
    }

    public function run() {
        while(true) {
            var reading = arduino.analogRead(0);
            trace(reading);
            arduino.analogWrite(9, reading >> 2);
            Sys.sleep(0.04);
        }
    }

    static public function main() {
        var app = new FirmataTest();
        app.run();
    }
}