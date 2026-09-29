// The St4sh hero: the S3 mark, cut from AvQest's outlines and rendered live with three.js.
//
// Back to front. A full-screen shader draws deep space: stars that twinkle, and a purple nebula,
// domain-warped noise lit by the flare and by the pointer. The mark is the two glyphs extruded
// with a rounded bevel. Its faces are a river of deep purple blood: a distance field baked from
// the outlines tells each point which way its stroke runs, so the liquid flows down the strokes,
// pools on the level, boils, and bubbles, with a wet surface that catches the light. Its bevels
// are pearl that burns with pale flame tongues. The pointer is a lamp: the nearer it comes to a
// stroke, the lighter that stroke's purple, and the mark turns towards it. Sparks run along the
// outlines, dust drifts through the scene, and a lens flare, every element drawn by a shader,
// burns above the 3. A click sends a ring of light through the letters.
//
// The scene renders to a half-float target; a bright pass and four blur passes make the bloom,
// and the composite applies ACES tone mapping, a vignette and dithering. Colours come from the
// site's CSS tokens, so sass/brand.sass stays their single owner.
//
// The canvas stays inert until the hero is on screen, stops when the tab is hidden, and caps the
// device pixel ratio. Under prefers-reduced-motion nothing moves on its own: a frame is drawn when
// the pointer moves, and that is all. The still in the markup stays until the first frame is
// drawn; without WebGL nothing is added and the still remains.

import * as THREE from './vendor/three.module.min.js';

// AvQest (GemFonts / Imitation Warehouse; 1001Fonts Free For Commercial Use License, which allows
// logos and embedding): the outlines of its S and 3, rendered as they are, in font units, 1000 to
// the em, y up. The font itself ships unchanged in static/fonts/.
const GLYPHS = {
  'S': { advance: 580, kern: -110, path: 'M 280 -23 Q 211 -23 159.5 17.5 Q 108 58 95 125 L 192 168 L 208 142 Q 183 126 183 118 Q 183 102 207 81 Q 238 54 283 54 Q 331 54 364.5 80.5 Q 398 107 398 154 Q 398 202 317 246 L 225 296 Q 172 325 148 355 Q 120 391 120 446 Q 120 514 171 558 Q 219 601 288 601 Q 407 601 462 492 L 380 418 L 361 448 Q 380 464 380 474 Q 380 497 347 512 Q 320 525 294 525 Q 254 525 229 506 Q 201 485 201 446 Q 201 416 223 397 Q 235 386 271 367 L 379 309 Q 480 255 480 153 Q 480 74 418 24 Q 361 -23 280 -23 Z' },
  '3': { advance: 602, path: 'M 360 364 Q 422 344 461 291.5 Q 500 239 500 174 Q 500 89 443 32 Q 386 -25 301 -25 Q 219 -25 158 34 Q 97 93 102 175 L 105 220 L 236 222 L 222 188 Q 184 188 184 174 Q 184 125 218 91 Q 252 57 301 57 Q 350 57 383.5 91 Q 417 125 417 174 Q 417 228 379.5 260 Q 342 292 287 292 Q 251 292 187 272 L 368 512 L 192 512 Q 166 512 160.5 505 Q 155 498 153 470 L 120 455 L 122 596 L 192 594 L 534 594 Z' },
};

const EM = 1000;
const TEXT = 'S3';
const DEPTH = 120 / EM;
const BEVEL = { thickness: 22 / EM, size: 13 / EM, segments: 7 };
const SPARKS = 46;
// How far flames reach past the outline, in font-relative units; up-facing edges burn 1.3 times
// as tall, so that is how far above the mark they rise.
const FLAME_REACH = 0.16;
const FLAME_OVERHANG = FLAME_REACH * 1.3;
const MOTES = 420;
const FLARE_ELEMENTS = [
  // t: position along the axis from the light (0) through the screen centre (1)
  { t: 0.0, size: 0.26, shape: 0, color: [1.0, 0.92, 1.0], alpha: 1.0 },
  { t: 0.0, size: 1.3, shape: 3, color: [0.85, 0.7, 1.0], alpha: 0.55 },
  { t: 0.0, size: 0.46, shape: 1, color: [0.75, 0.55, 1.0], alpha: 0.18 },
  { t: 0.28, size: 0.06, shape: 2, color: [0.6, 0.45, 1.0], alpha: 0.28 },
  { t: 0.46, size: 0.03, shape: 0, color: [1.0, 0.6, 0.9], alpha: 0.4 },
  { t: 0.64, size: 0.09, shape: 2, color: [0.45, 0.55, 1.0], alpha: 0.14 },
  { t: 0.86, size: 0.14, shape: 1, color: [0.8, 0.5, 1.0], alpha: 0.08 },
  { t: 1.02, size: 0.045, shape: 2, color: [1.0, 0.7, 0.95], alpha: 0.2 },
];

const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

function cssColor(name, fallback) {
  const raw = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  const color = new THREE.Color(fallback);
  if (raw) {
    try { color.setStyle(raw); } catch { /* an unparsable token keeps the fallback */ }
  }
  return color;
}

function glyphShapes() {
  const shapes = [];
  let pen = 0;
  for (const ch of TEXT) {
    const glyph = GLYPHS[ch];
    const path = new THREE.ShapePath();
    const tokens = glyph.path.split(' ');
    for (let i = 0; i < tokens.length;) {
      const op = tokens[i++];
      const n = () => Number(tokens[i++]);
      const x = () => (n() + pen) / EM;
      const y = () => n() / EM;
      if (op === 'M') path.moveTo(x(), y());
      else if (op === 'L') path.lineTo(x(), y());
      else if (op === 'Q') path.quadraticCurveTo(x(), y(), x(), y());
      else if (op === 'C') path.bezierCurveTo(x(), y(), x(), y(), x(), y());
      // Z: ShapePath closes each subpath when it becomes a shape.
    }
    // TrueType outlines wind their solids clockwise, CFF ones counter-clockwise: the largest
    // contour of a glyph is always a solid, so its winding says which convention this font uses.
    let largest = 0;
    for (const subPath of path.subPaths) {
      const area = THREE.ShapeUtils.area(subPath.getPoints());
      if (Math.abs(area) > Math.abs(largest)) largest = area;
    }
    shapes.push(...path.toShapes(largest > 0));
    pen += glyph.advance + (glyph.kern || 0);
  }
  return shapes;
}

// Contours as closed polylines, for the sparks that run along them.
function contourPaths(shapes) {
  const paths = [];
  for (const shape of shapes) {
    for (const curve of [shape, ...shape.holes]) {
      const points = curve.getSpacedPoints(260);
      let length = 0;
      const lengths = [0];
      for (let i = 1; i < points.length; i++) {
        length += points[i].distanceTo(points[i - 1]);
        lengths.push(length);
      }
      paths.push({ points, lengths, length });
    }
  }
  return paths;
}

function pointAlong(path, fraction, out) {
  const target = (((fraction % 1) + 1) % 1) * path.length;
  const { lengths, points } = path;
  let lo = 0;
  let hi = lengths.length - 1;
  while (hi - lo > 1) {
    const mid = (lo + hi) >> 1;
    if (lengths[mid] < target) lo = mid; else hi = mid;
  }
  const span = lengths[hi] - lengths[lo] || 1;
  const k = (target - lengths[lo]) / span;
  out.set(
    points[lo].x + (points[hi].x - points[lo].x) * k,
    points[lo].y + (points[hi].y - points[lo].y) * k,
  );
  return out;
}

