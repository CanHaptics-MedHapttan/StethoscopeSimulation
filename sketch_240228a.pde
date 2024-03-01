PImage img;

void setup() {
  size(500,800);
  img = loadImage("Human.png");
}

void draw() {
  image(img, 0, 0);
  //image(img, 0, 0, width/2, height/2);
}
