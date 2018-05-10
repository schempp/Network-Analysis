import java.util.*;
import java.text.SimpleDateFormat;
import java.text.ParseException;

Calendar cal = Calendar.getInstance();

String actualRequest = "";
String request = "https://api.pushshift.io/reddit/search/";
String request1 = "https://api.pushshift.io/reddit/search/submission/?";
String request2 = "https://api.pushshift.io/reddit/submission/comment_ids/";
String request3 = "https://api.pushshift.io/reddit/search/comment/?";

//String afterTime = "2018-02-01T00:00:00.000-0000";
//String beforeTime = "2018-02-14T00:00:00.000-0000";
String afterTime = "2018-02-12T00:00:00.000-0000";
String beforeTime = "2018-02-13T00:00:00.000-0000";

int sort = 0;
String[] sortDirection = {"desc","asc"};

int sortIdx = -1;
String[] sortTypes = {"score", "num_comments", "created_utc"};

int resultSize = 2;

int before;
int after;
          
void setup() {
  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
  try {
    
    Date dt = sdf.parse(afterTime);
    long epoch = dt.getTime();
    
    after = (int)(epoch/1000);
    println(after);
    
    dt = sdf.parse(beforeTime);
    epoch = dt.getTime();
    
    before = (int)(epoch/1000);
    println(before);
  } catch(ParseException e) {
    println("Date Format Error");
  }
  
  ArrayList<Integer> qList = computeQueryList(resultSize);  
  
  ArrayList<Document> docList = retrieveDocList(qList,"UserSubmissionSubreddit");
  
  ArrayList<Document> allDocs = retrieveComments(docList,"UserCommentSubreddit");
  
  writeCorpus(allDocs,"corpus");

  
  System.exit(0);
}

void writeUserTable(ArrayList<User> userTable, String fileName) {
  
  String fName = fileName;
  if (!fileName.endsWith(".csv")) {
    fName += ".csv";
  }
  
  Table newTable = new Table();
  
  newTable.addColumn("user");
  newTable.addColumn("subreddits");
  
  for (int i = 0; i < userTable.size(); i++) {
    TableRow newRow = newTable.addRow();  
    
    newRow.setString("user",userTable.get(i).name);
    
    String subredditCollection = userTable.get(i).subreddits.get(0);
    
    if (userTable.get(i).subreddits.size() > 1) {
      for (int j = 1; j < userTable.get(i).subreddits.size(); j++) {
        subredditCollection = subredditCollection + "|" +  userTable.get(i).subreddits.get(j);
      }       
    }
    
    newRow.setString("subreddits",subredditCollection);
  }
  
  saveTable(newTable, "data/" + fName);
}

void writeUserTable2(ArrayList<User> userTable, String fileName) {
  
  String fName = fileName;
  if (!fileName.endsWith(".csv")) {
    fName += ".csv";
  }
  
  PrintWriter output = createWriter("data/" + fName);
  
  output.println("user,subreddits");
  
  for (int i = 0; i < userTable.size(); i++) {
    String subredditCollection = userTable.get(i).subreddits.get(0);
      
    if (userTable.get(i).subreddits.size() > 1) {
      for (int j = 1; j < userTable.get(i).subreddits.size(); j++) {
        subredditCollection = subredditCollection + "|" +  userTable.get(i).subreddits.get(j);
      }       
    }
    
    output.println(userTable.get(i).name + "," + subredditCollection);
  }
  
  output.flush();
  output.close();
}

// Computes the query array
ArrayList<Integer> computeQueryList(int size) {
  
  // ArrayList to return
  ArrayList<Integer> queryList = new ArrayList<Integer>();
  
  // max size for PushShift API is 500
  // if greater than limit
  if (size > 500) {
    
    // shallow copy of size
    int numberOfResults = size + 0;
    
    // bin size into array where each position can be up to 500
    // Example: size = 1001 --> {500,500,1}
    //          size = 1495 --> {500,500,495}
    while (numberOfResults > 0) {
      if (numberOfResults > 500) {
        queryList.add(500);
        numberOfResults -= 500;
      } else {
        queryList.add(numberOfResults);
        numberOfResults = 0;
      }
    }        
  } else {
    // otherwise queryArray is simply the input size
    queryList.add(resultSize);
  }
    
  return queryList;
}