// A squared Euclidean distance transform (Felzenszwalb and Huttenlocher), in place.
function distanceTransform(grid, width, height) {
  const size = Math.max(width, height);
  const f = new Float64Array(size);
  const d = new Float64Array(size);
  const v = new Int32Array(size);
  const z = new Float64Array(size + 1);
  const line = (count) => {
    let k = 0;
    v[0] = 0;
    z[0] = -Infinity;
    z[1] = Infinity;
    for (let q = 1; q < count; q++) {
      let s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
      while (s <= z[k]) {
        k--;
        s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
      }
      k++;
      v[k] = q;
      z[k] = s;
      z[k + 1] = Infinity;
    }
    k = 0;
    for (let q = 0; q < count; q++) {
      while (z[k + 1] < q) k++;
      d[q] = (q - v[k]) * (q - v[k]) + f[v[k]];
    }
  };
  for (let x = 0; x < width; x++) {
    for (let y = 0; y < height; y++) f[y] = grid[y * width + x];
    line(height);
    for (let y = 0; y < height; y++) grid[y * width + x] = d[y];
  }
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) f[x] = grid[y * width + x];
    line(width);
    for (let x = 0; x < width; x++) grid[y * width + x] = d[x];
  }
}

// How far inside the strokes each point is, normalized to the deepest, as a texture over the
// mark's box: the blood's channel depth and, through its gradient, the direction of its flow.
function bakeField(shapes, center) {
  const contours = [];
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;
  for (const shape of shapes) {
    for (const curve of [shape, ...shape.holes]) {
      const points = curve.getPoints(24).map((p) => new THREE.Vector2(p.x - center.x, p.y - center.y));
      for (const p of points) {
        minX = Math.min(minX, p.x);
        minY = Math.min(minY, p.y);
        maxX = Math.max(maxX, p.x);
        maxY = Math.max(maxY, p.y);
      }
      contours.push(points);
    }
  }
  const margin = 0.02;
  const box = new THREE.Vector4(minX - margin, minY - margin, maxX - minX + 2 * margin, maxY - minY + 2 * margin);
  const width = 384;
  const height = Math.max(8, Math.round(width * box.w / box.z));
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const context = canvas.getContext('2d', { willReadFrequently: true });
  context.beginPath();
  for (const points of contours) {
    points.forEach((p, i) => {
      const x = ((p.x - box.x) / box.z) * width;
      const y = height - ((p.y - box.y) / box.w) * height;
      if (i === 0) context.moveTo(x, y); else context.lineTo(x, y);
    });
    context.closePath();
  }
  context.fill('evenodd');
  const pixels = context.getImageData(0, 0, width, height).data;
  const grid = new Float64Array(width * height);
  for (let i = 0; i < width * height; i++) grid[i] = pixels[i * 4 + 3] > 127 ? 1e20 : 0;
  distanceTransform(grid, width, height);
  let deepest = 1;
  for (let i = 0; i < grid.length; i++) {
    grid[i] = Math.sqrt(grid[i]);
    deepest = Math.max(deepest, grid[i]);
  }
  // Two box blurs round the ridge down each stroke's middle, where the gradient turns over.
  const blurred = new Float64Array(grid.length);
  for (let pass = 0; pass < 2; pass++) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        let sum = 0;
        let count = 0;
        for (let dy = -2; dy <= 2; dy++) {
          for (let dx = -2; dx <= 2; dx++) {
            const sx = x + dx;
            const sy = y + dy;
            if (sx < 0 || sy < 0 || sx >= width || sy >= height) continue;
            sum += grid[sy * width + sx];
            count++;
          }
        }
        blurred[y * width + x] = grid[y * width + x] > 0 ? sum / count : 0;
      }
    }
    grid.set(blurred);
  }
  // Half floats: eight bits leave steps in the gradient the flow follows. Canvas rows run top
  // down; texture rows bottom up.
  const data = new Uint16Array(width * height);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      data[(height - 1 - y) * width + x] = THREE.DataUtils.toHalfFloat(grid[y * width + x] / deepest);
    }
  }
  const texture = new THREE.DataTexture(data, width, height, THREE.RedFormat, THREE.HalfFloatType);
  texture.minFilter = THREE.LinearFilter;
  texture.magFilter = THREE.LinearFilter;
  texture.needsUpdate = true;
  return { texture, box, texel: new THREE.Vector2(2 / width, 2 / height) };
}

const NOISE = /* glsl */ `
  float hash31(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
  }
  float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
  }
  float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(
      mix(mix(hash31(i), hash31(i + vec3(1, 0, 0)), u.x),
          mix(hash31(i + vec3(0, 1, 0)), hash31(i + vec3(1, 1, 0)), u.x), u.y),
      mix(mix(hash31(i + vec3(0, 0, 1)), hash31(i + vec3(1, 0, 1)), u.x),
          mix(hash31(i + vec3(0, 1, 1)), hash31(i + vec3(1, 1, 1)), u.x), u.y),
      u.z);
  }
  float fbm3(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
      value += amplitude * noise3(p);
      p = p * 2.03 + vec3(11.7, 3.1, 5.9);
      amplitude *= 0.5;
    }
    return value;
  }
`;

// Shared by both glyph materials: the pointer lamp and the click ring.
const LAMP = /* glsl */ `
  uniform vec3 uPointer;
  uniform float uPresence;
  uniform float uReach;
  uniform vec4 uPulse;
  float lamp(vec3 world) {
    vec2 d = world.xy - uPointer.xy;
    return uPresence * exp(-dot(d, d) / (uReach * uReach));
  }
  float pulseRing(vec3 world) {
    float age = uPulse.w;
    if (age < 0.0 || age > 2.4) return 0.0;
    float radius = age * 1.35;
    float d = distance(world.xy, uPulse.xy);
    float ring = exp(-pow((d - radius) * 9.0, 2.0));
    return ring * (1.0 - age / 2.4);
  }
`;

const GLYPH_VERTEX = /* glsl */ `
  varying vec3 vWorld;
  varying vec3 vObject;
  varying vec3 vNormal;
  void main() {
    vec4 world = modelMatrix * vec4(position, 1.0);
    vWorld = world.xyz;
    vObject = position;
    vNormal = normalize(mat3(modelMatrix) * normal);
    gl_Position = projectionMatrix * viewMatrix * world;
  }
`;

