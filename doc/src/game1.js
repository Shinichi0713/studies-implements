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


const canvas = document.getElementById('stage');
const ctx = canvas.getContext('2d');

let currentGame = null;
let currentGameKey = '';

// ==========================================
// 1. テトリス (Tetris Engine)
// ==========================================
class TetrisEngine {
    constructor() {
    this.cols = 10;
    this.rows = 20;
    this.tileSize = 30;
    this.shapes = {
        I: { color: '#00f0ff', m: [[0,0,0,0],[1,1,1,1],[0,0,0,0],[0,0,0,0]] },
        J: { color: '#0000ff', m: [[1,0,0],[1,1,1],[0,0,0]] },
        L: { color: '#ff7f00', m: [[0,0,1],[1,1,1],[0,0,0]] },
        O: { color: '#ffff00', m: [[1,1],[1,1]] },
        S: { color: '#00ff00', m: [[0,1,1],[1,1,0],[0,0,0]] },
        T: { color: '#a000f0', m: [[0,1,0],[1,1,1],[0,0,0]] },
        Z: { color: '#ff0000', m: [[1,1,0],[0,1,1],[0,0,0]] }
    };
    this.controls = '← / → : 移動<br>↓ : 落下<br>↑ / Z : 回転<br>Space : ハードドロップ';
    }

    init() {
    this.grid = Array.from({ length: this.rows }, () => Array(this.cols).fill(0));
    this.score = 0;
    this.gameOver = false;
    this.dropTimer = 0;
    this.bag = [];
    this.spawn();
    }

    getPiece() {
    if (this.bag.length === 0) {
        this.bag = Object.keys(this.shapes).sort(() => Math.random() - 0.5);
    }
    const key = this.bag.pop();
    return {
        type: key,
        color: this.shapes[key].color,
        matrix: this.shapes[key].m.map(r => [...r]),
        x: 3,
        y: 0
    };
    }

    spawn() {
    this.p = this.getPiece();
    if (this.collide(this.p.x, this.p.y, this.p.matrix)) {
        this.gameOver = true;
    }
    }

    collide(x, y, matrix) {
    for (let r = 0; r < matrix.length; r++) {
        for (let c = 0; c < matrix[r].length; c++) {
        if (matrix[r][c]) {
            let nx = x + c, ny = y + r;
            if (nx < 0 || nx >= this.cols || ny >= this.rows) return true;
            if (ny >= 0 && this.grid[ny][nx]) return true;
        }
        }
    }
    return false;
    }

    update(dt) {
    if (this.gameOver) return;
    this.dropTimer += dt;
    if (this.dropTimer > 600) {
        this.drop();
        this.dropTimer = 0;
    }
    }

    drop() {
    if (!this.collide(this.p.x, this.p.y + 1, this.p.matrix)) {
        this.p.y++;
    } else {
        this.lock();
    }
    }

    lock() {
    for (let r = 0; r < this.p.matrix.length; r++) {
        for (let c = 0; c < this.p.matrix[r].length; c++) {
        if (this.p.matrix[r][c]) {
            this.grid[this.p.y + r][this.p.x + c] = this.p.color;
        }
        }
    }
    this.clearLines();
    this.spawn();
    }

    clearLines() {
    let lines = 0;
    for (let r = this.rows - 1; r >= 0; r--) {
        if (this.grid[r].every(cell => cell !== 0)) {
        this.grid.splice(r, 1);
        this.grid.unshift(Array(this.cols).fill(0));
        lines++;
        r++;
        }
    }
    if (lines > 0) this.score += lines * 100 * lines;
    }

    rotate() {
    const m = this.p.matrix;
    const N = m.length;
    const rotated = Array.from({ length: N }, () => Array(N).fill(0));
    for (let r = 0; r < N; r++) {
        for (let c = 0; c < N; c++) {
        rotated[c][N - 1 - r] = m[r][c];
        }
    }
    if (!this.collide(this.p.x, this.p.y, rotated)) {
        this.p.matrix = rotated;
    }
    }

    handleInput(code) {
    if (this.gameOver) return;
    if (code === 'ArrowLeft' && !this.collide(this.p.x - 1, this.p.y, this.p.matrix)) this.p.x--;
    if (code === 'ArrowRight' && !this.collide(this.p.x + 1, this.p.y, this.p.matrix)) this.p.x++;
    if (code === 'ArrowDown') this.drop();
    if (code === 'ArrowUp' || code === 'KeyZ') this.rotate();
    if (code === 'Space') {
        while (!this.collide(this.p.x, this.p.y + 1, this.p.matrix)) this.p.y++;
        this.lock();
    }
    }

    draw(ctx) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // 盤面描画
    for (let r = 0; r < this.rows; r++) {
        for (let c = 0; c < this.cols; c++) {
        ctx.strokeStyle = '#222';
        ctx.strokeRect(c * this.tileSize, r * this.tileSize, this.tileSize, this.tileSize);
        if (this.grid[r][c]) {
            ctx.fillStyle = this.grid[r][c];
            ctx.fillRect(c * this.tileSize, r * this.tileSize, this.tileSize - 1, this.tileSize - 1);
        }
        }
    }

