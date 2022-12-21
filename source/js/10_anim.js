window.onload = (function () {
  var pixelCanvas = document.getElementById('stage'),
      pixelContext = pixelCanvas.getContext("2d"),
      textModeCanvas = document.getElementById('text-stage'),
      textModeContext = textModeCanvas.getContext('2d'),
      CANVAS_WIDTH = pixelCanvas.width = 32,
      CANVAS_HEIGHT = pixelCanvas.height = 32,
      FONT_SIZE = 16,
      TEXT_CANVAS_WIDTH = textModeCanvas.width = FONT_SIZE * CANVAS_WIDTH,
      TEXT_CANVAS_HEIGHT = textModeCanvas.height = FONT_SIZE * CANVAS_HEIGHT,
      SCREEN_DIST = 2500,
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
      objects3d = [],
      textCanvas = [],
      angleCounter = 0
  ;
  /*                6 *********** 7
  *                *            *                     / \
             2 ************ 3   *                      | y
               *    4     *    ** 5           _|
               *          * **                /          - > x
             0 ************ 1                z
   */

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
    ctx.fillStyle = '#f6f3ce';
    ctx.font = FONT_SIZE + "px monospace";
    ctx.fillText(ASCII_TABLE[i], 0, FONT_SIZE);
  }

  objects3d.push(
      new O3D(
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
          pixelContext
      )
  );

  function animationStep() {
    pixelContext.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    textModeContext.clearRect(0, 0, TEXT_CANVAS_WIDTH, TEXT_CANVAS_HEIGHT);

    // Loop through the dots array and draw every dot
    angleCounter += 0.025;
    objects3d[0].angle = Math.PI * 2 * Math.sin(angleCounter / 6);

    for (var i = 0; i < objects3d.length; i++) {
      objects3d[i].z = objects3d[i].startZ + 800 * Math.sin(objects3d[i].angle);
      objects3d[i].draw();
    }

    // convert to text
    var pixels = pixelContext.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
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
          textModeContext.drawImage(ASCII_GRAPHICS[asciiIndex], x * FONT_SIZE, y * FONT_SIZE)
        }
      }
    }
  }

  setInterval(animationStep, 100);
});