// Computes the query array
ArrayList<Document> retrieveDocList(ArrayList<Integer> queryList, String fileName) {
  
  // Intialize as Max Value
  int prevScore = 999999999;
  
  // Users --> Subreddit (directed network)
  ArrayList<User> users = new ArrayList<User>();  
  
  // Document content
  ArrayList<Document> docs = new ArrayList<Document>();
  
  // Submission IDs
  ArrayList<String> submissionIDs = new ArrayList<String>();
  
  // Iterate thru queryArray
  for (int i = 0; i < queryList.size(); i++) {
    
    // Only include "score=<" parameter if not first iteration
    if (i == 0) {
      actualRequest = request1 + "after=" + after + "&before=" + before + "&sort_type=score&sort=desc&size=" + queryList.get(i) + "&over_18=false";
    } else {
      actualRequest = request1 + "after=" + after + "&before=" + before + "&sort_type=score&sort=desc&size=" + queryList.get(i) + "&score=<" + prevScore + "&over_18=false";
    }
    
    // testing
    println(actualRequest);
    println(queryList.get(i));

    // JSON obj to handle HTTP request
    JSONObject jsonObj = loadJSONObject(actualRequest);
    
    // read JSONArray from request
    JSONArray jsonAr = jsonObj.getJSONArray("data");
    
    // iterate thru JSON array
    for (int j = 0; j < jsonAr.size(); j++) {
      
      // create temporary object for each item in array
      JSONObject tmpObj = jsonAr.getJSONObject(j);
      
      // test if submission already encountered
      if (!submissionIDs.contains(tmpObj.getString("id"))) {
        
        // if never encountered add
        submissionIDs.add(tmpObj.getString("id"));  
        
        String selfText = tmpObj.getString("selftext");
        selfText = selfText.replace("\n", " ");
        selfText = selfText.replace("\r", " ");
        
        // create document
        Document tmpDoc = new Document(tmpObj.getString("id"),tmpObj.getString("url"),tmpObj.getString("title"),tmpObj.getString("selftext"));
        
        // add to doc list
        docs.add(tmpDoc);        
      } else {
        
        // otherwise must add 1 to end of queryArray
        int tmpNum = queryList.get(queryList.size()-1);
        if (tmpNum < 500) {
          tmpNum++;
          queryList.set(queryList.size()-1,tmpNum);
        } else {
          queryList.add(1);
        }
      }
      
      // find user idx, otherwise is -1
      int userIdx = -1;
      for (int k  = 0; k < users.size(); k++) {
        if (users.get(k).name.equals(tmpObj.getString("author"))) {
          userIdx = k;
          break;
        }
      }
      
      // test to see if user is in list
      if (userIdx == -1) {
        
        // if not in list, test if author is [deleted]
        if (!tmpObj.getString("author").equals("[deleted]")) {
          
          // if not [deleted] add to users list
          User tmpUser = new User(tmpObj.getString("author"));
          tmpUser.update(tmpObj.getString("subreddit"));          
          users.add(tmpUser);
        }        
      } else {                  
        // if in list, then update subreddit list
        users.get(userIdx).update(tmpObj.getString("subreddit"));  
      }
      
      // testing
      println(tmpObj.getString("title"));
      println(tmpObj.getInt("score"));

      prevScore = tmpObj.getInt("score") + 1;
    }
  }
  
  writeUserTable2(users,fileName);
  
  return docs;
}

