// Document class to hold submission + comment data
class Document {
  String id;
  String url;
  String title;
  String selfText;
  ArrayList<String> content;
  
  // Constructor
  Document(String dId, String dUrl, String dTitle, String dST) {
    id = dId;
    url = dUrl;
    title = dTitle;
    selfText = dST;
    content = new ArrayList<String>();
  }
  
  // Append content
  void update(String dat) {
    dat = dat.replace("\n", " ");
    dat = dat.replace("\r", " ");
    if (!dat.equals("[deleted]")) {
      content.add(dat);  
    }      
  }
}