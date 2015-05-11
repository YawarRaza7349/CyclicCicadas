// Cicada Data: http://hydrodictyon.eeb.uconn.edu/projects/cicada/databases/magicicada/magi_search.php
// US Map: http://commons.wikimedia.org/wiki/File:Blank_US_Map.svg
// NOTE: See https://github.com/processing/processing/issues/2377 for why the map doesn't look quite right pre-Processing 2.2.

class CicadaData {
  String species;
  String brood;
  Integer cycle; // allow for null values, in the case of data abnormality
  Integer year; // allow for null values, in the case of data abnormality
  String recordType;
  String state;
  String county;
}

CicadaData mkData(String row) {
  CicadaData data = new CicadaData();
  data.species = codeToExpanded.get(row.substring(0, 2));
  data.brood = codeToExpanded.get(row.substring(2, 4));
  try {
    data.cycle = Integer.parseInt(codeToExpanded.get(row.substring(4, 6)));
  } catch(NumberFormatException e) {
    data.cycle = null;
  }
  try {
    data.year = Integer.parseInt(codeToExpanded.get(row.substring(6, 8)));
  } catch(NumberFormatException e) {
    data.year = null;
  }
  data.recordType = codeToExpanded.get(row.substring(8, 10));
  data.state = codeToExpanded.get(row.substring(10, 12));
  data.county = codeToExpanded.get(row.substring(12, 14));
  return data;
}

// map the condensed two character "code" to the value it originally represents 
StringDict codeToExpanded;

// the following arrays have 17 and 13 elements respectively, one for each year in the cycle
// each element of the array maps U.S. state names to the number of findings in each state during that year
IntDict[] selectedData17;
IntDict[] selectedData13;

PShape usMap;

// maps U.S. state to the SVG element that visually represents the state
HashMap<String, PShape> usStates;

String trace(String x)
{
  println(x);
  return x;
}

void setup() {
  size(959, 593);
  
  // populate codeToExpanded
  codeToExpanded = new StringDict();
  String[] translateRows = loadStrings("key.tsv");
  for(String row : translateRows) {
    String[] keyVal = split(row, '\t');
    codeToExpanded.set(keyVal[0], keyVal[1]);
  }
  
  // read and parse all the raw data
  String allData = loadStrings("data.txt")[0];
  CicadaData[] allObjs = new CicadaData[allData.length()/14];
  for(int i = 0; i < allObjs.length; ++i) {
    allObjs[i] = mkData(allData.substring(14 * i, 14 * (i + 1))); // isolate each "row" of the "table" represented by the file
  }
  
  // process raw data into relevant information
  selectedData17 = new IntDict[17];
  selectedData13 = new IntDict[13];
  for(int i = 0; i < 17; ++i) {
    selectedData17[i] = new IntDict();
  }
  for(int i = 0; i < 13; ++i) {
    selectedData13[i] = new IntDict();
  }
  
  usStates = new HashMap<String, PShape>();
  
  // identify all states
  // cannot access underlying XML from PShape object
  // so load it from the original file as XML
  XML svgXml = loadXML("usMap.svg");
  for(XML child : svgXml.getChildren()) {
    if("#text".equals(child.getName())) {
      continue;
    }
    if("state".equals(child.getString("class"))) {
      String stateInitials = child.getString("id");
      usStates.put(stateInitials, null);
      for(IntDict data : selectedData17) {
        data.add(stateInitials, 0);
      }
      for(IntDict data : selectedData13) {
        data.add(stateInitials, 0);
      }
    }
  }
  
  // identify SVG shapes for states
  usMap = loadShape("usMap.svg");
  for(PShape child : usMap.getChildren()) {
    if(usStates.containsKey(child.getName())) {
      usStates.put(child.getName(), child);
      fillState(child, #FFFFFF);
    }
  }
  
  for(CicadaData cd : allObjs) {
    // the raw data contains less data points as the year decreases
    // to maximize the consistency and representativity of the data
    // we choose to limit ourselves to looking only at the most recent cycle for both types of cicadas
    if(cd.cycle != null && cd.cycle == 17) {
      if(cd.year != null && cd.year > 1994 && cd.year < 2012) {
        selectedData17[cd.year-1995].add(cd.state, 1);
      }
    } else if(cd.cycle != null && cd.cycle == 13) {
      if(cd.year != null && cd.year > 1998 && cd.year < 2012) {
        selectedData13[cd.year-1999].add(cd.state, 1);
      }
    }
  }
}

void draw() {
  background(0);
  for(String stateName : usStates.keySet()) {
    colorState(usStates.get(stateName), stateName);
  }
  shape(usMap, 0, 0, width, height);
  textSize(50);
  fill(255);
  text(str(millis() / 1000 + 1999), 650, 75);
}

color getColorFromNumber(int num) {
  int modified = int(log(num + 1) * 16);
  return color(255, 255 - modified, 255 - modified);
}

void colorState(PShape stateShape, String stateName) {
  fillState(stateShape, getColorFromNumber(selectedData13[(millis() / 1000) % 13].get(stateName) + selectedData17[(millis() / 1000 + 4) % 17].get(stateName)));
}

void fillState(PShape shape, color col) {
  if(shape.getFamily() == GROUP) {
    for(PShape child : shape.getChildren()) {
      fillState(child, col);
    }
  } else {
    shape.beginShape();
    shape.fill(col);
    shape.endShape();
  }
}
