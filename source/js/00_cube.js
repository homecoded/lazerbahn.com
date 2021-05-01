function Cube(x, y, z, foV, projection, vertices, planes, gfxContext) {
  this.x = x;
  this.y = y;
  this.z = z;
  this.foV = foV;
  this.projection = projection;
  this.vertices = vertices;
  this.planes = planes;
  this.gfxContext = gfxContext;

  this.startZ = this.z;
  this.radius = 700;
  this.angle = 0;
  this.points = [];

  // Do some math to project the 3D position into the 2D canvas
  this.project = function (x, y, z) {
    const sizeProjection = this.foV / (this.foV + z);
    const xProject = (x * sizeProjection) + this.projection.x;
    const yProject = (y * sizeProjection) + this.projection.y;
    return {
      size: sizeProjection,
      x: xProject,
      y: yProject
    }
  }

  this.rotateZ = function (v, angle) {
    var sinV = Math.sin(angle);
    var cosV = Math.cos(angle);
    var x = v.x;
    var y = v.y;
    v.x = x * cosV - y * sinV;
    v.y = y * cosV + x * sinV;
    return v;
  }

  this.rotateY = function (v, angle) {
    var sinV = Math.sin(angle);
    var cosV = Math.cos(angle);
    var y = v.y;
    var z = v.z;
    v.y = y * cosV - z * sinV;
    v.z = z * cosV + y * sinV;
    return v;
  }

  this.rotateX = function (v, angle) {
    var sinV = Math.sin(angle);
    var cosV = Math.cos(angle);
    var x = v.x;
    var z = v.z;
    v.x = x * cosV + z * sinV;
    v.z = z * cosV - x * sinV;
    return v;
  }

  // Draw the dot on the canvas
  this.draw = function () {
    // rotate points
    var points = this.points = [];
    for (var i = 0; i < this.vertices.length; i++) {
      var point = {
        x: this.vertices[i][0] * this.radius,
        y: this.vertices[i][1] * this.radius,
        z: this.vertices[i][2] * this.radius
      }

      // rotate
      point = this.rotateX(point, this.angle);
      point = this.rotateY(point, this.angle * -1.9);
      point = this.rotateZ(point, this.angle / -3.4);

      // translate
      point.z = point.z + this.projection.z + this.z;

      // project
      point.projection = this.project(point.x, point.y, point.z);
      points.push(point);
    }

    for (var i = 0; i < this.planes.length; i++) {
      var plane = this.planes[i];
      var point = points[plane[0]];
      var currentZ = point.z;
      var minZ = 400;
      var maxZ = 3500;
      var colorDistance = maxZ - minZ;
      var color = 0;
      if (currentZ > maxZ) color = 0;
      else if (currentZ < minZ) color = 255
      else color = ~~(255 - (((currentZ - minZ) / colorDistance) * 255));

      this.gfxContext.strokeStyle = 'rgb(' + [color, color, color].join(',') + ')';

      this.gfxContext.beginPath();
      this.gfxContext.moveTo(point.projection.x, point.projection.y);

      for (var j = 1; j < 4; j++) {
        point = points[plane[j]];
        this.gfxContext.lineTo(point.projection.x, point.projection.y);
      }
      this.gfxContext.closePath()
      this.gfxContext.stroke();
    }
  }
}