const FACE_FRAGMENT = /* glsl */ `
  uniform float uTime;
  uniform vec3 uLight;
  uniform vec3 uDeep;
  uniform vec3 uMid;
  uniform vec3 uAccent;
  uniform sampler2D tField;
  uniform vec4 uFieldBox;
  uniform vec2 uFieldTexel;
  varying vec3 vWorld;
  varying vec3 vObject;
  varying vec3 vNormal;
  ${NOISE}
  ${LAMP}
  vec2 hash22(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
  }
  // Bubbles: the dome over the nearest bubble, 0 outside it. Only some cells hold one, and each
  // swells, holds and pops on its own clock, so they rise in ones and twos.
  float bubbles(vec2 p, float time) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    float dome = 0.0;
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec2 offset = vec2(float(i), float(j));
        vec2 h = hash22(cell + offset);
        if (h.y > 0.6) continue;
        float life = fract(time * (0.12 + 0.2 * h.y) + h.x * 7.0);
        float radius = (0.14 + 0.24 * h.x) * smoothstep(0.0, 0.35, life) * smoothstep(1.0, 0.9, life);
        float d = length(local - offset - 0.2 - 0.6 * h) / max(radius, 1e-3);
        dome = max(dome, sqrt(max(0.0, 1.0 - d * d)) * step(0.001, radius));
      }
    }
    return dome;
  }
  // The liquid: folds that boil slowly in place, with bubbles domed above them.
  vec2 liquid(vec2 p, float seed) {
    vec3 q = vec3(p, seed + uTime * 0.12);
    float fold = noise3(q) * 0.55 + noise3(q * 2.07 + 5.3) * 0.3 + noise3(q * 4.3 + 1.9) * 0.15;
    return vec2(fold, bubbles(p * 0.85 + seed * 7.1, uTime));
  }
  vec2 surface(vec2 p, vec2 current, float phase0, float phase1, float blend, float cycle) {
    vec2 a = liquid(p - current * phase0, floor(cycle) * 1.37);
    vec2 b = liquid(p - current * phase1, 3.1 + floor(cycle + 0.5) * 1.37);
    return mix(a, b, blend);
  }
  float heightOf(vec2 liquidSample) {
    return liquidSample.x * 0.7 + liquidSample.y * 0.55;
  }
  void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(cameraPosition - vWorld);
    vec3 l = normalize(uLight - vWorld);

    // The stroke's distance field: its value is how deep in the channel this point is, and its
    // gradient points across the stroke, so its perpendicular runs along it. The current is that
    // direction scaled by how steeply it falls, which is the same whichever way the
    // perpendicular points: blood runs down the verticals, pools on the level, and drags at the
    // banks.
    vec2 fuv = (vObject.xy - uFieldBox.xy) / uFieldBox.zw;
    float depth = texture2D(tField, fuv).r;
    vec2 across = vec2(
      texture2D(tField, fuv + vec2(uFieldTexel.x, 0.0)).r - texture2D(tField, fuv - vec2(uFieldTexel.x, 0.0)).r,
      texture2D(tField, fuv + vec2(0.0, uFieldTexel.y)).r - texture2D(tField, fuv - vec2(0.0, uFieldTexel.y)).r);
    float slopeAcross = length(across);
    vec2 along = slopeAcross > 1e-5 ? vec2(-across.y, across.x) / slopeAcross : vec2(0.0);
    // Where the gradient turns over, on the ridge down the middle, the current eases through
    // instead of jumping.
    float settled = smoothstep(0.002, 0.012, slopeAcross);
    vec2 current = -along * along.y * smoothstep(0.0, 0.4, depth) * mix(1.4, 2.2, settled) * settled;

    // Two layers advected along the current, each reset while the other carries the picture.
    float cycle = uTime * 0.16;
    float phase0 = fract(cycle);
    float phase1 = fract(cycle + 0.5);
    float blend = abs(phase0 - 0.5) * 2.0;
    vec2 p = vObject.xy * 6.5;
    vec2 here = surface(p, current, phase0, phase1, blend, cycle);
    float height = heightOf(here);

    // A wet surface: the height's slope bends the normal, so folds and bubble rims catch light.
    float e = 0.05;
    vec2 slope = vec2(
      heightOf(surface(p + vec2(e, 0.0), current, phase0, phase1, blend, cycle)) - height,
      heightOf(surface(p + vec2(0.0, e), current, phase0, phase1, blend, cycle)) - height) / e;
    vec3 wet = normalize(n - vec3(slope * 0.16, 0.0));
    vec3 h = normalize(l + v);

    // Deep purple blood: near black down the middle of the channel, rich in the risen folds,
    // and every bubble a glossy bead of the lighter purple.
    float fold = smoothstep(0.25, 0.8, here.x);
    vec3 blood = mix(uDeep * 0.45, uMid * 1.25, fold);
    blood = mix(blood, blood * 0.55, smoothstep(0.2, 1.0, depth) * (1.0 - fold * 0.6));
    blood = mix(blood, mix(uMid * 1.8, uAccent, 0.25), here.y * 0.55);

    // The lamp lightens the purple towards lavender and then pale lilac as it comes close,
    // keeping the liquid's own shading so a lit bubble is still a bead, not a blank disc.
    float near = lamp(vWorld);
    vec3 lit = mix(blood, uAccent * (0.75 + 0.35 * fold + 0.3 * here.y), clamp(near * 1.15, 0.0, 1.0));
    lit = mix(lit, mix(uAccent, vec3(1.0), 0.6), clamp(near * near * 0.3, 0.0, 1.0));

    float diffuse = max(dot(wet, l), 0.0);
    float specular = pow(max(dot(wet, h), 0.0), 70.0) * (0.3 + 0.9 * max(fold, here.y));
    float sheen = pow(max(dot(wet, h), 0.0), 9.0) * 0.16;
    float fresnel = pow(1.0 - max(dot(n, v), 0.0), 3.0);

    vec3 color = lit * (0.45 + 0.7 * diffuse)
      + vec3(1.0, 0.93, 1.0) * specular * 1.1
      + uAccent * sheen
      + uAccent * fresnel * 0.2
      + uAccent * near * 0.2
      + vec3(1.0, 0.9, 1.0) * pulseRing(vWorld) * 2.2;
    gl_FragColor = vec4(color, 1.0);
  }
`;

const SIDE_FRAGMENT = /* glsl */ `
  uniform float uTime;
  uniform vec3 uLight;
  uniform vec3 uAccent;
  uniform vec3 uMid;
  varying vec3 vWorld;
  varying vec3 vObject;
  varying vec3 vNormal;
  ${NOISE}
  ${LAMP}
  void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(cameraPosition - vWorld);
    vec3 l = normalize(uLight - vWorld);
    vec3 h = normalize(l + v);
    float facing = max(dot(n, v), 0.0);

    // Pearl: pale lavender with a thin-film shimmer that turns with the view.
    vec3 film = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.22, 0.45) + facing * 1.1 + uTime * 0.03));
    vec3 pearl = mix(mix(uAccent, vec3(1.0), 0.55), film, 0.18);
    float near = lamp(vWorld);
    pearl = mix(pearl, vec3(1.0), clamp(near * 0.8, 0.0, 1.0));

    float diffuse = max(dot(n, l), 0.0);
    float specular = pow(max(dot(n, h), 0.0), 60.0);
    // The walls stay dark enamel; only the bevel's crest, where it turns to face the viewer, is pearl.
    float crest = smoothstep(0.35, 0.92, facing);
    vec3 fq = vec3(vObject.x * 14.0, vObject.y * 8.0 - uTime * 2.1, uTime * 0.5);
    float fire = noise3(fq) * 0.6 + noise3(fq * 2.1) * 0.4;
    crest *= 0.72 + 0.6 * fire;
    vec3 wall = uMid * (0.25 + 0.55 * diffuse) + uAccent * near * 0.4;
    vec3 color = mix(wall, pearl * (0.75 + 0.6 * diffuse), crest)
      + vec3(1.0) * specular * 1.8
      + pearl * near * crest * 1.4
      + vec3(1.0, 0.9, 1.0) * pulseRing(vWorld) * 3.0;
    gl_FragColor = vec4(color, 1.0);
  }
`;

