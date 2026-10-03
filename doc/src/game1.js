O: { color: '#ffff00', matrix: [[1,1],[1,1]] },
    S: { color: '#00ff00', matrix: [[0,1,1],[1,1,0],[0,0,0]] },
    T: { color: '#a000f0', matrix: [[0,1,0],[1,1,1],[0,0,0]] },
    Z: { color: '#ff0000', matrix: [[1,1,0],[0,1,1],[0,0,0]] }
};

// SRS (Super Rotation System) キックテーブル
const KICK_TABLE = [
    [[0,0], [-1,0], [-1,1], [0,-2], [-1,-2]], // 0 -> 1
    [[0,0], [1,0], [1,-1], [0,2], [1,2]],     // 1 -> 0
    [[0,0], [1,0], [1,-1], [0,2], [1,2]],     // 1 -> 2
    [[0,0], [-1,0], [-1,1], [0,-2], [-1,-2]], // 2 -> 1
    [[0,0], [1,0], [1,1], [0,-2], [1,-2]],    // 2 -> 3
    [[0,0], [-1,0], [-1,-1], [0,2], [-1,2]],  // 3 -> 2
    [[0,0], [-1,0], [-1,-1], [0,2], [-1,2]],  // 3 -> 0
    [[0,0], [1,0], [1,1], [0,-2], [1,-2]]     // 0 -> 3
];

let grid = Array.from({ length: ROWS }, () => Array(COLS).fill(0));
let score = 0, lines = 0, level = 1, ren = -1;
let currentPiece, holdPiece, canHold = true;
let bag = [], nextQueue = [];
let gameOver = false, lastTime = 0, dropCounter = 0;

// 7-Bag 抽選アルゴリズム
function generateBag() {
    const keys = Object.keys(SHAPES);
    for (let i = keys.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [keys[i], keys[j]] = [keys[j], keys[i]];
    }
    return keys;
}

function getNextPieceType() {
    if (bag.length === 0) bag = generateBag();
    return bag.pop();
}

class Piece {
    constructor(type) {
    this.type = type;
    this.color = SHAPES[type].color;
    this.matrix = SHAPES[type].matrix.map(row => [...row]);
    this.x = Math.floor((COLS - this.matrix[0].length) / 2);
    this.y = 0;
    this.rotation = 0; // 0, 1, 2, 3
    this.lastActionWasRotate = false;
    }
}

function resetGame() {
    grid = Array.from({ length: ROWS }, () => Array(COLS).fill(0));
    score = 0; lines = 0; level = 1; ren = -1;
    gameOver = false; holdPiece = null; canHold = true;
    bag = []; nextQueue = [];
    
    for (let i = 0; i < 3; i++) nextQueue.push(getNextPieceType());
    spawnPiece();
    updateUI();
    document.getElementById('actionText').innerText = '';
}

function spawnPiece() {
    currentPiece = new Piece(nextQueue.shift());
    nextQueue.push(getNextPieceType());
    canHold = true;

    if (collide(grid, currentPiece)) {
    gameOver = true;
    document.getElementById('actionText').innerText = 'GAME OVER';
    }
}

function collide(grid, piece, offset = { x: 0, y: 0 }) {
    for (let y = 0; y < piece.matrix.length; y++) {
    for (let x = 0; x < piece.matrix[y].length; x++) {
        if (piece.matrix[y][x]) {
        const newX = piece.x + x + offset.x;
        const newY = piece.y + y + offset.y;
        if (newX < 0 || newX >= COLS || newY >= ROWS) return true;
        if (newY >= 0 && grid[newY][newX]) return true;
        }
    }
    }
    return false;
}

