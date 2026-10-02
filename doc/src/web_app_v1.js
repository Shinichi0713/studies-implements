const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// リクエストボディの JSON パース用ミドルウェア
app.use(express.json());
// 静的ファイル（HTML等）を提供するディレクトリを指定
app.use(express.static('public'));

// インメモリデータストア（簡易データベースの代わり）
let todos = [
  { id: 1, task: 'Node.jsの勉強', completed: false },
  { id: 2, task: 'Webアプリの作成', completed: true }
];

// --- API エンドポイント ---

// 1. タスク一覧の取得 (GET)
app.get('/api/todos', (req, res) => {
  res.json(todos);
});

// 2. 新規タスクの追加 (POST)
app.post('/api/todos', (req, res) => {
  const { task } = req.body;
  if (!task) {
    return res.status(400).json({ error: 'タスク内容は必須です' });
  }

  const newTodo = {
    id: Date.now(),
    task,
    completed: false
  };

  todos.push(newTodo);
  res.status(201).json(newTodo);
});

// 3. タスクの削除 (DELETE)
app.delete('/api/todos/:id', (req, res) => {
  const id = parseInt(req.params.id, 10);
  todos = todos.filter(todo => todo.id !== id);
  res.status(200).json({ message: '削除しました', id });
});

// サーバーの起動
app.listen(PORT, () => {
  printServerInfo(PORT);
});

function printServerInfo(port) {
  console.log(`Server running at http://localhost:${port}`);
}

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// リクエストボディの JSON パース用ミドルウェア
app.use(express.json());
// 静的ファイル（HTML等）を提供するディレクトリを指定
app.use(express.static('public'));

// インメモリデータストア（簡易データベースの代わり）
let todos = [
  { id: 1, task: 'Node.jsの勉強', completed: false },
  { id: 2, task: 'Webアプリの作成', completed: true }
];

// --- API エンドポイント ---

// 1. タスク一覧の取得 (GET)
app.get('/api/todos', (req, res) => {
  res.json(todos);
});

// 2. 新規タスクの追加 (POST)
app.post('/api/todos', (req, res) => {
  const { task } = req.body;
  if (!task) {
    return res.status(400).json({ error: 'タスク内容は必須です' });
  }

  const newTodo = {
    id: Date.now(),
    task,
    completed: false
  };

  todos.push(newTodo);
  res.status(201).json(newTodo);
});

// 3. タスクの削除 (DELETE)
app.delete('/api/todos/:id', (req, res) => {
  const id = parseInt(req.params.id, 10);
  todos = todos.filter(todo => todo.id !== id);
  res.status(200).json({ message: '削除しました', id });
});

// サーバーの起動
app.listen(PORT, () => {
  printServerInfo(PORT);
});

function printServerInfo(port) {
  console.log(`Server running at http://localhost:${port}`);
}


const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'health_data.json');

