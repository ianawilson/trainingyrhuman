// To add more tweets, add to tweets.h

#include "HT1632.h"

#define DATA 2
#define WR   3
#define CS0  4
#define CS1  5
#define CS2  6
#define CS3  7

// This sets up all of our matricies with the correct control selects
HT1632LEDMatrix matrix = HT1632LEDMatrix(DATA, WR, CS0, CS1, CS2, CS3);


// buffer is plenty long (should only have a max of 140)
// char buffer[160];


// DON'T TOUCH THESE !!
// They are for private use by printLong()

// scrollPos is pixels from the left
int scrollPos;
// charPos is the character that we're on in the string
int charPos;
// charWidth = 6, 6 pixels per char
int charWidth = 6;

String prevSubstring;
int prevScrollPos;

String tweet;

void setup() {
  Serial.begin(9600);
  
  matrix.begin(HT1632_COMMON_16NMOS);  
  
  // setup for text
  matrix.setTextSize(1);    // size 1 == 8 pixels high
  
  // little "hello" screen flash and clear
  matrix.fillScreen();
  delay(500);
  matrix.clearScreen();
  
  reset();
}




void loop() {
  printTweet();
}


void reset() {
  // setup for printTweet
  scrollPos = matrix.width();
  charPos = 0;
  tweet = getTweetFromProcessing();
}


String getTweetFromProcessing() {
  // send a byte with value "true", 0x01, as a request
  byte request = (byte) true;
  bool done = false;
  String buffer = "";
  
  // while we have not hit the null terminator
  while (! done) {
    // if there is something to read
    if(Serial.available() > 0) {
      // read a single char, append to string
      char c = Serial.read();
      buffer += c;
      
      // if it's a null terminator, we're done
      if (c == '\n') {
        done = true;
      }
    }
  }
  
  return buffer;
}

void printTweet() {
  // figure out where we are
  
  // maximum chars displayed are the width / charWidth
  // +1 for the one char that will be shifting on to the display
  int maxChars = matrix.width() / charWidth + 1;
  
  
  // the last char we will display is either the position + the
  // number of chars we can display (maxChars) or the last char
  // in the string (text.length), whichever is sooner (lower)
  int lastChar = min(tweet.length(), charPos + maxChars);
  
  
  // get the sub string
  String substring = tweet.substring(charPos, lastChar);
  
  // clear old
  // this is faster than clearScreen() !!
  matrix.setTextColor(0);   // 'unlit' LEDs
  matrix.setCursor(prevScrollPos, 4);
  matrix.print(prevSubstring);
  
  // draw it  
  matrix.setTextColor(1);   // 'lit' LEDs
  matrix.setCursor(scrollPos, 4);
  matrix.print(substring);
  
  // all of this is faster becuase we don't write to the screen til the end
  // BOOM!
  matrix.writeScreen();
  
  
  // save this data for the clearing of the old next time through
  prevSubstring = substring;
  prevScrollPos = scrollPos;
  
  // set up for next time
  // decrease the scroll position
  scrollPos--;
  // if we have scrolled one char all the way off the screen
  if (scrollPos <= -1 * charWidth) {
    // reset to 0
    scrollPos = 0;
    // shift ahead in the string
    charPos ++;
  }
  
  // if we have completely run the string out, reset !
  if (charPos >= tweet.length()) {
    reset();
  }
}