    // ピース描画
    if (!this.gameOver && this.p) {
        ctx.fillStyle = this.p.color;
        for (let r = 0; r < this.p.matrix.length; r++) {
        for (let c = 0; c < this.p.matrix[r].length; c++) {
            if (this.p.matrix[r][c]) {
            ctx.fillRect((this.p.x + c) * this.tileSize, (this.p.y + r) * this.tileSize, this.tileSize - 1, this.tileSize - 1);
            }
        }
        }
    }
    }
}

// ==========================================
// 2. スネークゲーム (Snake Engine)
// ==========================================
class SnakeEngine {
    constructor() {
    this.gridSize = 15;
    this.tileSize = 20; // 15 x 30 = 300x600 canvas
    this.controls = '← ↑ ↓ → : 移動';
    }

    init() {
    this.snake = [{ x: 7, y: 15 }, { x: 7, y: 16 }, { x: 7, y: 17 }];
    this.dir = { x: 0, y: -1 };
    this.nextDir = { x: 0, y: -1 };
    this.score = 0;
    this.gameOver = false;
    this.stepTimer = 0;
    this.spawnFood();
    }

    spawnFood() {
    this.food = {
        x: Math.floor(Math.random() * 15),
        y: Math.floor(Math.random() * 30)
    };
    }

    update(dt) {
    if (this.gameOver) return;
    this.stepTimer += dt;
    if (this.stepTimer > 120) {
        this.step();
        this.stepTimer = 0;
    }
    }

    step() {
    this.dir = this.nextDir;
    const head = { x: this.snake[0].x + this.dir.x, y: this.snake[0].y + this.dir.y };

    // 衝突判定
    if (head.x < 0 || head.x >= 15 || head.y < 0 || head.y >= 30 || this.snake.some(s => s.x === head.x && s.y === head.y)) {
        this.gameOver = true;
        return;
    }

    this.snake.unshift(head);

    // 餌を食べる判定
    if (head.x === this.food.x && head.y === this.food.y) {
        this.score += 10;
        this.spawnFood();
    } else {
        this.snake.pop();
    }
    }

    handleInput(code) {
    if (code === 'ArrowUp' && this.dir.y === 0) this.nextDir = { x: 0, y: -1 };
    if (code === 'ArrowDown' && this.dir.y === 0) this.nextDir = { x: 0, y: 1 };
    if (code === 'ArrowLeft' && this.dir.x === 0) this.nextDir = { x: -1, y: 0 };
    if (code === 'ArrowRight' && this.dir.x === 0) this.nextDir = { x: 1, y: 0 };
    }

    draw(ctx) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // 餌を描画
    ctx.fillStyle = '#ff007f';
    ctx.fillRect(this.food.x * this.tileSize, this.food.y * this.tileSize, this.tileSize - 1, this.tileSize - 1);

    // 蛇を描画
    ctx.fillStyle = '#00f0ff';
    this.snake.forEach((s, idx) => {
        ctx.fillStyle = idx === 0 ? '#ffffff' : '#00f0ff';
        ctx.fillRect(s.x * this.tileSize, s.y * this.tileSize, this.tileSize - 1, this.tileSize - 1);
    });
    }
}

// ==========================================
// 3. マインスイーパー (Minesweeper Engine)
// ==========================================
class MinesweeperEngine {
    constructor() {
    this.cols = 10;
    this.rows = 20;
    this.tileSize = 30;
    this.minesCount = 25;
    this.controls = '左クリック : マスを開く<br>右クリック : フラグ配置';
    }

    init() {
    this.grid = Array.from({ length: this.rows }, () =>
        Array.from({ length: this.cols }, () => ({ mine: false, revealed: false, flagged: false, count: 0 }))
    );
    this.score = 0;
    this.gameOver = false;
    this.gameWon = false;
    this.firstClick = true;
    }

    placeMines(exR, exC) {
    let placed = 0;
    while (placed < this.minesCount) {
        let r = Math.floor(Math.random() * this.rows);
        let c = Math.floor(Math.random() * this.cols);
        if (!this.grid[r][c].mine && !(r === exR && c === exC)) {
        this.grid[r][c].mine = true;
        placed++;
        }
    }

    // 周囲の地雷数を算出
    for (let r = 0; r < this.rows; r++) {
        for (let c = 0; c < this.cols; c++) {
        if (this.grid[r][c].mine) continue;
        let cnt = 0;
        for (let dr = -1; dr <= 1; dr++) {
            for (let dc = -1; dc <= 1; dc++) {
            let nr = r + dr, nc = c + dc;
            if (nr >= 0 && nr < this.rows && nc >= 0 && nc < this.cols && this.grid[nr][nc].mine) {
                cnt++;
            }
            }
        }
        this.grid[r][c].count = cnt;
        }
    }
    }

