// =====================
// OpenCV.js loader
// =====================
function loadOpenCV() {
  return new Promise((resolve, reject) => {
    if (window.cv && cv.Mat) { resolve(); return; }
    const script = document.createElement('script');
    script.src = 'https://docs.opencv.org/4.9.0/opencv.js';
    script.async = true;
    script.onload = () => {
      if (cv.getBuildInformation) { resolve(); }
      else { cv.onRuntimeInitialized = () => resolve(); }
    };
    script.onerror = () => reject(new Error('OpenCV.js load failed'));
    document.head.appendChild(script);
  });
}

// =====================
// State
// =====================
let leftImage = null;
let rightImage = null;
let dsmData = null;
let currentJobId = null;
let scene3D = null;

// =====================
// UI refs
// =====================
const el = {
  loading: document.getElementById('loadingOverlay'),
  fileLeft: document.getElementById('fileLeft'),
  fileRight: document.getElementById('fileRight'),
  dropLeft: document.getElementById('dropLeft'),
  dropRight: document.getElementById('dropRight'),
  imgLeft: document.getElementById('imgLeft'),
  imgRight: document.getElementById('imgRight'),
  previewGrid: document.getElementById('previewGrid'),
  btnUpload: document.getElementById('btnUpload'),
  btnSynthetic: document.getElementById('btnSynthetic'),
  btnReset: document.getElementById('btnReset'),
  btnRun: document.getElementById('btnRun'),
  btnDownloadCSV: document.getElementById('btnDownloadCSV'),
  btnDownloadImage: document.getElementById('btnDownloadImage'),
  statusInput: document.getElementById('statusInput'),
  statusRun: document.getElementById('statusRun'),
  jobInfo: document.getElementById('jobInfo'),
  resultSection: document.getElementById('resultSection'),
  canvasDisparity: document.getElementById('canvasDisparity'),
  canvasDSM: document.getElementById('canvasDSM'),
  threeContainer: document.getElementById('threeContainer'),
  paramF: document.getElementById('paramF'),
  paramB: document.getElementById('paramB'),
  paramNumDisp: document.getElementById('paramNumDisp'),
  paramBlockSize: document.getElementById('paramBlockSize'),
  paramCellSize: document.getElementById('paramCellSize'),
  paramZScale: document.getElementById('paramZScale'),
  valZScale: document.getElementById('valZScale'),
};

// =====================
// Helpers
// =====================
function setStatus(elStatus, msg, type) {
  elStatus.innerHTML = '<span class="status-dot"></span>' + msg;
  elStatus.className = 'status ' + (type || 'ready');
}

function readFileAsImage(file) {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => { URL.revokeObjectURL(url); resolve(img); };
    img.src = url;
  });
}

function setupDrop(dropzone, fileInput, onFile) {
  dropzone.addEventListener('dragover', (e) => { e.preventDefault(); dropzone.classList.add('dragover'); });
  dropzone.addEventListener('dragleave', () => dropzone.classList.remove('dragover'));
  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.classList.remove('dragover');
    if (e.dataTransfer.files.length) onFile(e.dataTransfer.files[0]);
  });
  fileInput.addEventListener('change', () => { if (fileInput.files.length) onFile(fileInput.files[0]); });
}

// =====================
// Server upload
// =====================
async function uploadToServer() {
  if (!el.fileLeft.files[0] || !el.fileRight.files[0]) {
    setStatus(el.statusInput, '左右両方の画像ファイルを選択してください', 'error');
    return;
  }
  const formData = new FormData();
  formData.append('leftImage', el.fileLeft.files[0]);
  formData.append('rightImage', el.fileRight.files[0]);

  setStatus(el.statusInput, 'サーバーにアップロード中…', 'ready');
  try {
    const res = await fetch('/api/upload', { method: 'POST', body: formData });
    const data = await res.json();
    if (data.success) {
      currentJobId = data.jobId;
      setStatus(el.statusInput, 'アップロード完了: ' + data.jobId, 'ready');
      el.jobInfo.textContent = 'Job ID: ' + data.jobId;
      el.jobInfo.classList.remove('hidden');
    } else {
      setStatus(el.statusInput, 'アップロード失敗: ' + data.error, 'error');
    }
  } catch (err) {
    setStatus(el.statusInput, '通信エラー: ' + err.message, 'error');
  }
}