// 初期データファイルの読み込み / 存在しなければ新規作成
function loadData() {
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([]));
    return [];
  }
  try {
    const content = fs.readFileSync(DATA_FILE, 'utf-8');
    return JSON.parse(content || '[]');
  } catch (err) {
    return [];
  }
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// サーバー本体
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // --- API エンドポイント ---

  // 1. 健康データの取得 (GET /api/records)
  if (pathname === '/api/records' && method === 'GET') {
    const records = loadData();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify(records));
  }

  // 2. 健康データの新規登録 (POST /api/records)
  if (pathname === '/api/records' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const newRecord = JSON.parse(body);
        newRecord.id = Date.now().toString();
        
        const records = loadData();
        // 日付順に昇順ソートして保持
        records.push(newRecord);
        records.sort((a, b) => new Date(a.date) - new Date(b.date));
        
        saveData(records);

        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: true, record: newRecord }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ error: '無効なJSONフォーマットです' }));
      }
    });
    return;
  }

  // 3. データの削除 (DELETE /api/records?id=xxx)
  if (pathname === '/api/records' && method === 'DELETE') {
    const id = parsedUrl.query.id;
    let records = loadData();
    records = records.filter(r => r.id !== id);
    saveData(records);

    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ success: true }));
  }

  // 4. CSV ダウンロード (GET /api/export/csv)
  if (pathname === '/api/export/csv' && method === 'GET') {
    const records = loadData();
    let csv = '日付,体重(kg),体温(℃),歩数(歩),睡眠(時間),最高血圧,最低血圧,メモ\n';
    
    records.forEach(r => {
      csv += `${r.date},${r.weight || ''},${r.temp || ''},${r.steps || ''},${r.sleep || ''},${r.bpSys || ''},${r.bpDia || ''},"${(r.memo || '').replace(/"/g, '""')}"\n`;
    });

    res.writeHead(200, {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': 'attachment; filename="health_records.csv"'
    });
    return res.end('\uFEFF' + csv); // UTF-8 BOM付き
  }

  // --- 静的ファイル配信 (HTML, CSS, JS) ---
  let filePath = pathname === '/' ? '/public/index.html' : path.join('/public', pathname);
  const fullPath = path.join(__dirname, filePath);
  const ext = path.extname(fullPath);

  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8'
  };

  fs.readFile(fullPath, (err, content) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('404 Not Found');
    } else {
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'text/plain' });
      res.end(content);
    }
  });
});

server.listen(PORT, () => {
  console.log(`Health Tracker Server is running on http://localhost:${PORT}`);
});

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'health_data.json');

// 初期データファイルの読み込み / 存在しなければ新規作成
function loadData() {
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([]));
    return [];
  }
  try {
    const content = fs.readFileSync(DATA_FILE, 'utf-8');
    return JSON.parse(content || '[]');
  } catch (err) {
    return [];
  }
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// サーバー本体
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // --- API エンドポイント ---

  // 1. 健康データの取得 (GET /api/records)
  if (pathname === '/api/records' && method === 'GET') {
    const records = loadData();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify(records));
  }

  // 2. 健康データの新規登録 (POST /api/records)
  if (pathname === '/api/records' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const newRecord = JSON.parse(body);
        newRecord.id = Date.now().toString();
        
        const records = loadData();
        // 日付順に昇順ソートして保持
        records.push(newRecord);
        records.sort((a, b) => new Date(a.date) - new Date(b.date));
        
        saveData(records);

        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: true, record: newRecord }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ error: '無効なJSONフォーマットです' }));
      }
    });
    return;
  }

  // 3. データの削除 (DELETE /api/records?id=xxx)
  if (pathname === '/api/records' && method === 'DELETE') {
    const id = parsedUrl.query.id;
    let records = loadData();
    records = records.filter(r => r.id !== id);
    saveData(records);

    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ success: true }));
  }

  // 4. CSV ダウンロード (GET /api/export/csv)
  if (pathname === '/api/export/csv' && method === 'GET') {
    const records = loadData();
    let csv = '日付,体重(kg),体温(℃),歩数(歩),睡眠(時間),最高血圧,最低血圧,メモ\n';
    
    records.forEach(r => {
      csv += `${r.date},${r.weight || ''},${r.temp || ''},${r.steps || ''},${r.sleep || ''},${r.bpSys || ''},${r.bpDia || ''},"${(r.memo || '').replace(/"/g, '""')}"\n`;
    });

    res.writeHead(200, {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': 'attachment; filename="health_records.csv"'
    });
    return res.end('\uFEFF' + csv); // UTF-8 BOM付き
  }

  // --- 静的ファイル配信 (HTML, CSS, JS) ---
  let filePath = pathname === '/' ? '/public/index.html' : path.join('/public', pathname);
  const fullPath = path.join(__dirname, filePath);
  const ext = path.extname(fullPath);

  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8'
  };

  fs.readFile(fullPath, (err, content) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('404 Not Found');
    } else {
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'text/plain' });
      res.end(content);
    }
  });
});

server.listen(PORT, () => {
  console.log(`Health Tracker Server is running on http://localhost:${PORT}`);
});