    reveal(r, c) {
    if (r < 0 || r >= this.rows || c < 0 || c >= this.cols) return;
    let cell = this.grid[r][c];
    if (cell.revealed || cell.flagged) return;

    if (this.firstClick) {
        this.firstClick = false;
        this.placeMines(r, c);
    }

    cell.revealed = true;
    if (cell.mine) {
        this.gameOver = true;
        return;
    }

    this.score += 10;

    if (cell.count === 0) {
        for (let dr = -1; dr <= 1; dr++) {
        for (let dc = -1; dc <= 1; dc++) {
            if (dr !== 0 || dc !== 0) this.reveal(r + dr, c + dc);
        }
        }
    }

    this.checkWin();
    }

    toggleFlag(r, c) {
    if (r >= 0 && r < this.rows && c >= 0 && c < this.cols) {
        let cell = this.grid[r][c];
        if (!cell.revealed) cell.flagged = !cell.flagged;
    }
    }

    checkWin() {
    let unrevealedSafe = 0;
    for (let r = 0; r < this.rows; r++) {
        for (let c = 0; c < this.cols; c++) {
        if (!this.grid[r][c].mine && !this.grid[r][c].revealed) unrevealedSafe++;
        }
    }
    if (unrevealedSafe === 0) {
        this.gameWon = true;
    }
    }

    update(dt) {}

    handleInput() {} // キー操作非対応 (マウスクリック対応)

    draw(ctx) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    for (let r = 0; r < this.rows; r++) {
        for (let c = 0; c < this.cols; c++) {
        let cell = this.grid[r][c];
        let x = c * this.tileSize;
        let y = r * this.tileSize;

        if (cell.revealed) {
            if (cell.mine) {
            ctx.fillStyle = '#ff0000';
            ctx.fillRect(x, y, this.tileSize - 1, this.tileSize - 1);
            } else {
            ctx.fillStyle = '#222';
            ctx.fillRect(x, y, this.tileSize - 1, this.tileSize - 1);
            if (cell.count > 0) {
                ctx.fillStyle = ['#00f0ff', '#00ff00', '#ff007f', '#ffff00'][cell.count - 1] || '#ffffff';
                ctx.font = '16px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(cell.count, x + 15, y + 22);
            }
            }
        } else {
            ctx.fillStyle = '#444';
            ctx.fillRect(x, y, this.tileSize - 1, this.tileSize - 1);
            if (cell.flagged) {
            ctx.fillStyle = '#ffe600';
            ctx.font = '16px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText('🚩', x + 15, y + 22);
            }
        }
        }
    }
    }
}

// ==========================================
// ポータル管理 & ゲームループ
// ==========================================
const games = {
    tetris: new TetrisEngine(),
    snake: new SnakeEngine(),
    minesweeper: new MinesweeperEngine()
};

function switchGame(key) {
    currentGameKey = key;
    currentGame = games[key];
    
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    document.getElementById('controlsText').innerHTML = currentGame.controls;
    currentGame.init();
}

function restartCurrentGame() {
    if (currentGame) currentGame.init();
}

// イベントリスナー設定
document.addEventListener('keydown', e => {
    if (currentGame && currentGame.handleInput) {
    currentGame.handleInput(e.code);
    }
});

canvas.addEventListener('click', e => {
    if (currentGameKey === 'minesweeper' && !currentGame.gameOver) {
    const rect = canvas.getBoundingClientRect();
    const c = Math.floor((e.clientX - rect.left) / 30);
    const r = Math.floor((e.clientY - rect.top) / 30);
    currentGame.reveal(r, c);
    }
});

canvas.addEventListener('contextmenu', e => {
    e.preventDefault();
    if (currentGameKey === 'minesweeper' && !currentGame.gameOver) {
    const rect = canvas.getBoundingClientRect();
    const c = Math.floor((e.clientX - rect.left) / 30);
    const r = Math.floor((e.clientY - rect.top) / 30);
    currentGame.toggleFlag(r, c);
    }
});

// 統一ゲームループ
let lastTime = 0;
function mainLoop(time = 0) {
    const dt = time - lastTime;
    lastTime = time;

    if (currentGame) {
    currentGame.update(dt);
    currentGame.draw(ctx);

    // UI情報の更新
    document.getElementById('scoreVal').innerText = currentGame.score || 0;
    const statusEl = document.getElementById('statusVal');
    
    if (currentGame.gameOver) {
        statusEl.innerText = 'GAME OVER';
        statusEl.style.color = '#ff0055';
    } else if (currentGame.gameWon) {
        statusEl.innerText = 'CLEAR!';
        statusEl.style.color = '#00ff66';
    } else {
        statusEl.innerText = 'PLAYING';
        statusEl.style.color = '#ffe600';
    }
    }

    requestAnimationFrame(mainLoop);
}

// 初期ゲームの起動
switchGame('tetris');
mainLoop();