// 行回転処理 (SRS実装)
function rotate(piece, dir) {
    const oldRotation = piece.rotation;
    const newRotation = (piece.rotation + dir + 4) % 4;
    const matrix = piece.matrix;
    const N = matrix.length;
    
    // 行列の回転
    const rotated = Array.from({ length: N }, () => Array(N).fill(0));
    for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
        rotated[x][N - 1 - y] = dir > 0 ? matrix[y][x] : matrix[N - 1 - x][y];
    }
    }

    const prevMatrix = piece.matrix;
    piece.matrix = rotated;
    piece.rotation = newRotation;

    // Wall Kick 判定
    const kickIndex = oldRotation * 2 + (dir > 0 ? 0 : 1);
    const kicks = KICK_TABLE[kickIndex % KICK_TABLE.length];

    for (let [kx, ky] of kicks) {
    if (!collide(grid, piece, { x: kx, y: -ky })) {
        piece.x += kx;
        piece.y -= ky;
        piece.lastActionWasRotate = true;
        return;
    }
    }

    // キック失敗時は戻す
    piece.matrix = prevMatrix;
    piece.rotation = oldRotation;
}

// 落下および固定処理
function drop() {
    if (!collide(grid, currentPiece, { x: 0, y: 1 })) {
    currentPiece.y++;
    currentPiece.lastActionWasRotate = false;
    } else {
    lockPiece();
    }
    dropCounter = 0;
}

function hardDrop() {
    while (!collide(grid, currentPiece, { x: 0, y: 1 })) {
    currentPiece.y++;
    score += 2;
    }
    lockPiece();
}

function lockPiece() {
    const isTSpin = checkTSpin();
    for (let y = 0; y < currentPiece.matrix.length; y++) {
    for (let x = 0; x < currentPiece.matrix[y].length; x++) {
        if (currentPiece.matrix[y][x]) {
        grid[currentPiece.y + y][currentPiece.x + x] = currentPiece.color;
        }
    }
    }

    clearLines(isTSpin);
    spawnPiece();
}

// T-Spin 判定ロジック
function checkTSpin() {
    if (currentPiece.type !== 'T' || !currentPiece.lastActionWasRotate) return false;
    let corners = 0;
    const cx = currentPiece.x + 1;
    const cy = currentPiece.y + 1;
    const checkCorners = [[cx-1, cy-1], [cx+1, cy-1], [cx-1, cy+1], [cx+1, cy+1]];
    
    for (let [x, y] of checkCorners) {
    if (x < 0 || x >= COLS || y >= ROWS || (y >= 0 && grid[y][x])) corners++;
    }
    return corners >= 3;
}

// ライン消去・スコア・REN（コンボ）計算
function clearLines(isTSpin) {
    let cleared = 0;
    for (let y = ROWS - 1; y >= 0; y--) {
    if (grid[y].every(cell => cell !== 0)) {
        grid.splice(y, 1);
        grid.unshift(Array(COLS).fill(0));
        cleared++;
        y++;
    }
    }

    let actionText = '';
    if (cleared > 0) {
    ren++;
    let baseScore = 0;
    if (isTSpin) {
        actionText = `T-SPIN ${['SINGLE', 'DOUBLE', 'TRIPLE'][cleared - 1] || ''}!`;
        baseScore = [800, 1200, 1600][cleared - 1] || 400;
    } else {
        const names = ['SINGLE', 'DOUBLE', 'TRIPLE', 'TETRIS'];
        actionText = names[cleared - 1] || '';
        baseScore = [100, 300, 500, 800][cleared - 1] || 0;
    }

    if (ren > 0) actionText += ` ${ren} REN!`;
    score += (baseScore + ren * 50) * level;
    lines += cleared;
    level = Math.floor(lines / 10) + 1;
    } else {
    ren = -1;
    if (isTSpin) actionText = 'T-SPIN!';
    }

    document.getElementById('actionText').innerText = actionText;
    updateUI();
}

// ホールド処理
function hold() {
    if (!canHold) return;
    if (!holdPiece) {
    holdPiece = currentPiece.type;
    spawnPiece();
    } else {
    const temp = currentPiece.type;
    currentPiece = new Piece(holdPiece);
    holdPiece = temp;
    }
    canHold = false;
    drawHold();
}

