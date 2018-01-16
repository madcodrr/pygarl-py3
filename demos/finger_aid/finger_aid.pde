import java.io.*;
import java.util.concurrent.*;

String port = "COM6";
String modelPath = "C:\\Users\\Federico\\Documents\\finger_model.svm";
String scriptPath = "D:\\GitHub\\pygarl\\demos\\finger_aid.py";
DataThread dataThread = new DataThread();

Status status = Status.INIT;
String gesture = "make a gesture";
int alpha = 255;
float alphaSpeed = 5;

int rowCount = 5;
int colCount = 7;

int row = 2;
int col = 3;

int rowSize;
int colSize;

void setup() {
  size(1024, 768);
  orientation(LANDSCAPE);
   
  println("Starting DataThread...");
  dataThread.start();
  
  rowSize = height/rowCount;
  colSize = width/colCount;

} 

void draw () {
  background(0);
  
  for (int r = 0; r < rowCount; r++) {
     for (int c = 0; c < colCount; c++) {
         if (r == row && c == col) {
            fill(0,0,100, 150); 
         }else{
            fill(30,30,30, 255); 
         }
         rect(c*colSize, r*rowSize, colSize, rowSize);
         
     }
  }
  
  String statusText = "STARTING...";
  
  fill(255,255,255);
  if (status == Status.INIT) {
     statusText = "INITIALIZING...";
  }else if (status == Status.LOADING) {
     statusText = "LOADING..."; 
  }else if (status == Status.STARTED) {
     statusText = "STARTED";
     fill(0, 255, 0, 255);
  }else if (status == Status.ERROR) {
     statusText = "ERROR";
     fill(255, 0, 0, 255);
  }
  
  
  textSize(16);
  text(statusText, width/2, 20); 
  
  textSize(64);
  
  textAlign(CENTER);
  fill(255,255,255, alpha);
  text(gesture, width/2, height/2);
  
  alpha-=alphaSpeed;
}

void receiveGesture(String g) {
  gesture = g;
  alpha = 255;
  if (g.equals("left")) {
    col--;
  }else if (g.equals("right")) {
    col++;
  }else if (g.equals("pull")) {
    row++;
  }else if (g.equals("push")) {
    row--;
  }
}

public class DataThread extends Thread {  
  Process p;
  boolean shouldStop = false;
  
  public void run () {
    try {
      String line;
      println("Starting process...");
      ProcessBuilder pb = new ProcessBuilder("python", scriptPath, port, modelPath);
      pb.redirectErrorStream(true);
      p = pb.start();     
      
      BufferedReader input = new BufferedReader(new InputStreamReader(p.getInputStream()));
      
      while (!shouldStop && (line = input.readLine()) != null) {
        if (line.equals("LOADING")) {
          status = Status.LOADING;
        }else if (line.equals("LOADED")) {
          status = Status.LOADED; 
        }else if (line.equals("STARTED")) {
          status = Status.STARTED; 
        }else if (line.equals("EXCEPTION")) {
          status = Status.ERROR; 
        }else if (line.startsWith("GESTURE ")) {
          receiveGesture(line.substring(8));
        }
        println(line);
        Thread.sleep(1);
      }
      
    } catch (Exception err) {
      err.printStackTrace();
    }
    println("Exiting...");
  }
  
  public void closePython() {
    p.destroyForcibly();
  }
}

void exit() {
  println("Closing...");
  dataThread.closePython();
  dataThread.shouldStop = true;
  super.exit();
}

enum Status {
  INIT,
  LOADING,
  LOADED,
  STARTED,
  ERROR
}
 