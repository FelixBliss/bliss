 // functions in dart
//functions with parameters but no return
int arithmetics(int n1,int n2){
  int sumResults;
  int productResults;
  int differenceResults;
  
 sumResults=n1+n2;
  productResults=n1*n2;
  differenceResults=n1-n2;
  
  //addition
  print("the sum is:${sumResults}");
 //multiplication
  print("the product is:${productResults}");
  //subtraction
  print("the difference is :${differenceResults}"); 
  
  return sumResults;
}

//function with return but no parameters
String readMe(){
  String read="I will teach you how to code with ease on your phone";
  return read; 
}

//function with no parameters and return
hellocode(){
  String code="coding is a nice game";
  print(code);
}
void main(){
  arithmetics(10,2);
  print(readMe ());
  hellocode();
}