const NEBULA_FRAGMENT = /* glsl */ `
  uniform float uTime;
  uniform vec2 uResolution;
  uniform vec2 uLightScreen;
  uniform vec2 uPointerScreen;
  uniform float uPresence;
  uniform vec3 uBg;
  uniform vec3 uDeep;
  uniform vec3 uAccent;
  varying vec2 vUv;
  ${NOISE}
  void main() {
    float aspect = uResolution.x / uResolution.y;
    vec2 p = (vUv - 0.5) * vec2(aspect, 1.0);

    // Domain-warped fbm, two layers drifting apart.
    vec3 q = vec3(p * 1.6, uTime * 0.012);
    vec3 warp = vec3(fbm3(q + vec3(1.3, 0.0, 0.0)), fbm3(q + vec3(0.0, 4.2, 0.0)), 0.0);
    float cloud = fbm3(q * 1.3 + warp * 1.9);
    float wisps = fbm3(q * 3.1 - warp * 1.2 + vec3(0.0, 0.0, uTime * 0.02));
    float density = smoothstep(0.38, 0.95, cloud) * (0.6 + 0.6 * wisps);

    vec2 lightP = (uLightScreen - 0.5) * vec2(aspect, 1.0);
    vec2 pointerP = (uPointerScreen - 0.5) * vec2(aspect, 1.0);
    float byLight = exp(-2.2 * length(p - lightP));
    float byPointer = uPresence * exp(-6.0 * length(p - pointerP));

    vec3 color = uBg;
    color += uDeep * density * 1.4;
    color += uAccent * density * (0.18 + 0.9 * byLight + 0.5 * byPointer);
    color += uAccent * byLight * 0.08;
    // Alpha carries the density, so the stars can sink into the clouds.
    gl_FragColor = vec4(color, density);
  }
`;

const SKY_FRAGMENT = /* glsl */ `
  uniform float uTime;
  uniform vec2 uResolution;
  uniform sampler2D tNebula;
  varying vec2 vUv;
  float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
  }
  float stars(vec2 p, float scale, float threshold) {
    vec2 cell = floor(p * scale);
    vec2 local = fract(p * scale) - 0.5;
    float h = hash21(cell);
    if (h < threshold) return 0.0;
    vec2 offset = vec2(hash21(cell + 7.1), hash21(cell + 3.3)) - 0.5;
    float d = length(local - offset * 0.7);
    float twinkle = 0.55 + 0.45 * sin(uTime * (1.0 + h * 3.0) + h * 40.0);
    return smoothstep(0.08, 0.0, d) * twinkle * (h - threshold) / (1.0 - threshold);
  }
  void main() {
    float aspect = uResolution.x / uResolution.y;
    vec2 p = (vUv - 0.5) * vec2(aspect, 1.0);
    vec4 nebula = texture2D(tNebula, vUv);
    vec3 color = nebula.rgb;
    float density = nebula.a;
    float starField = stars(p + vec2(uTime * 0.002, 0.0), 90.0, 0.93)
      + 0.6 * stars(p * 1.7 + 4.0, 160.0, 0.95)
      + 1.4 * stars(p * 0.6 + 9.0, 40.0, 0.975);
    color += vec3(0.9, 0.85, 1.0) * starField * (1.0 - density * 0.6);
    gl_FragColor = vec4(color, 1.0);
  }
`;

// Flames: ribbons laid outward from every contour, shaded with rising turbulence into tongues
// that are white at the rim and pale accent at their tips.
const FLAME_VERTEX = /* glsl */ `
  attribute float aOut;
  varying vec3 vWorld;
  varying vec3 vLocal;
  varying float vOut;
  void main() {
    vOut = aOut;
    vLocal = position;
    vec4 world = modelMatrix * vec4(position, 1.0);
    vWorld = world.xyz;
    gl_Position = projectionMatrix * viewMatrix * world;
  }
`;

const FLAME_FRAGMENT = /* glsl */ `
  uniform float uTime;
  uniform vec3 uAccent;
  varying vec3 vWorld;
  varying vec3 vLocal;
  varying float vOut;
  ${NOISE}
  ${LAMP}
  void main() {
    float near = lamp(vWorld);
    // Each column along the edge gets its own tongue height, which rises and falls; inside it,
    // upright turbulence advected upward and curled sideways gives the streaks and the flicker.
    float column = noise3(vec3(vLocal.x * 17.0, vLocal.y * 17.0, uTime * 1.4));
    vec3 q = vec3(vLocal.x * 13.0, vLocal.y * 2.8 - uTime * 2.7, uTime * 0.5);
    q.x += 1.7 * (fbm3(vec3(vLocal.xy * 2.4, uTime * 0.4)) - 0.5);
    float turbulence = fbm3(q);
    float streaks = 1.0 - abs(noise3(q * vec3(1.8, 0.6, 1.0)) * 2.0 - 1.0);
    float heat = clamp(column * 0.8 + turbulence * 1.1 + streaks * 0.25 - 0.7, 0.0, 1.0) * (0.6 + 0.9 * near);
    float tongue = smoothstep(0.0, 0.2, heat - vOut) * (0.55 + 0.45 * streaks);
    float core = smoothstep(0.0, 0.25, heat * 0.5 - vOut);
    float rim = exp(-vOut * 22.0);
    float flicker = 0.8 + 0.2 * noise3(vec3(vLocal.xy * 4.0, uTime * 7.0));
    float tip = pow(1.0 - vOut, 1.2);
    vec3 pale = mix(uAccent, vec3(1.0), 0.35);
    vec3 color = pale * tongue * 0.5 * streaks + vec3(1.0, 0.97, 1.0) * core * 1.0 + pale * rim * 0.35;
    gl_FragColor = vec4(color * tip * flicker * (1.0 + near * 1.2), 1.0);
  }
`;

const FULLSCREEN_VERTEX = /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = vec4(position.xy, 0.0, 1.0);
  }
`;

const SPARK_VERTEX = /* glsl */ `
  attribute float aBright;
  attribute float aSize;
  uniform float uPixelRatio;
  uniform float uScale;
  varying float vBright;
  void main() {
    vBright = aBright;
    vec4 view = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = aSize * uScale * uPixelRatio / -view.z;
    gl_Position = projectionMatrix * view;
  }
`;

const SPARK_FRAGMENT = /* glsl */ `
  uniform vec3 uAccent;
  varying float vBright;
  void main() {
    vec2 p = gl_PointCoord - 0.5;
    float r = length(p);
    float core = exp(-r * r * 90.0);
    float cross = exp(-abs(p.x) * 60.0) * exp(-abs(p.y) * 7.0) + exp(-abs(p.y) * 60.0) * exp(-abs(p.x) * 7.0);
    float glow = exp(-r * r * 14.0) * 0.35;
    float a = (core + cross * 0.6 + glow) * vBright;
    gl_FragColor = vec4(mix(uAccent, vec3(1.0), 0.75) * a * 3.0, 1.0);
  }
`;

const MOTE_VERTEX = /* glsl */ `
  attribute vec3 aSeed;
  uniform float uTime;
  uniform float uPixelRatio;
  varying float vAlpha;
  void main() {
    vec3 p = position;
    p.y = mod(p.y + uTime * (0.03 + aSeed.x * 0.05) + 3.0, 6.0) - 3.0;
    p.x += sin(uTime * 0.3 + aSeed.y * 6.28) * 0.12;
    vec4 view = modelViewMatrix * vec4(p, 1.0);
    gl_PointSize = (1.2 + aSeed.z * 2.6) * uPixelRatio * 7.0 / -view.z;
    vAlpha = (0.25 + 0.75 * aSeed.z) * smoothstep(3.0, 2.2, abs(p.y));
    gl_Position = projectionMatrix * view;
  }
