  #define tonePin 8

  // only change the following three lines (and update the variable names in the rest of the sketch)  
  #define songCount 13
  float songNotes[] = {329.6, 0.0, 370.0, 0.0, 370.0, 349.2, 370.0, 349.2, 370.0, 349.2, 370.0, 349.2, 370.0};
  int songDurations[] = {100, 32, 119, 112, 111, 95, 119, 104, 119, 95, 87, 95, 79};
  
  int currentTone = 0;
  
  void setup() 
  {    
    pinMode(tonePin, OUTPUT);
  }
  
  void loop() 
  {    
      float theTone = songNotes[currentTone];
      if (theTone != 0) {
        tone(tonePin, theTone);
      } else {
        noTone(tonePin);
      }
      
      delay(songDurations[currentTone]);
      
      currentTone++;
      if (currentTone == songCount) currentTone = 0;    
  }

