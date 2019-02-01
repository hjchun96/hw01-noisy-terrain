import {vec2, vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import Plane from './geometry/Plane';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  'Daylight': 'Medium',
  'FlowSpeed': 2.5,
};

let square: Square;
let plane : Plane;
let plane2: Plane;
let wPressed: boolean;
let aPressed: boolean;
let sPressed: boolean;
let dPressed: boolean;
let planePos: vec2;

function loadScene() {
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  
  plane = new Plane(vec3.fromValues(0,0,0), vec2.fromValues(100,100), 20);
  plane.create();

  plane2 = new Plane(vec3.fromValues(0,0,0), vec2.fromValues(100,100), 20);
  plane2.create();

  wPressed = false;
  aPressed = false;
  sPressed = false;
  dPressed = false;
  planePos = vec2.fromValues(0,0);
}

function main() {
  window.addEventListener('keypress', function (e) {
    // console.log(e.key);
    switch(e.key) {
      case 'w':
      wPressed = true;
      break;
      case 'a':
      aPressed = true;
      break;
      case 's':
      sPressed = true;
      break;
      case 'd':
      dPressed = true;
      break;
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
      case 'w':
      wPressed = false;
      break;
      case 'a':
      aPressed = false;
      break;
      case 's':
      sPressed = false;
      break;
      case 'd':
      dPressed = false;
      break;
    }
  }, false);

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'Daylight', [ 'High', 'Medium', 'Low' ] );
  gui.add(controls, 'FlowSpeed', 0, 10);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 10, -20), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(164.0 / 255.0, 233.0 / 255.0, 1.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/terrain-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/terrain-frag.glsl')),
  ]);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  const basePlane = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/basePlane-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/basePlane-frag.glsl')),
  ]);

  function processKeyPresses() {
    let velocity: vec2 = vec2.fromValues(0,0);
    if(wPressed) {
      velocity[1] += 1.0;
    }
    if(aPressed) {
      velocity[0] += 1.0;
    }
    if(sPressed) {
      velocity[1] -= 1.0;
    }
    if(dPressed) {
      velocity[0] -= 1.0;
    }
    let newPos: vec2 = vec2.fromValues(0,0);
    vec2.add(newPos, velocity, planePos);
    lambert.setPlanePos(newPos);
    basePlane.setPlanePos(newPos);
    planePos = newPos;
  }

  let prevDaylight = 4;
  let prevDaylight_type = 'Medium';
  let prevFlowspeed = 2.5;
  let time = 0;

  // This function will be called every frame
  function tick() {

    let daylight = prevDaylight;
    let flowspeed = prevFlowspeed;
    camera.update();
    stats.begin();
    time += 1;
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    processKeyPresses();

    if(controls.Daylight != prevDaylight_type)
    {
      prevDaylight_type = controls.Daylight;

      switch(prevDaylight_type) {
        case "High":
          daylight = 6;
          break;
        case "Medium":
          daylight = 4;
          break;
        case "Low":
          daylight = 2;
          break;
      }

      prevDaylight = daylight;
    }

    if(controls.FlowSpeed != prevFlowspeed) 
    {
      flowspeed = controls.FlowSpeed;
      prevFlowspeed = flowspeed;
    }


    renderer.render(camera, lambert, [
      plane,
    ], time, daylight, flowspeed);

    renderer.render(camera, basePlane, [
      plane2,
    ], time, daylight, flowspeed);

    renderer.render(camera, flat, [
      square,
    ], time, daylight, flowspeed);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