`;

const MOTE_FRAGMENT = /* glsl */ `
  uniform vec3 uAccent;
  varying float vAlpha;
  void main() {
    float r = length(gl_PointCoord - 0.5);
    float a = smoothstep(0.5, 0.0, r) * vAlpha;
    gl_FragColor = vec4(mix(uAccent, vec3(1.0), 0.4) * a * 0.7, 1.0);
  }
`;

const FLARE_VERTEX = /* glsl */ `
  uniform vec2 uCenter;
  uniform float uSize;
  uniform float uAspect;
  varying vec2 vUv;
  void main() {
    vUv = uv;
    vec2 p = uCenter + position.xy * uSize * vec2(1.0 / uAspect, 1.0);
    gl_Position = vec4(p, 0.0, 1.0);
  }
`;

const FLARE_FRAGMENT = /* glsl */ `
  uniform int uShape;
  uniform vec3 uColor;
  uniform float uAlpha;
  uniform float uTime;
  varying vec2 vUv;
  void main() {
    vec2 p = vUv * 2.0 - 1.0;
    float r = length(p);
    float value = 0.0;
    if (uShape == 0) {
      value = exp(-r * r * 9.0) + 0.35 * exp(-r * 3.2);
    } else if (uShape == 1) {
      value = exp(-pow((r - 0.78) * 14.0, 2.0)) * 0.9 + exp(-r * r * 3.0) * 0.08;
    } else if (uShape == 2) {
      // A hexagonal aperture ghost with a soft edge.
      vec2 a = abs(p);
      float hex = max(a.x * 0.866 + a.y * 0.5, a.y);
      value = smoothstep(0.82, 0.62, hex) * (0.55 + 0.45 * smoothstep(0.2, 0.75, hex));
    } else {
      // A long anamorphic streak with a fainter vertical spike and a slow shimmer.
      float horizontal = exp(-abs(p.y) * 70.0) * exp(-abs(p.x) * 1.8);
      float vertical = exp(-abs(p.x) * 90.0) * exp(-abs(p.y) * 4.0) * 0.5;
      float diagonal = exp(-abs(p.x - p.y) * 80.0) * exp(-r * 4.5) * 0.3 + exp(-abs(p.x + p.y) * 80.0) * exp(-r * 4.5) * 0.3;
      value = (horizontal + vertical + diagonal) * (0.85 + 0.15 * sin(uTime * 1.7));
    }
    vec2 edge = abs(vUv * 2.0 - 1.0);
    value *= smoothstep(1.0, 0.72, max(edge.x, edge.y));
    gl_FragColor = vec4(uColor * value * uAlpha, 1.0);
  }
`;

const BRIGHT_FRAGMENT = /* glsl */ `
  uniform sampler2D tInput;
  uniform float uThreshold;
  varying vec2 vUv;
  void main() {
    vec3 c = texture2D(tInput, vUv).rgb;
    float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
    gl_FragColor = vec4(c * smoothstep(uThreshold, uThreshold + 0.6, luma), 1.0);
  }
`;

const BLUR_FRAGMENT = /* glsl */ `
  uniform sampler2D tInput;
  uniform vec2 uDirection;
  varying vec2 vUv;
  void main() {
    vec3 sum = texture2D(tInput, vUv).rgb * 0.2270270270;
    sum += texture2D(tInput, vUv + uDirection * 1.3846153846).rgb * 0.3162162162;
    sum += texture2D(tInput, vUv - uDirection * 1.3846153846).rgb * 0.3162162162;
    sum += texture2D(tInput, vUv + uDirection * 3.2307692308).rgb * 0.0702702703;
    sum += texture2D(tInput, vUv - uDirection * 3.2307692308).rgb * 0.0702702703;
    gl_FragColor = vec4(sum, 1.0);
  }
