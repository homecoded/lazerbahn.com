window.onload = (function () {
  var c = document.getElementById('stage'),
      d = c.getContext("2d"),
      ct = document.getElementById('text-stage'),
      dt = ct.getContext('2d'),
      CANVAS_WIDTH = c.width = 32,
      CANVAS_HEIGHT = c.height = 32,
      FONT_SIZE = 16,
      TEXT_CANVAS_WIDTH = ct.width = FONT_SIZE * CANVAS_WIDTH,
      TEXT_CANVAS_HEIGHT = ct.height = FONT_SIZE * CANVAS_HEIGHT,
      SCREEN_DIST = 2500,
      PROJECTION_CENTER_X = CANVAS_WIDTH / 2,
      PROJECTION_CENTER_Y = CANVAS_HEIGHT / 2,
      FIELD_OF_VIEW = CANVAS_WIDTH * 0.6,
      CUBE_VERTICES = [
        [-1, -1, -1], [1, -1, -1], [-1, 1, -1], [1, 1, -1],
        [-1, -1, 1], [1, -1, 1], [-1, 1, 1], [1, 1, 1]
      ],
      PLANES = [
        [0, 1, 3, 2],
        [1, 5, 7, 3],
        [5, 4, 6, 7],
        [4, 0, 2, 6],
        [2, 3, 7, 6],
        [4, 5, 1, 0]
      ],
      NORMALS = [
        [4, 0],
        [0, 1],
        [0, 4],
        [1, 0],
        [0, 2],
        [2, 0]
      ],
      ASCII_TABLE = ' ·-:=*##',
      ASCII_GRAPHICS = [],
      cubes = []
  ;
  /*                6 *********** 7
  *                *            *                     / \
             2 ************ 3   *                      | y
               *    4     *    ** 5           _|
               *          * **                /          - > x
             0 ************ 1                z
   */
  var textCanvas = [];

  for (var y = 0; y < CANVAS_HEIGHT; y++) {
    textCanvas[y] = [];
    for (var x = 0; x < CANVAS_WIDTH; x++) {
      textCanvas[y][x] = ' ';
    }
  }

  for (var i = 0; i < ASCII_TABLE.length; i++) {
    ASCII_GRAPHICS[i] = document.createElement('canvas');
    ASCII_GRAPHICS[i].width = FONT_SIZE;
    ASCII_GRAPHICS[i].height = FONT_SIZE;
    var ctx = ASCII_GRAPHICS[i].getContext("2d");
    ctx.fillStyle = '#999';
    ctx.font = FONT_SIZE + "px monospace";
    ctx.fillText(ASCII_TABLE[i], 0, FONT_SIZE);
  }

  cubes.push(
      new Cube(
          0,
          0,
          200,
          FIELD_OF_VIEW,
          {
            x: CANVAS_WIDTH / 2,
            y: CANVAS_WIDTH / 2,
            z: SCREEN_DIST
          },
          CUBE_VERTICES,
          PLANES,
          d
      )
  );

  var angleCounter = 0;

  function animationStep() {
    d.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    dt.clearRect(0, 0, TEXT_CANVAS_WIDTH, TEXT_CANVAS_HEIGHT);

    // Loop through the dots array and draw every dot
    angleCounter += 0.025;
    cubes[0].angle = Math.PI * 2 * Math.sin(angleCounter / 6);

    for (var i = 0; i < cubes.length; i++) {
      cubes[i].z = cubes[i].startZ + 800 * Math.sin(cubes[i].angle);
      cubes[i].draw();
    }

    // convert to text
    var pixels = d.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    var pixelData = pixels.data;

    for (var i = 0; i < pixelData.length; i += 4) {
      var value = (pixelData[i + 2] + pixelData[i + 3]) >> 1;
      var pointIndex = i / 4;
      var x = pointIndex % CANVAS_WIDTH;
      var y = ~~(pointIndex / CANVAS_WIDTH)
      textCanvas[y][x] = ~~((value - 1) / (255 / ASCII_TABLE.length));
    }

    for (var y = 0; y < CANVAS_HEIGHT; y++) {
      for (var x = 0; x < CANVAS_WIDTH; x++) {
        var asciiIndex = textCanvas[y][x];
        if (asciiIndex > 0) {
          dt.drawImage(ASCII_GRAPHICS[asciiIndex], x * FONT_SIZE, y * FONT_SIZE)
        }
      }
    }
  }

  setInterval(animationStep, 100);
});