// 画面更新描画
function draw() {
    ctx.clearRect(0, 0, boardCanvas.width, boardCanvas.height);

    // グリッド線の描画
    ctx.strokeStyle = '#222';
    for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
        ctx.strokeRect(c * BLOCK_SIZE, r * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE);
        if (grid[r][c]) {
        ctx.fillStyle = grid[r][c];
        ctx.fillRect(c * BLOCK_SIZE, r * BLOCK_SIZE, BLOCK_SIZE - 1, BLOCK_SIZE - 1);
        }
    }
    }

    if (currentPiece && !gameOver) {
    // ゴースト（落下予測位置）の描画
    const ghost = new Piece(currentPiece.type);
    ghost.matrix = currentPiece.matrix;
    ghost.x = currentPiece.x;
    ghost.y = currentPiece.y;
    while (!collide(grid, ghost, { x: 0, y: 1 })) ghost.y++;

    ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
    drawMatrix(ctx, ghost.matrix, ghost.x, ghost.y);

    // 操作中のテトリミノ
    ctx.fillStyle = currentPiece.color;
    drawMatrix(ctx, currentPiece.matrix, currentPiece.x, currentPiece.y);
    }

    drawNext();
    drawHold();
}

function drawMatrix(context, matrix, offsetX, offsetY, size = BLOCK_SIZE) {
    for (let y = 0; y < matrix.length; y++) {
    for (let x = 0; x < matrix[y].length; x++) {
        if (matrix[y][x]) {
        context.fillRect((offsetX + x) * size, (offsetY + y) * size, size - 1, size - 1);
        }
    }
    }
}

function drawNext() {
    nextCtx.clearRect(0, 0, 80, 120);
    nextQueue.slice(0, 2).forEach((type, idx) => {
    nextCtx.fillStyle = SHAPES[type].color;
    drawMatrix(nextCtx, SHAPES[type].matrix, 0.5, idx * 2.2 + 0.5, 18);
    });
}

function drawHold() {
    holdCtx.clearRect(0, 0, 80, 80);
    if (holdPiece) {
    holdCtx.fillStyle = SHAPES[holdPiece].color;
    drawMatrix(holdCtx, SHAPES[holdPiece].matrix, 0.5, 0.5, 18);
    }
}

function updateUI() {
    document.getElementById('score').innerText = score;
    document.getElementById('lines').innerText = lines;
    document.getElementById('level').innerText = level;
}

// メインループ
function gameLoop(time = 0) {
    const deltaTime = time - lastTime;
    lastTime = time;
    dropCounter += deltaTime;

    const dropInterval = Math.max(100, 1000 - (level - 1) * 80);
    if (dropCounter > dropInterval && !gameOver) {
    drop();
    }

    draw();
    requestAnimationFrame(gameLoop);
}

// キーボード操作
document.addEventListener('keydown', e => {
    if (gameOver) return;
    switch (e.code) {
    case 'ArrowLeft':
        if (!collide(grid, currentPiece, { x: -1, y: 0 })) {
        currentPiece.x--;
        currentPiece.lastActionWasRotate = false;
        }
        break;
    case 'ArrowRight':
        if (!collide(grid, currentPiece, { x: 1, y: 0 })) {
        currentPiece.x++;
        currentPiece.lastActionWasRotate = false;
        }
        break;
    case 'ArrowDown':
        drop();
        score += 1;
        break;
    case 'Space':
        hardDrop();
        break;
    case 'KeyX':
    case 'ArrowUp':
        rotate(currentPiece, 1);
        break;
    case 'KeyZ':
        rotate(currentPiece, -1);
        break;
    case 'KeyC':
    case 'ShiftLeft':
        hold();
        break;
    }
});

// 初期化・起動
resetGame();
gameLoop();