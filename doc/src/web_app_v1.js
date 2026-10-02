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

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'app_data.json');

function loadData() {
  if (!fs.existsSync(DATA_FILE)) {
    const initialData = { health: [], schedules: [], tickets: [] };
    fs.writeFileSync(DATA_FILE, JSON.stringify(initialData, null, 2));
    return initialData;
  }
  try {
    const content = fs.readFileSync(DATA_FILE, 'utf-8');
    const data = JSON.parse(content || '{}');
    return {
      health: data.health || [],
      schedules: data.schedules || [],
      tickets: data.tickets || []
    };
  } catch (err) {
    return { health: [], schedules: [], tickets: [] };
  }
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // --- API: 全データ取得 ---
  if (pathname === '/api/data' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify(loadData()));
  }

  // --- API: 体調管理 ---
  if (pathname === '/api/health' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      const record = JSON.parse(body);
      record.id = Date.now().toString();
      const data = loadData();
      data.health.push(record);
      data.health.sort((a, b) => new Date(a.date) - new Date(b.date));
      saveData(data);
      res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, record }));
    });
    return;
  }
  if (pathname === '/api/health' && method === 'DELETE') {
    const id = parsedUrl.query.id;
    const data = loadData();
    data.health = data.health.filter(r => r.id !== id);
    saveData(data);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ success: true }));
  }

  // --- API: 予定管理 ---
  if (pathname === '/api/schedule' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      const schedule = JSON.parse(body);
      schedule.id = Date.now().toString();
      const data = loadData();
      data.schedules.push(schedule);
      data.schedules.sort((a, b) => new Date(`${a.date}T${a.time || '00:00'}`) - new Date(`${b.date}T${b.time || '00:00'}`));
      saveData(data);
      res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, schedule }));
    });
    return;
  }
  if (pathname === '/api/schedule' && method === 'DELETE') {
    const id = parsedUrl.query.id;
    const data = loadData();
    data.schedules = data.schedules.filter(s => s.id !== id);
    saveData(data);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ success: true }));
  }

  // --- API: 切符管理 ---
  if (pathname === '/api/ticket' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      const ticket = JSON.parse(body);
      ticket.id = Date.now().toString();
      const data = loadData();
      data.tickets.push(ticket);
      data.tickets.sort((a, b) => new Date(`${a.date}T${a.depTime || '00:00'}`) - new Date(`${b.date}T${b.depTime || '00:00'}`));
      saveData(data);
      res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, ticket }));
    });
    return;
  }
  if (pathname === '/api/ticket' && method === 'DELETE') {
    const id = parsedUrl.query.id;
    const data = loadData();
    data.tickets = data.tickets.filter(t => t.id !== id);
    saveData(data);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ success: true }));
  }

  // --- API: CSV エクスポート ---
  if (pathname === '/api/export/csv' && method === 'GET') {
    const type = parsedUrl.query.type;
    const data = loadData();
    let csv = '';

    if (type === 'health') {
      csv = '日付,体重(kg),体温(℃),歩数(歩),睡眠(時間),最高血圧,最低血圧,メモ\n';
      data.health.forEach(r => {
        csv += `${r.date},${r.weight || ''},${r.temp || ''},${r.steps || ''},${r.sleep || ''},${r.bpSys || ''},${r.bpDia || ''},"${(r.memo || '').replace(/"/g, '""')}"\n`;
      });
    } else if (type === 'schedule') {
      csv = '日付,時間,タイトル,カテゴリー,詳細メモ\n';
      data.schedules.forEach(s => {
        csv += `${s.date},${s.time || ''},"${(s.title || '').replace(/"/g, '""')}",${s.category || ''},"${(s.memo || '').replace(/"/g, '""')}"\n`;
      });
    } else if (type === 'ticket') {
      csv = '乗車日,出発時間,発駅,着駅,路線・経由,座席種別,金額(円),メモ\n';
      data.tickets.forEach(t => {
        csv += `${t.date},${t.depTime || ''},"${(t.fromStation || '').replace(/"/g, '""')}","${(t.toStation || '').replace(/"/g, '""')}","${(t.route || '').replace(/"/g, '""')}",${t.seatType || ''},${t.fare || 0},"${(t.memo || '').replace(/"/g, '""')}"\n`;
      });
    }

    res.writeHead(200, {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${type}_data.csv"`
    });
    return res.end('\uFEFF' + csv);
  }

  // --- 静的ファイル配信 ---
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
  console.log(`Server running on http://localhost:${PORT}`);
});