// =====================
// Synthetic stereo pair generator
// =====================
function generateSyntheticStereoPair() {
  const W = 480, H = 360;
  const canvasL = document.createElement('canvas');
  const canvasR = document.createElement('canvas');
  canvasL.width = canvasR.width = W;
  canvasL.height = canvasR.height = H;
  const ctxL = canvasL.getContext('2d');
  const ctxR = canvasR.getContext('2d');

  // Background gradient (sky)
  const grad = ctxL.createLinearGradient(0,0,0,H);
  grad.addColorStop(0, '#87CEEB'); grad.addColorStop(0.5, '#e0f0ff'); grad.addColorStop(1, '#d0e8d0');
  ctxL.fillStyle = grad; ctxL.fillRect(0,0,W,H);
  ctxR.fillStyle = grad; ctxR.fillRect(0,0,W,H);

  // Terrain function: returns height at x
  function terrainHeight(x) {
    const nx = x / W;
    return H * (0.55
      + 0.12 * Math.sin(nx * Math.PI * 4)
      + 0.08 * Math.sin(nx * Math.PI * 9)
      + 0.06 * Math.exp(-Math.pow((nx-0.35)*6, 2))
      + 0.10 * Math.exp(-Math.pow((nx-0.7)*5, 2))
    );
  }

  // Draw terrain as filled shape
  function drawTerrain(ctx, offsetX) {
    ctx.beginPath();
    ctx.moveTo(0, H);
    for (let x = 0; x <= W; x++) {
      const h = terrainHeight(x + offsetX);
      ctx.lineTo(x, h);
    }
    ctx.lineTo(W, H);
    ctx.closePath();
    const grad = ctx.createLinearGradient(0,0,0,H);
    grad.addColorStop(0, '#5a8a4e');
    grad.addColorStop(0.4, '#7aad6a');
    grad.addColorStop(1, '#3d6b33');
    ctx.fillStyle = grad;
    ctx.fill();
    ctx.strokeStyle = '#2a4d24';
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  // Draw some trees
  function drawTrees(ctx, offsetX) {
    for (let i = 0; i < 18; i++) {
      const tx = ((i * 9301 + 49297) % W + W) % W;
      const xPos = (tx + i * 27) % W;
      const th = terrainHeight(xPos + offsetX);
      const h = 18 + (i % 5) * 6;
      // trunk
      ctx.fillStyle = '#5c4033';
      ctx.fillRect(xPos - 2, th - h*0.3, 4, h*0.3);
      // foliage
      ctx.fillStyle = i % 3 === 0 ? '#2d5a27' : (i % 3 === 1 ? '#3a6b33' : '#1e4220');
      ctx.beginPath();
      ctx.moveTo(xPos - 12, th - h*0.4);
      ctx.lineTo(xPos, th - h);
      ctx.lineTo(xPos + 12, th - h*0.4);
      ctx.closePath();
      ctx.fill();
    }
  }

  // Draw buildings
  function drawBuildings(ctx, offsetX) {
    const buildings = [
      {x: 120, w: 50, h: 70, color: '#8c8c8c'},
      {x: 280, w: 40, h: 90, color: '#a0a0a0'},
      {x: 360, w: 35, h: 55, color: '#7a7a7a'},
    ];
    for (const b of buildings) {
      const by = terrainHeight(b.x + offsetX);
      ctx.fillStyle = b.color;
      ctx.fillRect(b.x - b.w/2, by - b.h, b.w, b.h);
      ctx.strokeStyle = '#555';
      ctx.lineWidth = 1;
      ctx.strokeRect(b.x - b.w/2, by - b.h, b.w, b.h);
      // windows
      ctx.fillStyle = '#cde8ff';
      for (let wy = by - b.h + 10; wy < by - 5; wy += 14) {
        for (let wx = b.x - b.w/2 + 6; wx < b.x + b.w/2 - 6; wx += 10) {
          ctx.fillRect(wx, wy, 5, 8);
        }
      }
    }
  }

  const disparityOffset = 18; // pixels shift for right image

  drawTerrain(ctxL, 0);
  drawTrees(ctxL, 0);
  drawBuildings(ctxL, 0);

  drawTerrain(ctxR, disparityOffset);
  drawTrees(ctxR, disparityOffset);
  drawBuildings(ctxR, disparityOffset);

  leftImage = new Image();
  leftImage.src = canvasL.toDataURL('image/png');
  rightImage = new Image();
  rightImage.src = canvasR.toDataURL('image/png');

  leftImage.onload = () => {
    el.imgLeft.src = leftImage.src;
    el.imgRight.src = rightImage.src;
    el.previewGrid.classList.remove('hidden');
    setStatus(el.statusInput, '合成デモ画像を生成しました（左・右）', 'ready');
  };
}

// =====================
// Disparity & DSM
// =====================
function imageToGrayMat(img) {
  const c = document.createElement('canvas');
  c.width = img.naturalWidth || img.width;
  c.height = img.naturalHeight || img.height;
  const ctx = c.getContext('2d');
  ctx.drawImage(img, 0, 0);
  const imgData = ctx.getImageData(0, 0, c.width, c.height);
  const mat = new cv.Mat(c.height, c.width, cv.CV_8UC4);
  mat.data.set(imgData.data);
  const gray = new cv.Mat();
  cv.cvtColor(mat, gray, cv.COLOR_RGBA2GRAY);
  mat.delete();
  return {mat: gray, width: c.width, height: c.height};
}

function computeDisparity(leftImg, rightImg) {
  const left = imageToGrayMat(leftImg);
  const right = imageToGrayMat(rightImg);

  if (left.width !== right.width || left.height !== right.height) {
    const resized = new cv.Mat();
    cv.resize(right.mat, resized, new cv.Size(left.width, left.height));
    right.mat.delete();
    right.mat = resized;
    right.width = left.width;
    right.height = left.height;
  }

  const numDisparities = Math.max(16, parseInt(el.paramNumDisp.value) || 64);
  const blockSize = Math.max(5, parseInt(el.paramBlockSize.value) || 15);

  const disparity = new cv.Mat();
  const stereo = new cv.StereoBM();
  stereo.setNumDisparities(numDisparities);
  stereo.setBlockSize(blockSize);
  stereo.setPreFilterType(cv.STEREO_BM_PREFILTER_NORMALIZED_RESPONSE);
  stereo.setPreFilterSize(5);
  stereo.setPreFilterCap(31);
  stereo.setTextureThreshold(10);
  stereo.setMinDisparity(0);
  stereo.setSpeckleWindowSize(100);
  stereo.setSpeckleRange(32);
  stereo.setDisp12MaxDiff(1);

  stereo.compute(left.mat, right.mat, disparity);

  left.mat.delete();
  right.mat.delete();
  stereo.delete();

  return {disparity, width: left.width, height: left.height};
}

function disparityToDSM(disparityMat, width, height) {
  const f = parseFloat(el.paramF.value) || 800;
  const B = parseFloat(el.paramB.value) || 0.12;
  const zScale = parseFloat(el.paramZScale.value) || 1.0;
  const cellSize = parseFloat(el.paramCellSize.value) || 0.5;

  const disp = new Float32Array(width * height);
  const dsm = new Float32Array(width * height);

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = y * width + x;
      const val = disparityMat.int16At(y, x);
      const d = val / 16.0;
      disp[idx] = d;
      const z = (d > 0.1) ? (f * B / d) * zScale : 0;
      dsm[idx] = z;
    }
  }

  let minZ = Infinity, maxZ = -Infinity;
  for (let i = 0; i < dsm.length; i++) {
    if (dsm[i] > 0) {
      if (dsm[i] < minZ) minZ = dsm[i];
      if (dsm[i] > maxZ) maxZ = dsm[i];
    }
  }
  if (!isFinite(minZ)) { minZ = 0; maxZ = 1; }

  return {dsm, disp, width, height, minZ, maxZ, cellSize};
}

