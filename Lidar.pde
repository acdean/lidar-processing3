// quick and dirty lidar data to point cloud for Processing3
// data is from data.gov.uk/dataset/lidar-tiles-tile-index
// acd 2016 10 01

import peasy.*;

public static final float ZMAG = 2.0;
public static final String FILENAME = "tq1080_DSM_2m.asc";

PShape cloud;
PeasyCam cam;
float ox, oy;  // origin
float xmag, ymag;

void setup() {
  size(1000, 750, P3D);
  cam = new PeasyCam(this, 500);
  LidarData lidar = new LidarData(FILENAME);
  xmag = lidar.cellSize;
  ymag = -lidar.cellSize; // flip y direction
  float zmin = 1000;
  float zmax = -1000;

  // create cloud
  cloud = createShape();
  cloud.beginShape(POINTS);
  cloud.stroke(0, 255, 0);
  cloud.strokeWeight(2);
  cloud.noFill();
  for (int y = 0 ; y < lidar.rows ; y++) {
    for (int x = 0 ; x < lidar.cols ; x++) {
      float z = lidar.points[x][y]; 
      if (z != lidar.noData) {
        cloud.stroke(map(z, 20, 70, 64, 255)); // heightmap to colour
        cloud.vertex(x * xmag, y * ymag, ZMAG * z);
        if (z < zmin) {
          zmin = z;
        }
        if (z > zmax) {
          zmax = z;
        }
      }
    }
  }
  cloud.endShape();

  // min and max heights
  println("MinMax: " + zmin + "," + zmax);
  // origin (TODO use xllcorner and yllcorner from file)
  ox = (lidar.cols * xmag) / 2;
  oy = (lidar.rows * ymag) / 2;
  println("Origin: " + ox + "," + oy);
  cam.lookAt(ox, oy, 0.0);
}

void draw() {
  background(0);
  shape(cloud);
}

class LidarData {
  int cols;
  int rows;
  int xllCorner; // lower left x
  int yllCorner; // lower left y
  float cellSize;  // in metres
  int noData;
  float[][] points;

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
  
  // convert "name      numeric" to "numeric"
  String getValue(String in) {
    String out = in.replaceAll("[A-Za-z_ ]", "");
    println("[" + in + "] - [" + out + "]");
    return out;
  }
}
