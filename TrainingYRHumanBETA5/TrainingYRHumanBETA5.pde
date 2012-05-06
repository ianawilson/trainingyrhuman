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

// This is where you enter your Oauth info
static String OAuthConsumerKey = "TDMj0jtcA4Gb3TOBd5B6A";
static String OAuthConsumerSecret = "aFcyHegp4PWf2PFlG1TsU3hnafEuF8rC0ZNMc4obE3Y";

// This is where you enter your Access Token info
static String AccessToken = "318024495-y7Zot2axO0piHWE6QCDjCMaXftAcfKvEZDcbvT6V";
static String AccessTokenSecret = "4ytPp6c535NO6hjQQRA2KaYcSveqcDXQJe5bH84NBM";

// variable set up
String myTimeline;
java.util.List statuses = null;
User[] friends;
Twitter twitter = new TwitterFactory().getInstance();
RequestToken requestToken;
String[] theSearchTweets = new String[12];
int tweetindex = 0;
String tweetsPath = "/Users/cpeppermint/Documents/Processing/TrainingYRHumanBETA5/data/tweets.txt"; //added
String [] lines = loadStrings(tweetsPath); //changed
int len = lines.length;
int latesttweet = 1;

int timeDelay = 12000; //10000 milliseconds = 10 seconds
int tweetTimeDelay = 600000; //get tweets once every 10 minutes

int time = 0;
int timetweets = 0;

void setup() {
  size(1440,900); // Macbook Air
  // size(1920,1080); // Vancouver Macs
  background(152,152,152);
  connectTwitter();
  getSearchTweets();
  DisplayTweets(); 
  rectMode(CORNER);
}
  
boolean bFlashBg = true;
boolean bWaitText = true;
boolean bCheckTweets = true;

void draw() {
 if (bFlashBg) {
   timeDelay = 5000; // time delay for strobe effect
 } else {
   timeDelay = 12000; // time delay for reading the text
 }
   if (bFlashBg) {
//~     println("FLASHING");
    rectMode(CORNER);
    float m = millis();
    fill(m % 150);
    rect(0, 0, 1440, 900);
  } else {

//~     println("NO FLASHING");
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
     println("found duplicate of " + msg + " in existing tweet archive.\n");
     break;  //and quit searching for the current message
   }
   
 }
}
catch(Exception e){ 
  println("Error: Can't read tweets file.");
  println(e.getMessage());
}

if (!msgInFile){
FileWriter file;
 try  
   {  
  file = new FileWriter(tweetsPath, true); //bool tells to append test should be theSearchTweets[i] instead //changed
  file.write("\n"+msg, 0, msg.length()+1); //(string, start char, end char)
  file.close();
        }  
     catch(Exception e)  
   {  
     println("Error: Can't open tweets file!");
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

// get a random value from the array length then check to see we are in bounds if we are then display a tweet
// int y = 200;
// int index = 1;
int r = int(random(lines.length));
if(tweetindex <= lines.length){ 
  println(r);
  text(lines[r], width/2, height-250, width/1, 800);
  tweetindex = (tweetindex + 1);
} else {
    tweetindex = 0; // reset counter
    println("This is the else");
    println(tweetindex);
    // getSearchTweets();
    String [] lines = loadStrings(tweetsPath); //changed
    int len = lines.length;
    println(len);
    background(152,152,152);
    text(lines[len -1], width/2, height-250, width/1, 800); // print the very latest tweet aby subtracing one from the total length (len) or else it errors: array out of bounds
    tweetindex = (tweetindex + 1);
 
}
  
}