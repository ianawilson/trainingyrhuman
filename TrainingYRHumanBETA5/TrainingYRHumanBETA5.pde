import processing.serial.*;

/*
TrainingYRHuman - 2011 
a project created by ecoarttech: 
making art at the convergence of biological, cultural, mental, and digital networks >
http://www.ecoarttech.org

Many thanks to:

RobotGrrl.com
for her clear code on using the twitter4j-core-2.2.4.jar

Eric Meinhardt
Talented student and programmer at the University of Rochester

PhiLho 
for his invaluable help on the Processing Forum http://phi.lho.free.fr/index.en.html

Code licensed under:
CC-BY

*/

// using secret.java, which has:
// static String OAuthConsumerKey
// static String OAuthConsumerSecret
// static String AccessToken
// static String AccessTokenSecret

// variable set up
String myTimeline;
java.util.List statuses = null;
User[] friends;
Twitter twitter = new TwitterFactory().getInstance();
RequestToken requestToken;
String[] theSearchTweets = new String[12];
int tweetindex = 0;
String tweetsPath = "tweets.txt"; // made this relative so it is more portable
String [] lines;
ArrayList unreadTweets = new ArrayList();

int timeDelay = 12000; //10000 milliseconds = 10 seconds
int tweetTimeDelay = 60000; //get tweets once every minute

int time = 0;
int timetweets = 0;

Serial myPort;

void setup() {
  // consult the printed list and choose the index of wherever your arduino is connected
  println(Serial.list());
  int arduinoPort = 1;
  
  myPort = new Serial(this, Serial.list()[arduinoPort], 9600);
  
  lines = loadStrings(tweetsPath);
  background(152,152,152);
  connectTwitter();
  getSearchTweets();
  rectMode(CORNER);
}

int inByte;

void serialEvent(Serial p) {
  inByte = myPort.read();
  if (inByte == 1) {
    String tweet = getTweet();
    myPort.write(tweet+'\n');
  }
}

boolean bFlashBg = true;
boolean bWaitText = true;
boolean bCheckTweets = true;

void draw() {
  
  // visualize();
  
  // Get new tweets from internet
  if (millis() - timetweets >= tweetTimeDelay) {
    timetweets = millis();
    println("Getting Search Tweets");
    getSearchTweets();
  }
}
// Initial connection
void connectTwitter() {

  twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
  AccessToken accessToken = loadAccessToken();
  twitter.setOAuthAccessToken(accessToken);

}

void visualize() {
  if (bFlashBg) {
    timeDelay = 5000; // time delay for strobe effect
  } else {
    timeDelay = 12000; // time delay for reading the text
  }
  if (bFlashBg) {
    rectMode(CORNER);
    float m = millis();
    fill(m % 150);
    rect(0, 0, 1440, 900);
  } else {

    if (bWaitText) {
      bWaitText = !bWaitText;
      DisplayTweets();
    }
  }
  if (millis() - time >= timeDelay) {
    time = millis();
    bFlashBg = !bFlashBg;
    bWaitText = true;
  }
}

// Sending a tweet
void sendTweet(String t) {

  try {
    Status status = twitter.updateStatus(t);
    println("Successfully updated the status to [" + status.getText() + "].");
  } catch(TwitterException e) { 
    println("Send tweet: " + e + " Status code: " + e.getStatusCode());
  }

}


// Loading up the access token
private static AccessToken loadAccessToken(){
  return new AccessToken(AccessToken, AccessTokenSecret);
}


// Get your tweets
void getTimeline() {

  try {
    statuses = twitter.getUserTimeline(); 
  } catch(TwitterException e) { 
    println("Get timeline: " + e + " Status code: " + e.getStatusCode());
  }

  for(int i=0; i<statuses.size(); i++) {
    Status status = (Status)statuses.get(i);
    println(status.getUser().getName() + ": " + status.getText());
  }

}

// getSearchTweets()  ---- Search for tweets and write them to tweets.txt
void getSearchTweets() {
  String queryStr = "#trainingYRhuman";
  try {
    Query query = new Query(queryStr);    
    query.setRpp(10); // Get 10 of the 100 search results  
    QueryResult result = twitter.search(query);    
    ArrayList tweets = (ArrayList) result.getTweets();    

    for (int i=0; i<tweets.size(); i++) {
      Tweet t = (Tweet)tweets.get(i);	
      String user = t.getFromUser();
      String msg = t.getText();
      Date d = t.getCreatedAt();

      theSearchTweets[i] = msg.substring(queryStr.length()+1);
      // text(theSearchTweets[i], width/2, height-250, width/1, 800); // print tweet on screen 

      //decide whether or not to write the tweet to file by checking whether the tweet's message appears in the file 
      Boolean msgInFile = false;
      BufferedReader reader;
      try {
        reader = createReader(tweetsPath);   //first open the file for reading
        for (String nextLine = reader.readLine(); nextLine != null; nextLine = reader.readLine()){ //do a linear search through the file...
          String[] matches = match(nextLine, msg); //look for msg in the current line 
          if (matches != null){ //if there is at least one match
            msgInFile = true; //note as much
            println("Found duplicate in existing tweet archive:\n" + msg);
            break;  //and quit searching for the current message
          }
        }
      }
      catch(Exception e){ 
        println("Error: Can't read tweets file.");
        println(e.getMessage());
      }

      if (!msgInFile){
        // FileWriter file;
        try  
        { 
          // append new tweet to lines
          String[] newLines = new String[lines.length + 1];
          System.arraycopy(lines, 0, newLines, 0, lines.length);
          // add msg to last spot in array, which should be unoccupied
          newLines[newLines.length - 1] = msg;
          
          // save lines to file again
          // for some reason, saveStrings doesn't assume to write in the data dir,
          // so it is added here manually
          saveStrings("data/" + tweetsPath, newLines);
          
          println("Found new tweet: " + msg);
          unreadTweets.add(msg);
        }  
        catch(Exception e)  
        {  
          println("Error: Can't open tweets file! " + e);
        } 
      }
    }

  } catch (TwitterException e) {
    println("Search tweets: " + e);
  }
}

// read from tweets.txt and print on screen
// Get your tweets
void DisplayTweets() {
  PFont font;
  // textFont(createFont( "Calibri-Bold", 72, true));
  font = loadFont("Calibri-Bold-72.vlw"); 
  textFont(font, 72); 

  textAlign(CENTER);
  textLeading(75);
  //rectMode(CORNER);
  background(150,150,150); //refreshes or clears the screen

  // text attributes
  rectMode(CENTER);
  fill(0);

  String tweet = getTweet();
  text(tweet, width/2, height-250, width/1, 800);
}


String getTweet() {
  // if we have any unread tweets (brand new since this session)
  // display one of those
  if (unreadTweets.size() > 0) {
    return (String) unreadTweets.remove(0);
  }
  // if no unread tweets,
  // get a random value from the array length then check to see we are in bounds if we are then display a tweet
  // int y = 200;
  // int index = 1;
  int r = int(random(lines.length));
  if(tweetindex <= lines.length){ 
    tweetindex = (tweetindex + 1);
    
    return lines[r];
  } else {
    tweetindex = 0; // reset counter
    lines = loadStrings(tweetsPath); //changed
    background(152,152,152);
    // send the very latest tweet aby subtracing one from the total length or else it errors: array out of bounds
    tweetindex = (tweetindex + 1);
    
    return lines[lines.length -1];
  }
}