function renderDisparityCanvas(disp, width, height, canvas) {
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  const imgData = ctx.createImageData(width, height);

  let minD = Infinity, maxD = -Infinity;
  for (let i = 0; i < disp.length; i++) {
    if (disp[i] < minD) minD = disp[i];
    if (disp[i] > maxD) maxD = disp[i];
  }
  if (!isFinite(minD)) { minD = 0; maxD = 1; }
  const rangeD = maxD - minD || 1;

  for (let i = 0; i < disp.length; i++) {
    const v = Math.round(255 * (disp[i] - minD) / rangeD);
    imgData.data[i*4] = v;
    imgData.data[i*4+1] = v;
    imgData.data[i*4+2] = v;
    imgData.data[i*4+3] = 255;
  }
  ctx.putImageData(imgData, 0, 0);
}

function jetColor(t) {
  const r = Math.max(0, Math.min(1, 1.5 - Math.abs(t*4 - 3)));
  const g = Math.max(0, Math.min(1, 1.5 - Math.abs(t*4 - 2)));
  const b = Math.max(0, Math.min(1, 1.5 - Math.abs(t*4 - 1)));
  return {r: Math.round(r*255), g: Math.round(g*255), b: Math.round(b*255)};
}

function renderDSMCanvas(dsm, width, height, minZ, maxZ, canvas) {
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  const imgData = ctx.createImageData(width, height);
  const rangeZ = maxZ - minZ || 1;

  for (let i = 0; i < dsm.length; i++) {
    const t = (dsm[i] - minZ) / rangeZ;
    const c = jetColor(Math.max(0, Math.min(1, t)));
    imgData.data[i*4] = c.r;
    imgData.data[i*4+1] = c.g;
    imgData.data[i*4+2] = c.b;
    imgData.data[i*4+3] = 255;
  }
  ctx.putImageData(imgData, 0, 0);
}

