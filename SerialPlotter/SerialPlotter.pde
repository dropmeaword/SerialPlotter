import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

// default serial port
String serialPortName = "/dev/tty.usbmodem1411";

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = true;

Serial serial;
ControlP5 cp5;
JSONObject plotterConfigJSON;

// plots
Graph BarChart = new Graph(300, 100, 500, 120, color(20, 20, 200));
Graph LineGraph = new Graph(300, 360, 500, 200, color (20, 20, 200));
float[] barChartValues = new float[6];
float[][] lineGraphValues = new float[6][100];
float[] lineGraphSampleNumbers = new float[100];
color[] graphColors = new color[6];
boolean capturing = false;

// possible serial datarates
int []dataRates = {300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200};

// helper for saving the executing path
String topSketchPath = "";

void setup() {
  frame.setTitle("Serial Plotter");
  size(890, 640);

  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // settings save file
  topSketchPath = sketchPath;
  String cfgname = topSketchPath+"/config.json";
  File file = new File(cfgname);
  if(file.exists()) {
    plotterConfigJSON = loadJSONObject( cfgname );
  } else {
    println("Config file " + cfgname + " doesn't exist");
  }

  // gui
  cp5 = new ControlP5(this);
  
  // init charts
  setChartSettings();
  for (int i=0; i<barChartValues.length; i++) {
    barChartValues[i] = 0;
  }
  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
    }
  }

  int x = 10; 
  int y = 40;

  cp5.addTextlabel("capture").setText("capture/idle").setPosition(x-10, y).setColor(0);
  cp5.addToggle("capToggle").setPosition(x, y+10).setValue(0).setMode(ControlP5.SWITCH);

  x += 120;
  int lastDataRate = int(getPlotterConfigString("ttyDataRate"));
  DropdownList dr = cp5.addDropdownList("ttyDataRate").setPosition(x, y+30).setSize(60, 200).setValue(int(getPlotterConfigString("ttyDataRate")));
  dr.actAsPulldownMenu(true);
  dr.setBackgroundColor(color(190));
  dr.setItemHeight(20);
  dr.setBarHeight(18);
  dr.captionLabel().set("Data rate");
  dr.captionLabel().style().marginTop = 3;
  dr.captionLabel().style().marginLeft = 3;
  dr.valueLabel().style().marginTop = 3;
  int idx = 0;
  for(int rate : dataRates ) {
    dr.addItem( ""+rate, idx);
    idx++;
  }
  dr.setIndex(lastDataRate);

  x = 10;
  y += 24;
  // build-up serial port selector
  //cp5.addTextlabel("lblSerial").setText("Serial device").setPosition(x, y).setColor(0);
  int lastDevice = int(getPlotterConfigString("ttyDevice"));
  DropdownList dd = cp5.addDropdownList("ttyDevice").setPosition(x, y+30).setSize(180, 200).setValue(int(getPlotterConfigString("ttyDevice")));
  dd.actAsPulldownMenu(true);
  dd.setBackgroundColor(color(190));
  dd.setItemHeight(20);
  dd.setBarHeight(18);
  dd.captionLabel().set("Serial device");
  dd.captionLabel().style().marginTop = 3;
  dd.captionLabel().style().marginLeft = 3;
  dd.valueLabel().style().marginTop = 3;
  int idx2 = 0;
  for(String port : Serial.list() ) {
    dd.addItem(port, idx2);
    idx2++;
  }
  dd.setIndex(lastDevice);

  x = 10;
  y += 40;
  int savey = y;

  // on/off controls for upper graph
  cp5.addTextlabel("on/off2").setText("on/off").setPosition(x, y).setColor(0);
  cp5.addTextlabel("multipliers2").setText("multipliers").setPosition(x=55, y).setColor(0);
  cp5.addTextfield("bcMultiplier1").setPosition(x=60, y).setText(getPlotterConfigString("bcMultiplier1")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("bcMultiplier2").setPosition(x, y=y+34).setText(getPlotterConfigString("bcMultiplier2")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("bcMultiplier3").setPosition(x, y=y+34).setText(getPlotterConfigString("bcMultiplier3")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("bcMultiplier4").setPosition(x, y=y+34).setText(getPlotterConfigString("bcMultiplier4")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("bcMultiplier5").setPosition(x, y=y+34).setText(getPlotterConfigString("bcMultiplier5")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("bcMultiplier6").setPosition(x, y=y+34).setText(getPlotterConfigString("bcMultiplier6")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addToggle("bcVisible1").setPosition(x=x-50, y=savey).setValue(int(getPlotterConfigString("bcVisible1"))).setMode(ControlP5.SWITCH);
  cp5.addToggle("bcVisible2").setPosition(x, y=y+34).setValue(int(getPlotterConfigString("bcVisible2"))).setMode(ControlP5.SWITCH);
  cp5.addToggle("bcVisible3").setPosition(x, y=y+34).setValue(int(getPlotterConfigString("bcVisible3"))).setMode(ControlP5.SWITCH);
  cp5.addToggle("bcVisible4").setPosition(x, y=y+34).setValue(int(getPlotterConfigString("bcVisible4"))).setMode(ControlP5.SWITCH);
  cp5.addToggle("bcVisible5").setPosition(x, y=y+34).setValue(int(getPlotterConfigString("bcVisible5"))).setMode(ControlP5.SWITCH);
  cp5.addToggle("bcVisible6").setPosition(x, y=y+34).setValue(int(getPlotterConfigString("bcVisible6"))).setMode(ControlP5.SWITCH);

  // range edit boxes
  cp5.addTextfield("bcMaxY").setPosition(x=250, y=90).setText(getPlotterConfigString("bcMaxY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("bcMinY").setPosition(x, y=y+118).setText(getPlotterConfigString("bcMinY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMaxY").setPosition(x, y=y+140).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMinY").setPosition(x, y=y+198).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);

  // on/off controls for bottom graph
  cp5.addTextlabel("label").setText("on/off").setPosition(x=13, y=320).setColor(0);
  cp5.addTextlabel("multipliers").setText("multipliers").setPosition(x=55, y).setColor(0);
  cp5.addTextfield("lgMultiplier1").setPosition(x=60, y=y+10).setText(getPlotterConfigString("lgMultiplier1")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier2").setPosition(x, y=y+40).setText(getPlotterConfigString("lgMultiplier2")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier3").setPosition(x, y=y+40).setText(getPlotterConfigString("lgMultiplier3")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier4").setPosition(x, y=y+40).setText(getPlotterConfigString("lgMultiplier4")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier5").setPosition(x, y=y+40).setText(getPlotterConfigString("lgMultiplier5")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier6").setPosition(x, y=y+40).setText(getPlotterConfigString("lgMultiplier6")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addToggle("lgVisible1").setPosition(x=x-50, y=330).setValue(int(getPlotterConfigString("lgVisible1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  cp5.addToggle("lgVisible2").setPosition(x, y=y+40).setValue(int(getPlotterConfigString("lgVisible2"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[1]);
  cp5.addToggle("lgVisible3").setPosition(x, y=y+40).setValue(int(getPlotterConfigString("lgVisible3"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[2]);
  cp5.addToggle("lgVisible4").setPosition(x, y=y+40).setValue(int(getPlotterConfigString("lgVisible4"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[3]);
  cp5.addToggle("lgVisible5").setPosition(x, y=y+40).setValue(int(getPlotterConfigString("lgVisible5"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[4]);
  cp5.addToggle("lgVisible6").setPosition(x, y=y+40).setValue(int(getPlotterConfigString("lgVisible6"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[5]);
}

void initSerial(String name, int rate) {
  println("Initializing serial port on " + name + " at a data rate of " + rate);
  if (!mockupSerial) {
    serial = new Serial(this, name, rate);
  }
  else
    serial = null;
}

byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable

void draw() {
  if (mockupSerial || serial.available() > 0) {
    String myString = "";

    if(capturing) {
      if (!mockupSerial) {
        try {
          serial.readBytesUntil('\r', inBuffer);
        }
        catch (Exception e) {
        }
        myString = new String(inBuffer);
      }
      else {
        myString = mockupSerialFunction();
      }
    }

    //println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
    
    // count number of bars and line graphs to hide
    int numberOfInvisibleBars = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("bcVisible"+(i+1))) == 0) {
        numberOfInvisibleBars++;
      }
    }
    int numberOfInvisibleLineGraphs = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleLineGraphs++;
      }
    }
    // build a new array to fit the data to show
    barChartValues = new float[6-numberOfInvisibleBars];

    // build the arrays for bar charts and line graphs
    int barchartIndex = 0;
    for (i=0; i<nums.length; i++) {

      // update barchart
      try {
        if (int(getPlotterConfigString("bcVisible"+(i+1))) == 1) {
          if (barchartIndex < barChartValues.length)
            barChartValues[barchartIndex++] = float(nums[i])*float(getPlotterConfigString("bcMultiplier"+(i+1)));
        }
        else {
        }
      }
      catch (Exception e) {
      }

      // update line graph
      try {
        if (i<lineGraphValues.length) {
          for (int k=0; k<lineGraphValues[i].length-1; k++) {
            lineGraphValues[i][k] = lineGraphValues[i][k+1];
          }

          lineGraphValues[i][lineGraphValues[i].length-1] = float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
        }
      }
      catch (Exception e) {
      }
    }
  }

  background(255); 
  BarChart.DrawAxis();              
  BarChart.Bar(barChartValues);

  LineGraph.DrawAxis();
  for (int i=0;i<lineGraphValues.length; i++) {
    LineGraph.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
  }
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  BarChart.xLabel=" Readings ";
  BarChart.yLabel="Value";
  BarChart.Title="";  
  BarChart.xDiv=1;  
  BarChart.yMax=int(getPlotterConfigString("bcMaxY")); 
  BarChart.yMin=int(getPlotterConfigString("bcMinY"));

  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=20;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-100;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}

void startCapture() {
  println("Starting capture");
  capturing = true;
  int serialidx = int(getPlotterConfigString("ttyDevice"));
  String serialName = Serial.list()[serialidx];
  int rateidx = int(getPlotterConfigString("ttyDataRate"));
  int serialRate = dataRates[rateidx];
  initSerial(serialName, serialRate);
}

void stopCapture() {
  println("Stopping capture");
  capturing = false;
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  boolean change = false;
  String parameter = theEvent.getName();
  String value = "";
  println("control: "+parameter);

  if(theEvent.isGroup()) {
    value = theEvent.getGroup().value()+"";
    println("val = "+value);
    change = true;
  } else if (theEvent.isController()) {
    if (theEvent.isAssignableFrom(Textfield.class) 
      || theEvent.isAssignableFrom(Toggle.class) 
      || theEvent.isAssignableFrom(Button.class)) {
      if (theEvent.isAssignableFrom(Textfield.class)) {
        value = theEvent.getStringValue();
        change = true;
      } else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
        value = theEvent.getValue()+"";
        change = true;

        println("param: " + parameter);
        if( parameter.equals("capToggle") ) {
          if (int(value) == 1) {
            startCapture();
          } else {
            stopCapture();
          }
        } // if toggle button
      }
    }
  }

  if(change) {
    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/config.json");
    setChartSettings();
  }
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}

