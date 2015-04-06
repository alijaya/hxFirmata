package ;

import hxFirmata.Arduino;

class FirmataTest {

    var arduino : Arduino;
    
    public function new() {
        arduino = new Arduino(Arduino.list()[5]);
    }

    public function run() {
        while(true) {
            trace(arduino.analogRead(0));
            Sys.sleep(0.04);
        }
    }

    static public function main() {
        var app = new FirmataTest();
        app.run();
    }
}