// =====================
// Three.js 3D Terrain
// =====================
function initThreeJS() {
  if (scene3D) return scene3D;
  const container = el.threeContainer;
  const width = container.clientWidth;
  const height = container.clientHeight;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0f1410);

  const camera = new THREE.PerspectiveCamera(60, width / height, 0.01, 1000);
  camera.position.set(0, 1.5, 2.5);

  const renderer = new THREE.WebGLRenderer({antialias: true});
  renderer.setSize(width, height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  container.innerHTML = '';
  container.appendChild(renderer.domElement);

  const controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;

  const ambient = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambient);
  const dir = new THREE.DirectionalLight(0xffffff, 0.8);
  dir.position.set(5, 10, 7);
  scene.add(dir);

  const grid = new THREE.GridHelper(10, 20, 0x334433, 0x1a221a);
  grid.position.y = -0.01;
  scene.add(grid);

  function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
  }
  animate();

  scene3D = {scene, camera, renderer, controls, mesh: null, width, height};
  return scene3D;
}

function updateThreeMesh(dsm, width, height, minZ, maxZ, cellSize) {
  const s3 = initThreeJS();
  if (s3.mesh) {
    s3.scene.remove(s3.mesh);
    s3.mesh.geometry.dispose();
    s3.mesh.material.dispose();
  }

  const rangeZ = maxZ - minZ || 1;
  const W = width;
  const H = height;

  const geometry = new THREE.PlaneGeometry(W * cellSize, H * cellSize, W - 1, H - 1);
  geometry.rotateX(-Math.PI / 2);

  const colors = [];
  const posAttr = geometry.attributes.position;

  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const idx = y * W + x;
      const z = dsm[idx];
      const t = Math.max(0, Math.min(1, (z - minZ) / rangeZ));
      const c = jetColor(t);
      colors.push(c.r/255, c.g/255, c.b/255);
      const vIdx = y * W + x;
      const h = (z - minZ) * 0.5;
      posAttr.setY(vIdx, h);
    }
  }

  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
  geometry.computeVertexNormals();

  const material = new THREE.MeshStandardMaterial({
    vertexColors: true,
    side: THREE.DoubleSide,
    roughness: 0.8,
    metalness: 0.1,
    flatShading: false,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.x = - (W * cellSize) / 2;
  mesh.position.z = - (H * cellSize) / 2;
  s3.scene.add(mesh);
  s3.mesh = mesh;
}

// =====================
// Save result to server
// =====================
async function saveResultToServer() {
  if (!currentJobId || !dsmData) return;

  const dsmImageBase64 = el.canvasDSM.toDataURL('image/png');

  // Build CSV
  const {dsm, width, height, cellSize} = dsmData;
  let csv = 'x,y,z\n';
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = y * width + x;
      const worldX = x * cellSize;
      const worldY = (height - y) * cellSize;
      csv += worldX.toFixed(2) + ',' + worldY.toFixed(2) + ',' + dsm[idx].toFixed(4) + '\n';
    }
  }

  const payload = {
    dsmImageBase64,
    csvData: csv,
    params: {
      f: parseFloat(el.paramF.value),
      B: parseFloat(el.paramB.value),
      numDisparities: parseInt(el.paramNumDisp.value),
      blockSize: parseInt(el.paramBlockSize.value),
      cellSize: parseFloat(el.paramCellSize.value),
      zScale: parseFloat(el.paramZScale.value),
    },
    stats: {
      width: dsmData.width,
      height: dsmData.height,
      minZ: dsmData.minZ,
      maxZ: dsmData.maxZ,
    }
  };

  try {
    const res = await fetch('/api/job/' + currentJobId + '/result', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    if (data.success) {
      setStatus(el.statusRun, '結果サーバーに保存しました', 'ready');
    }
  } catch (err) {
    console.error('Save failed:', err);
  }
}

