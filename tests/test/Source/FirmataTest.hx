package ;

import hxFirmata.Arduino;

class FirmataTest {
	
	public function new() {
		var arduino = new Arduino(Arduino.list()[5]);
	}

	static public function main() {
		var app = new FirmataTest();
	}
}