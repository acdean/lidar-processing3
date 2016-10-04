// quick and dirty lidar data to point cloud for Processing3
// data is from data.gov.uk/dataset/lidar-tiles-tile-index
// press 'l' to load another file
// added terrain mode (compile time)
// acd 2016 10 01

import peasy.*;

public static final float ZMAG = 2.0;
public static final String FILENAME = "tq1080_DSM_2m.asc";

PShape cloud;
PeasyCam cam;
float ox, oy;  // origin
float xmag, ymag;
LidarData lidar;

void setup() {
  size(1000, 750, P3D);
  cam = new PeasyCam(this, 500);
  lidar = loadLidar(FILENAME); // load initial file
  cam.lookAt(ox, oy, 0.0);
}

void draw() {
  background(0);
  lights();
  shape(cloud);
}

void keyReleased() {
  if (key == 'l') {
    selectInput("Select a lidar tile:", "fileSelected");
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    lidar = loadLidar(selection.getAbsolutePath());
  }
}

// loads the file, sets global variables
LidarData loadLidar(String filename) {
  LidarData data = new LidarData(filename);
  xmag = data.cellSize;
  ymag = -data.cellSize; // flip y direction

  //cloud = data.asPointCloud();
  cloud = data.asTerrain();

  // min and max heights
  println("MinMax: " + data.zmin + "," + data.zmax);
  // origin (TODO use xllcorner and yllcorner from file)
  ox = (data.cols * xmag) / 2;
  oy = (data.rows * ymag) / 2;
  println("Origin: " + ox + "," + oy);
  return data;
}

class LidarData {
  int cols;
  int rows;
  int xllCorner; // lower left x
  int yllCorner; // lower left y
  float cellSize;  // in metres
  int noData;
  float[][] points;
  float zmin = 1000;
  float zmax = -1000;

  LidarData(String filename) {
    String[] strs = loadStrings(filename);
    int row = 0;
    points = new float[strs.length][];
    for (int i = 0 ; i < strs.length ; i++) {
      //println("String: [" + strs[i] + "]");
      if (strs[i].startsWith("ncols")) {
        cols = int(getValue(strs[i]));
      } else if (strs[i].startsWith("nrows")) {
        rows = int(getValue(strs[i]));
      } else if (strs[i].startsWith("xllcorner")) {
        xllCorner = int(getValue(strs[i]));
      } else if (strs[i].startsWith("yllcorner")) {
        yllCorner = int(getValue(strs[i]));
      } else if (strs[i].startsWith("cellsize")) {
        cellSize = float(getValue(strs[i]));
      } else if (strs[i].startsWith("NODATA_value")) {
        noData = int(getValue(strs[i]));
      } else {
        // data
        String[] columns = split(trim(strs[i]), " ");
        //println("Columns: " + columns);
        points[row] = new float[columns.length];
        for (int x = 0 ; x < columns.length ; x++) {
          //println("x: " + columns[x]);
          points[row][x] = float(columns[x]);
        }
        row++;
      }
    }
  }

  PShape asPointCloud() {
    // create cloud
    PShape shape = createShape();
    shape.beginShape(POINTS);
    shape.stroke(0, 255, 0);
    shape.strokeWeight(2);
    shape.noFill();
    for (int y = 0 ; y < rows ; y++) {
      for (int x = 0 ; x < cols ; x++) {
        float z = points[x][y]; 
        if (z != noData) {
          shape.stroke(map(z, 20, 70, 64, 255)); // heightmap to colour
          shape.vertex(x * xmag, y * ymag, ZMAG * z);
          if (z < zmin) {
            zmin = z;
          }
          if (z > zmax) {
            zmax = z;
          }
        }
      }
    }
    shape.endShape();
    return shape;
  }

  PShape asTerrain() {
    PShape shape = createShape();
    shape.beginShape(TRIANGLES);
    shape.noStroke();
    shape.fill(128);
    // NB ignore last row / column
    for (int y = 0 ; y < rows - 1 ; y++) {
      for (int x = 0 ; x < cols - 1 ; x++) {
        // 0 1
        // 2 3
        float z0 = points[x][y]; 
        float z1 = points[x + 1][y]; 
        float z2 = points[x][y + 1]; 
        float z3 = points[x + 1][y + 1]; 
        if (z0 != noData && z1 != noData && z2 != noData && z3 != noData) {
          // triangle 1
          shape.vertex(x * xmag, y * ymag, ZMAG * z0);
          shape.vertex((x + 1) * xmag, y * ymag, ZMAG * z1);
          shape.vertex(x * xmag, (y + 1) * ymag, ZMAG * z2);
          // triangle 2
          shape.vertex((x + 1) * xmag, y * ymag, ZMAG * z1);
          shape.vertex(x * xmag, (y + 1) * ymag, ZMAG * z2);
          shape.vertex((x + 1) * xmag, (y + 1) * ymag, ZMAG * z3);
        }
      }
    }
    shape.endShape();
    return shape;
  }
  
  // convert "name      numeric" to "numeric"
  String getValue(String in) {
    String out = in.replaceAll("[A-Za-z_ ]", "");
    println("[" + in + "] - [" + out + "]");
    return out;
  }
}