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