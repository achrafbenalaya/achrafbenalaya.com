// backend/index.js
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const app = express();
const port = 5000;

app.use(cors());

app.get('/todos', (req, res) => {
  fs.readFile('./data/todos.json', 'utf8', (err, data) => {
    if (err) {
      res.status(500).send('Error reading todos');
      return;
    }
    res.send(JSON.parse(data));
  });
});

app.listen(port, () => {
  console.log(`Backend server running at http://localhost:${port}`);
});