ArrayList<Document> retrieveComments(ArrayList<Document> documents, String fileName) {
  
  //ArrayList<Document> docs = new ArrayList<Document>();
  
  ArrayList<User> usersComments = new ArrayList<User>();      
  
  // iterate thru each submission
  for (int i = 0; i < documents.size(); i++) {
    println((i+1) + " out of " + documents.size());
    
    // HTTP request all commentIDs associated with submission
    JSONObject jsonObj = loadJSONObject(request2 + documents.get(i).id);
    
    // obtain the array of commentIDs
    JSONArray jsonAr = jsonObj.getJSONArray("data");
    
    // shallow copy of list size
    int jsonSize = jsonAr.size() + 0;    
    
    // how many id's to retrieve at once (max ~ 250; but can be unstable --> 200 is safe)
    int binSize = 200;
    int counter = 0;
    
    while (jsonSize > 0) {
      String idQuery = jsonAr.getString(counter++);
      if (jsonSize > binSize) {
        for (int j = 1; j < binSize; j++) {
          idQuery = idQuery + "," + jsonAr.getString(counter++);
        }
        jsonSize-=binSize;
      } else {
        if (jsonSize > 1) {
          for (int j = 1; j < jsonSize; j++) {
            idQuery = idQuery + "," + jsonAr.getString(counter++);
          }  
        }
        jsonSize-=jsonSize;
      }
      
      boolean requestTry = false;
      JSONObject jsonObj2 = new JSONObject();
      JSONArray jsonAr2 = new JSONArray();
      
      while (!requestTry) {
        try {
          // HTTP request each comment by ID to retrieve author, subreddit, and content
          jsonObj2 = loadJSONObject(request3 + "ids=" + idQuery);
          jsonAr2 = jsonObj2.getJSONArray("data");
          requestTry = true;
        } catch (Exception e) {
          
        }
      }
      
      for (int k = 0; k < jsonAr2.size(); k++) {
        JSONObject tmpObj2 = jsonAr2.getJSONObject(k);
        
        documents.get(i).update(tmpObj2.getString("body"));
        
        int userIdx = -1;
        for (int n  = 0; n < usersComments.size(); n++) {
          if (usersComments.get(n).name.equals(tmpObj2.getString("author"))) {
            userIdx = n;
            break;
          }
        }
        
        if (userIdx == -1) {
          if (!tmpObj2.getString("author").equals("[deleted]")) {
            User tmpUser = new User(tmpObj2.getString("author"));
            tmpUser.update(tmpObj2.getString("subreddit"));
            
            usersComments.add(tmpUser);
          }          
        } else {                  
          usersComments.get(userIdx).update(tmpObj2.getString("subreddit"));  
        }
      }
      println(usersComments.size());
    }
  }
  
   writeUserTable2(usersComments,fileName);
   
  return documents;
}

void writeCorpus(ArrayList<Document> docs, String fileName) {
  
  String fName = fileName;
  if (!fileName.endsWith(".txt")) {
    fName += ".txt";
  }
  
  PrintWriter output = createWriter("data/" + fName); //<>//
  
  for (int i = 0; i < docs.size(); i++) {
    
    output.print(docs.get(i).id + "\t" + docs.get(i).url + "\t" + docs.get(i).title + "\t");
    if (!docs.get(i).selfText.equals("")) {
      output.print(docs.get(i).selfText + "\t");
    }
    
    if (docs.get(i).content.size() > 0) {
      output.print(docs.get(i).content.get(0));
      
      if (docs.get(i).content.size() > 2) {
        
        for (int j = 1; j < docs.get(i).content.size()-1; j++) {
          output.print(" " + docs.get(i).content.get(j));
        }
        
        output.println(" " + docs.get(i).content.get(docs.get(i).content.size()-1));
      } else {
        output.println(" " + docs.get(i).content.get(docs.get(i).content.size()-1));
      }      
    }    
  }
  
  output.flush();
  output.close();
}

void draw() {
  
}  