`;

const COMPOSITE_FRAGMENT = /* glsl */ `
  uniform sampler2D tScene;
  uniform sampler2D tBloomNear;
  uniform sampler2D tBloomFar;
  uniform float uTime;
  varying vec2 vUv;
  vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
  }
  float dither(vec2 p) {
    return fract(sin(dot(p + fract(uTime), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
  }
  void main() {
    vec3 color = texture2D(tScene, vUv).rgb;
    color += texture2D(tBloomNear, vUv).rgb * 0.9 + texture2D(tBloomFar, vUv).rgb * 0.7;
    vec2 d = vUv - 0.5;
    color *= 1.0 - dot(d, d) * 0.9;
    color = aces(color * 1.05);
    color = pow(color, vec3(1.0 / 2.2));
    color += dither(gl_FragCoord.xy) / 255.0;
    gl_FragColor = vec4(color, 1.0);
  }
`;

function fullscreenMaterial(fragmentShader, uniforms) {
  return new THREE.ShaderMaterial({
    vertexShader: FULLSCREEN_VERTEX,
    fragmentShader,
    uniforms,
    depthTest: false,
    depthWrite: false,
  });
}

function mount(root) {
  const stage = root.querySelector('[data-st4sh-hero-stage]');
  const anchor = root.querySelector('[data-st4sh-hero-anchor]');
  if (!stage || !anchor) return;

  const canvas = document.createElement('canvas');
  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, powerPreference: 'high-performance' });
  } catch {
    return;
  }
  if (!renderer.capabilities.isWebGL2) {
    renderer.dispose();
    return;
  }
  renderer.autoClear = false;
  renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
  canvas.className = 'st4sh-hero__canvas';
  canvas.setAttribute('aria-hidden', 'true');
  stage.append(canvas);

  const floatTargets = renderer.extensions.has('EXT_color_buffer_float') || renderer.extensions.has('EXT_color_buffer_half_float');
  const targetType = floatTargets ? THREE.HalfFloatType : THREE.UnsignedByteType;
  const makeTarget = () => new THREE.WebGLRenderTarget(1, 1, { type: targetType, depthBuffer: false });
  const sceneTarget = new THREE.WebGLRenderTarget(1, 1, { type: targetType, samples: 4 });
  const bloomTargets = [makeTarget(), makeTarget(), makeTarget(), makeTarget()];

  // Palette, from the site's tokens.
  const accent = cssColor('--dw-accent', '#c6a0f6');
  const bg = cssColor('--dw-bg-0', '#0b0710').multiplyScalar(0.55);
  const deep = cssColor('--st4sh-enamel-deep', '#12031c');
  const mid = cssColor('--st4sh-enamel', '#3f0f5e');

  const camera = new THREE.PerspectiveCamera(32, 1, 0.1, 60);
  camera.position.set(0, 0, 10);

  const scene = new THREE.Scene();
  const overlay = new THREE.Scene();
  const quad = new THREE.PlaneGeometry(2, 2);

  const shared = {
    uTime: { value: 0 },
    uPointer: { value: new THREE.Vector3(99, 99, 0) },
    uPresence: { value: 0 },
    uReach: { value: 0.5 },
    uPulse: { value: new THREE.Vector4(0, 0, 0, -1) },
    uLight: { value: new THREE.Vector3() },
    uAccent: { value: accent },
    uDeep: { value: deep },
    uMid: { value: mid },
  };

  // Sky.
  const skyUniforms = {
    uTime: shared.uTime,
    uResolution: { value: new THREE.Vector2(1, 1) },
    uLightScreen: { value: new THREE.Vector2(0.7, 0.7) },
    uPointerScreen: { value: new THREE.Vector2(-1, -1) },
    uPresence: shared.uPresence,
    uBg: { value: bg },
    uDeep: { value: deep },
    uAccent: { value: accent },
  };
  const nebulaTarget = new THREE.WebGLRenderTarget(1, 1, { type: targetType, depthBuffer: false });
  const nebulaMaterial = fullscreenMaterial(NEBULA_FRAGMENT, skyUniforms);
  const sky = new THREE.Mesh(quad, fullscreenMaterial(SKY_FRAGMENT, {
    uTime: shared.uTime,
    uResolution: skyUniforms.uResolution,
    tNebula: { value: nebulaTarget.texture },
  }));
  sky.frustumCulled = false;
  sky.renderOrder = -10;
  scene.add(sky);

  // The mark.
  const shapes = glyphShapes();
  const geometry = new THREE.ExtrudeGeometry(shapes, {
    depth: DEPTH,
    bevelEnabled: true,
    bevelThickness: BEVEL.thickness,
    bevelSize: BEVEL.size,
    bevelSegments: BEVEL.segments,
    curveSegments: 18,
  });
  geometry.computeBoundingBox();
  const box = geometry.boundingBox;
  const center = box.getCenter(new THREE.Vector3());
  geometry.translate(-center.x, -center.y, -center.z);
  const markSize = box.getSize(new THREE.Vector3());
  const frontZ = markSize.z / 2;

  const field = bakeField(shapes, center);
  const faceMaterial = new THREE.ShaderMaterial({
    vertexShader: GLYPH_VERTEX,
    fragmentShader: FACE_FRAGMENT,
    uniforms: {
      ...shared,
      tField: { value: field.texture },
      uFieldBox: { value: field.box },
      uFieldTexel: { value: field.texel },
    },
  });
  const sideMaterial = new THREE.ShaderMaterial({ vertexShader: GLYPH_VERTEX, fragmentShader: SIDE_FRAGMENT, uniforms: shared });
  const mark = new THREE.Mesh(geometry, [faceMaterial, sideMaterial]);
  const pivot = new THREE.Group();
  pivot.add(mark);
  scene.add(pivot);

  // Sparks on the front edge of every contour.
  const paths = contourPaths(shapes);
  const totalLength = paths.reduce((sum, p) => sum + p.length, 0);
  const sparks = [];
  for (let i = 0; i < SPARKS; i++) {
    // Longer contours get more sparks.
    let pick = Math.random() * totalLength;
    let pathIndex = 0;
    while (pick > paths[pathIndex].length && pathIndex < paths.length - 1) {
      pick -= paths[pathIndex].length;
      pathIndex++;
    }
    sparks.push({
      path: paths[pathIndex],
      at: Math.random(),
      speed: (0.012 + Math.random() * 0.03) * (Math.random() < 0.5 ? -1 : 1),
      phase: Math.random() * Math.PI * 2,
      size: 0.6 + Math.random() * 1.2,
    });
  }
  const sparkPositions = new Float32Array(SPARKS * 3);
  const sparkBright = new Float32Array(SPARKS);
  const sparkSize = new Float32Array(SPARKS);
  const sparkGeometry = new THREE.BufferGeometry();
  sparkGeometry.setAttribute('position', new THREE.BufferAttribute(sparkPositions, 3));
  sparkGeometry.setAttribute('aBright', new THREE.BufferAttribute(sparkBright, 1));
  sparkGeometry.setAttribute('aSize', new THREE.BufferAttribute(sparkSize, 1));
  const sparkUniforms = { uPixelRatio: { value: 1 }, uScale: { value: 60 }, uAccent: shared.uAccent };
  const sparkPoints = new THREE.Points(sparkGeometry, new THREE.ShaderMaterial({
    vertexShader: SPARK_VERTEX,
    fragmentShader: SPARK_FRAGMENT,
    uniforms: sparkUniforms,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    transparent: true,
  }));
  sparkPoints.frustumCulled = false;
  mark.add(sparkPoints);

  // Flame ribbons, one per contour, pointing away from the solid: out of an outline, into a
  // counter. Top edges burn tallest.
  const flamePositions = [];
  const flameOut = [];
  const flameIndex = [];
  let flameVertex = 0;
  for (const shape of shapes) {
    for (const [curve, isHole] of [[shape, false], ...shape.holes.map((hole) => [hole, true])]) {
      const points = curve.getSpacedPoints(320);
      points.pop();
      let area = 0;
      for (let i = 0; i < points.length; i++) {
        const a = points[i];
        const b = points[(i + 1) % points.length];
        area += a.x * b.y - b.x * a.y;
      }
      const away = (isHole ? area > 0 : area < 0) ? 1 : -1;
      const count = points.length;
      for (let i = 0; i <= count; i++) {
        const p = points[i % count];
        const prev = points[(i - 6 + count) % count];
        const next = points[(i + 6) % count];
        let nx = -(next.y - prev.y) * away;
        let ny = (next.x - prev.x) * away;
        const length = Math.hypot(nx, ny) || 1;
        nx /= length;
        ny /= length;
        const reach = FLAME_REACH * (0.4 + 0.9 * Math.max(0, ny)) * (isHole ? 0.35 : 1);
        flamePositions.push(p.x - center.x, p.y - center.y, 0, p.x - center.x + nx * reach, p.y - center.y + ny * reach, 0);
        flameOut.push(0, 1);
        if (i < count) {
          const a = flameVertex + i * 2;
          flameIndex.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
        }
      }
      flameVertex += (count + 1) * 2;
    }
  }
  const flameGeometry = new THREE.BufferGeometry();
  flameGeometry.setAttribute('position', new THREE.Float32BufferAttribute(flamePositions, 3));
  flameGeometry.setAttribute('aOut', new THREE.Float32BufferAttribute(flameOut, 1));
  flameGeometry.setIndex(flameIndex);
  // Max blending: where ribbons overlap in a concave curve they must not add up into stripes.
  const flames = new THREE.Mesh(flameGeometry, new THREE.ShaderMaterial({
    vertexShader: FLAME_VERTEX,
    fragmentShader: FLAME_FRAGMENT,
    uniforms: shared,
    blending: THREE.CustomBlending,
    blendEquation: THREE.MaxEquation,
    blendSrc: THREE.OneFactor,
    blendDst: THREE.OneFactor,
    depthWrite: false,
    transparent: true,
    side: THREE.DoubleSide,
  }));
  flames.frustumCulled = false;
  mark.add(flames);

  // Dust.
  const motePositions = new Float32Array(MOTES * 3);
  const moteSeeds = new Float32Array(MOTES * 3);
  for (let i = 0; i < MOTES; i++) {
    motePositions[i * 3] = (Math.random() - 0.5) * 9;
    motePositions[i * 3 + 1] = (Math.random() - 0.5) * 6;
    motePositions[i * 3 + 2] = (Math.random() - 0.5) * 5 - 0.5;
    moteSeeds[i * 3] = Math.random();
    moteSeeds[i * 3 + 1] = Math.random();
    moteSeeds[i * 3 + 2] = Math.random() ** 3;
  }
  const moteGeometry = new THREE.BufferGeometry();
  moteGeometry.setAttribute('position', new THREE.BufferAttribute(motePositions, 3));
  moteGeometry.setAttribute('aSeed', new THREE.BufferAttribute(moteSeeds, 3));
  const moteUniforms = { uTime: shared.uTime, uPixelRatio: sparkUniforms.uPixelRatio, uAccent: shared.uAccent };
  const motes = new THREE.Points(moteGeometry, new THREE.ShaderMaterial({
    vertexShader: MOTE_VERTEX,
    fragmentShader: MOTE_FRAGMENT,
    uniforms: moteUniforms,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    transparent: true,
  }));
  motes.frustumCulled = false;
  scene.add(motes);

  // Lens flare, drawn in screen space over everything.
  const flares = FLARE_ELEMENTS.map((element) => {
    const material = new THREE.ShaderMaterial({
      vertexShader: FLARE_VERTEX,
      fragmentShader: FLARE_FRAGMENT,
      uniforms: {
        uCenter: { value: new THREE.Vector2() },
        uSize: { value: element.size },
        uAspect: { value: 1 },
        uShape: { value: element.shape },
        uColor: { value: new THREE.Color().setRGB(...element.color).multiply(accent.clone().lerp(new THREE.Color(1, 1, 1), 0.5)) },
        uAlpha: { value: element.alpha },
        uTime: shared.uTime,
      },
      blending: THREE.AdditiveBlending,
      depthTest: false,
      depthWrite: false,
      transparent: true,
    });
    const mesh = new THREE.Mesh(quad, material);
    mesh.frustumCulled = false;
    overlay.add(mesh);
    return { element, material };
  });

  // Post: bright pass, blur, composite.
  const post = new THREE.Scene();
  const postCamera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  const postQuad = new THREE.Mesh(quad);
  postQuad.frustumCulled = false;
  post.add(postQuad);
  const brightMaterial = fullscreenMaterial(BRIGHT_FRAGMENT, { tInput: { value: null }, uThreshold: { value: 0.7 } });
  const blurMaterial = fullscreenMaterial(BLUR_FRAGMENT, { tInput: { value: null }, uDirection: { value: new THREE.Vector2() } });
  const compositeMaterial = fullscreenMaterial(COMPOSITE_FRAGMENT, {
    tScene: { value: sceneTarget.texture },
    tBloomNear: { value: bloomTargets[0].texture },
    tBloomFar: { value: bloomTargets[2].texture },
    uTime: shared.uTime,
  });

  function pass(material, target) {
    postQuad.material = material;
    renderer.setRenderTarget(target);
    renderer.render(post, postCamera);
  }

  function blur(source, via, target, radius) {
    blurMaterial.uniforms.tInput.value = source.texture;
    blurMaterial.uniforms.uDirection.value.set(radius / source.width, 0);
    pass(blurMaterial, via);
    blurMaterial.uniforms.tInput.value = via.texture;
    blurMaterial.uniforms.uDirection.value.set(0, radius / via.height);
    pass(blurMaterial, target);
  }

  // Layout: the mark fills the anchor's box; the canvas fills the stage.
  let width = 1;
  let height = 1;
  let nebulaAge = Infinity;
  // Resolution scale, lowered a step whenever frames run slow for a while.
  let quality = 1;
  let slowTime = 0;
  const worldAnchor = new THREE.Vector3();
  let markScale = 1;
  const tmp = new THREE.Vector3();

  function worldPerPixel() {
    const visible = 2 * camera.position.z * Math.tan(THREE.MathUtils.degToRad(camera.fov / 2));
    return visible / height;
  }

  function layout() {
    const stageBox = stage.getBoundingClientRect();
    const anchorBox = anchor.getBoundingClientRect();
    width = Math.max(1, Math.round(stageBox.width));
    height = Math.max(1, Math.round(stageBox.height));
    const ratio = Math.min(window.devicePixelRatio || 1, 1.5) * quality;
    renderer.setPixelRatio(ratio);
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();

    const w = Math.round(width * ratio);
    const h = Math.round(height * ratio);
    sceneTarget.setSize(w, h);
    bloomTargets[0].setSize(Math.max(1, w >> 2), Math.max(1, h >> 2));
    bloomTargets[1].setSize(Math.max(1, w >> 2), Math.max(1, h >> 2));
    bloomTargets[2].setSize(Math.max(1, w >> 3), Math.max(1, h >> 3));
    bloomTargets[3].setSize(Math.max(1, w >> 3), Math.max(1, h >> 3));
    skyUniforms.uResolution.value.set(w, h);
    nebulaTarget.setSize(Math.max(1, w >> 1), Math.max(1, h >> 1));
    nebulaAge = Infinity;
    sparkUniforms.uPixelRatio.value = ratio;
    sparkUniforms.uScale.value = height * 0.09;
    for (const { material } of flares) material.uniforms.uAspect.value = width / height;

    const perPixel = worldPerPixel();
    const cx = anchorBox.left + anchorBox.width / 2 - stageBox.left;
    const cy = anchorBox.top + anchorBox.height / 2 - stageBox.top;
    // The mark and the flames above it fit the anchor together: the mark sits lower by half their
    // height, so the tongues burn inside the box instead of past its top.
    markScale = Math.min((anchorBox.width * perPixel) / markSize.x, (anchorBox.height * perPixel) / (markSize.y + FLAME_OVERHANG)) * 0.9;
    worldAnchor.set((cx - width / 2) * perPixel, -(cy - height / 2) * perPixel - (FLAME_OVERHANG * markScale) / 2, 0);
    pivot.position.copy(worldAnchor);
    pivot.scale.setScalar(markScale);
    shared.uReach.value = 0.32 * markScale;
  }

  // The pointer lamp.
  const pointerNdc = new THREE.Vector2(0, 0);
  const pointerTarget = new THREE.Vector3();
  const raycaster = new THREE.Raycaster();
  const plane = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0);
  let pointerActive = false;
  let lastPointer = -Infinity;
  let presence = 0;
  const tilt = new THREE.Vector2();

  function onPointer(event) {
    const bounds = stage.getBoundingClientRect();
    pointerNdc.set(
      ((event.clientX - bounds.left) / bounds.width) * 2 - 1,
      -((event.clientY - bounds.top) / bounds.height) * 2 + 1,
    );
    pointerActive = true;
    lastPointer = performance.now();
    if (reduceMotion) requestFrame();
  }
  function onLeave() {
    pointerActive = false;
    if (reduceMotion) requestFrame();
  }
  function onPress(event) {
    onPointer(event);
    raycaster.setFromCamera(pointerNdc, camera);
    plane.constant = -(worldAnchor.z + frontZ * markScale);
    if (raycaster.ray.intersectPlane(plane, tmp)) {
      shared.uPulse.value.set(tmp.x, tmp.y, tmp.z, 0);
      for (const spark of sparks) spark.boost = 1;
    }
  }
  root.addEventListener('pointermove', onPointer, { passive: true });
  root.addEventListener('pointerdown', onPress, { passive: true });
  root.addEventListener('pointerleave', onLeave, { passive: true });

  // The render loop.
  const clock = new THREE.Clock();
  let time = reduceMotion ? 12.0 : 0;
  let visible = false;
  let running = false;
  let first = true;
  const projected = new THREE.Vector3();
  const lightLocal = new THREE.Vector3();

  function frame() {
    running = false;
    const rawDt = clock.getDelta();
    const dt = Math.min(rawDt, 0.05);
    if (!reduceMotion && rawDt < 0.5) {
      slowTime = rawDt > 1 / 40 ? slowTime + rawDt : Math.max(0, slowTime - rawDt * 0.5);
      if (slowTime > 1.5 && quality > 0.5) {
        quality = Math.max(0.5, quality - 0.2);
        slowTime = 0;
        layout();
      }
    }
    if (!reduceMotion) time += dt;
    shared.uTime.value = time;

    // Where the lamp is: the pointer while it's over the hero, a slow wander otherwise.
    const idle = !pointerActive || performance.now() - lastPointer > 4000;
    if (idle && !reduceMotion) {
      pointerNdc.set(
        worldAnchor.x / (camera.aspect * camera.position.z * Math.tan(THREE.MathUtils.degToRad(camera.fov / 2))) + Math.sin(time * 0.37) * 0.28,
        worldAnchor.y / (camera.position.z * Math.tan(THREE.MathUtils.degToRad(camera.fov / 2))) + Math.sin(time * 0.53 + 1.1) * 0.22,
      );
    }
    raycaster.setFromCamera(pointerNdc, camera);
    plane.constant = -(worldAnchor.z + frontZ * markScale);
    if (raycaster.ray.intersectPlane(plane, tmp)) pointerTarget.copy(tmp);
    const wanted = pointerActive ? 1 : (reduceMotion ? 0 : 0.32);
    presence += (wanted - presence) * (reduceMotion ? 1 : Math.min(1, dt * 4));
    shared.uPresence.value = presence;
    const follow = reduceMotion ? 1 : Math.min(1, dt * 9);
    shared.uPointer.value.lerp(pointerTarget, follow);
    skyUniforms.uPointerScreen.value.set(pointerNdc.x * 0.5 + 0.5, pointerNdc.y * 0.5 + 0.5);

    // The mark turns towards the lamp, and breathes.
    const dx = (shared.uPointer.value.x - worldAnchor.x) / Math.max(markScale, 0.001);
    const dy = (shared.uPointer.value.y - worldAnchor.y) / Math.max(markScale, 0.001);
    tilt.x += (THREE.MathUtils.clamp(-dy * 0.35, -0.35, 0.35) - tilt.x) * follow * 0.5;
    tilt.y += (THREE.MathUtils.clamp(dx * 0.3, -0.42, 0.42) - tilt.y) * follow * 0.5;
    pivot.rotation.set(tilt.x + Math.sin(time * 0.6) * 0.03, tilt.y + Math.sin(time * 0.41) * 0.05, Math.sin(time * 0.3) * 0.012);
    pivot.position.set(worldAnchor.x, worldAnchor.y + Math.sin(time * 0.8) * 0.02 * markScale, worldAnchor.z);

    // The key light and flare sit above the 3's shoulder, drifting a little.
    lightLocal.set(markSize.x * 0.47, markSize.y * 0.47, frontZ + 0.08);
    lightLocal.x += Math.sin(time * 0.23) * 0.03;
    lightLocal.y += Math.cos(time * 0.29) * 0.02;
    pivot.updateMatrixWorld(true);
    shared.uLight.value.copy(lightLocal).applyMatrix4(pivot.matrixWorld);
    projected.copy(shared.uLight.value).project(camera);
    skyUniforms.uLightScreen.value.set(projected.x * 0.5 + 0.5, projected.y * 0.5 + 0.5);
    const onScreen = Math.abs(projected.x) < 1.2 && Math.abs(projected.y) < 1.2 ? 1 : 0;
    for (const { element, material } of flares) {
      material.uniforms.uCenter.value.set(projected.x * (1 - element.t), projected.y * (1 - element.t));
      material.uniforms.uSize.value = element.size * (0.9 + 0.1 * Math.sin(time * 1.3 + element.t * 5)) * (0.55 + 0.45 * Math.min(1, width / 900));
      material.uniforms.uAlpha.value = element.alpha * onScreen;
    }

    // Sparks run along their contours, brightest near the lamp and after a click.
    const lampLocal = tmp.copy(shared.uPointer.value);
    mark.worldToLocal(lampLocal);
    const point = new THREE.Vector2();
    const pulseAge = shared.uPulse.value.w;
    for (let i = 0; i < SPARKS; i++) {
      const spark = sparks[i];
      const boost = spark.boost || 0;
      spark.at += spark.speed * dt * (1 + boost * 6);
      spark.boost = boost * Math.max(0, 1 - dt * 1.5);
      pointAlong(spark.path, spark.at, point);
      sparkPositions[i * 3] = point.x - center.x;
      sparkPositions[i * 3 + 1] = point.y - center.y;
      sparkPositions[i * 3 + 2] = frontZ + 0.004;
      const dxs = point.x - center.x - lampLocal.x;
      const dys = point.y - center.y - lampLocal.y;
      const nearLamp = presence * Math.exp(-(dxs * dxs + dys * dys) / 0.08);
      const twinkle = 0.35 + 0.65 * Math.max(0, Math.sin(time * 2.2 + spark.phase)) ** 6;
      sparkBright[i] = Math.min(2.5, twinkle + nearLamp * 1.8 + boost * 1.5);
      sparkSize[i] = spark.size * (1 + nearLamp * 0.8 + boost);
    }
    sparkGeometry.attributes.position.needsUpdate = true;
    sparkGeometry.attributes.aBright.needsUpdate = true;
    sparkGeometry.attributes.aSize.needsUpdate = true;
    if (pulseAge >= 0) shared.uPulse.value.w = pulseAge + dt * (reduceMotion ? 0 : 1);
    if (shared.uPulse.value.w > 2.4) shared.uPulse.value.w = -1;

    // Render. The nebula drifts slowly enough to redraw every third frame at half resolution.
    nebulaAge++;
    if (nebulaAge >= 3 || reduceMotion) {
      nebulaAge = 0;
      pass(nebulaMaterial, nebulaTarget);
    }
    renderer.setRenderTarget(sceneTarget);
    renderer.clear();
    renderer.render(scene, camera);
    renderer.render(overlay, camera);

    // Near bloom at a quarter of the resolution, far bloom at an eighth, each blurred twice.
    brightMaterial.uniforms.tInput.value = sceneTarget.texture;
    pass(brightMaterial, bloomTargets[0]);
    blur(bloomTargets[0], bloomTargets[1], bloomTargets[0], 1.0);
    blur(bloomTargets[0], bloomTargets[1], bloomTargets[0], 2.0);
    pass(fullscreenCopy(bloomTargets[0]), bloomTargets[2]);
    blur(bloomTargets[2], bloomTargets[3], bloomTargets[2], 1.5);
    blur(bloomTargets[2], bloomTargets[3], bloomTargets[2], 3.0);

    renderer.setRenderTarget(null);
    pass(compositeMaterial, null);

    if (first) {
      first = false;
      root.classList.add('is-live');
    }
    if (visible && !reduceMotion && !document.hidden) requestFrame();
  }

  const copyMaterial = fullscreenMaterial(/* glsl */ `
    uniform sampler2D tInput;
    varying vec2 vUv;
    void main() { gl_FragColor = texture2D(tInput, vUv); }
  `, { tInput: { value: null } });
  function fullscreenCopy(source) {
    copyMaterial.uniforms.tInput.value = source.texture;
    return copyMaterial;
  }

  function requestFrame() {
    if (running) return;
    running = true;
    requestAnimationFrame(frame);
  }

  layout();
  new ResizeObserver(() => {
    layout();
    requestFrame();
  }).observe(root);
  new IntersectionObserver((entries) => {
    visible = entries.some((entry) => entry.isIntersecting);
    if (visible) {
      clock.getDelta();
      requestFrame();
    }
  }).observe(root);
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && visible) {
      clock.getDelta();
      requestFrame();
    }
  });
}

for (const root of document.querySelectorAll('[data-st4sh-hero]')) mount(root);
