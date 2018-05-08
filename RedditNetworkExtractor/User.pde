// Unweighted class
class User {
  String name;
  ArrayList<String> subreddits;
  
  // Constructor
  User(String nm) {
    name = nm;
    subreddits = new ArrayList<String>();
  }
  
  // Append documents if necessary
  void update(String dat) {
    if (!subreddits.contains(dat)) {
      subreddits.add(dat);  
    }
  }
}