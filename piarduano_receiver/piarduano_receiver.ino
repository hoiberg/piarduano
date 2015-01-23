/*
* Receives the input from the Piarduano OSX app and controlls an buzzer..
* Couldn't be any simpler :)
* Observation: if you enter a non-nummeric character after the frequency in the serial, the serial.available somehow gives another '0' after the timeout
* .. which causes the buzzer to stop buzzing...
*/

#define buzPin 8

void setup() {
  pinMode(buzPin, OUTPUT);  
  Serial.begin(9600);
  Serial.setTimeout(10); // to reduce the lag
  
  while (!Serial) { ; } // wait for serial to connect
  Serial.print("Greetings, human. I'll be your arduino for today."); // greet :) (don't use println)
}

void loop() {
  if (Serial.available()) {
    float frequency = Serial.parseFloat();
    if (frequency == 0) {
      noTone(buzPin);
    } else {
      tone(buzPin, frequency);
    }
  }
}