// =====================
// Downloads
// =====================
function downloadCSV() {
  if (!dsmData) return;
  const {dsm, width, height, cellSize} = dsmData;
  let csv = 'x,y,z\n';
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = y * width + x;
      const worldX = x * cellSize;
      const worldY = (height - y) * cellSize;
      csv += worldX.toFixed(2) + ',' + worldY.toFixed(2) + ',' + dsm[idx].toFixed(4) + '\n';
    }
  }
  const blob = new Blob([csv], {type: 'text/csv'});
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'dsm_output.csv';
  a.click();
  URL.revokeObjectURL(a.href);
}

function downloadImage() {
  const canvas = el.canvasDSM;
  const a = document.createElement('a');
  a.href = canvas.toDataURL('image/png');
  a.download = 'dsm_heatmap.png';
  a.click();
}

// =====================
// Event wiring
// =====================
setupDrop(el.dropLeft, el.fileLeft, async (file) => {
  leftImage = await readFileAsImage(file);
  el.imgLeft.src = leftImage.src;
  el.previewGrid.classList.remove('hidden');
  setStatus(el.statusInput, '左画像: ' + file.name, 'ready');
});

setupDrop(el.dropRight, el.fileRight, async (file) => {
  rightImage = await readFileAsImage(file);
  el.imgRight.src = rightImage.src;
  el.previewGrid.classList.remove('hidden');
  setStatus(el.statusInput, '右画像: ' + file.name, 'ready');
});

el.btnUpload.addEventListener('click', uploadToServer);

el.btnSynthetic.addEventListener('click', () => {
  generateSyntheticStereoPair();
});

el.btnReset.addEventListener('click', () => {
  leftImage = null; rightImage = null; dsmData = null; currentJobId = null;
  el.imgLeft.src = ''; el.imgRight.src = '';
  el.previewGrid.classList.add('hidden');
  el.resultSection.classList.add('hidden');
  el.jobInfo.classList.add('hidden');
  setStatus(el.statusInput, '画像をアップロードするか、合成デモを生成してください');
});

el.paramZScale.addEventListener('input', () => {
  el.valZScale.textContent = parseFloat(el.paramZScale.value).toFixed(1);
});

el.btnRun.addEventListener('click', async () => {
  if (!leftImage || !rightImage) {
    setStatus(el.statusRun, '左右の画像が必要です', 'error');
    return;
  }
  setStatus(el.statusRun, '視差計算中…', 'ready');
  await new Promise(r => setTimeout(r, 50));

  try {
    const {disparity, width, height} = computeDisparity(leftImage, rightImage);
    const dispArray = new Float32Array(width * height);
    for (let i = 0; i < dispArray.length; i++) {
      dispArray[i] = disparity.int16At(Math.floor(i / width), i % width) / 16;
    }
    renderDisparityCanvas(dispArray, width, height, el.canvasDisparity);

    setStatus(el.statusRun, 'DSM変換中…', 'ready');
    await new Promise(r => setTimeout(r, 30));

    const result = disparityToDSM(disparity, width, height);
    dsmData = result;
    renderDSMCanvas(result.dsm, result.width, result.height, result.minZ, result.maxZ, el.canvasDSM);

    setStatus(el.statusRun, '3D表示構築中…', 'ready');
    await new Promise(r => setTimeout(r, 30));

    updateThreeMesh(result.dsm, result.width, result.height, result.minZ, result.maxZ, result.cellSize);

    disparity.delete();
    el.resultSection.classList.remove('hidden');
    setStatus(el.statusRun, '完了: ' + result.width + '×' + result.height + '点、標高範囲 ' + result.minZ.toFixed(2) + '～' + result.maxZ.toFixed(2) + ' m', 'ready');
    el.resultSection.scrollIntoView({behavior: 'smooth'});

    // Save to server if job exists
    if (currentJobId) {
      await saveResultToServer();
    }
  } catch (e) {
    console.error(e);
    setStatus(el.statusRun, 'エラー: ' + e.message, 'error');
  }
});

el.btnDownloadCSV.addEventListener('click', downloadCSV);
el.btnDownloadImage.addEventListener('click', downloadImage);

// =====================
// Init
// =====================
Promise.all([loadOpenCV()]).then(() => {
  el.loading.classList.add('hidden');
  setStatus(el.statusInput, '準備完了。画像をアップロードするか、合成デモを生成してください', 'ready');
}).catch(err => {
  el.loading.innerHTML = '<div style="color:#b23a2e">ライブラリ読み込みに失敗しました<br>' + err.message + '</div>';
});
