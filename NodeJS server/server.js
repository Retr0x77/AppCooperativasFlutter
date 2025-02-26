const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// Configuración de la base de datos
const dbPath = './cooperativas.db';
const db = new sqlite3.Database(dbPath);

// Crear tablas si no existen
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE,
    name TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS cooperativas (
    id TEXT PRIMARY KEY,
    name TEXT,
    description TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS miembros (
    userId TEXT,
    cooperativeId TEXT,
    balance REAL,
    PRIMARY KEY (userId, cooperativeId)
  )`);
});

// Ruta para obtener todos los usuarios
app.get('/usuarios', (req, res) => {
  db.all('SELECT * FROM usuarios', [], (err, rows) => {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// Ruta para crear usuario
app.post('/usuarios', (req, res) => {
  const { email, name, password } = req.body;
  db.run('INSERT INTO usuarios (email, name) VALUES (?, ?)', [email, name], function(err) {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json({ id: this.lastID, email, name });
  });
});

app.post('/leave-cooperative', (req, res) => {
  const { cooperativeId, userId } = req.body;
  db.run('DELETE FROM miembros WHERE cooperativeId = ? AND userId = ?', [cooperativeId, userId], (err) => {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json({ message: 'Miembro eliminado exitosamente' });
  });
});

app.get('/miembros', (req, res) => {
  db.all('SELECT * FROM miembros', [], (err, rows) => {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// Ruta para crear cooperativa
app.post('/cooperativas', (req, res) => {
  const { id, name, description } = req.body;
  db.run('INSERT INTO cooperativas (id, name, description) VALUES (?, ?, ?)', [id, name, description], (err) => {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json({ message: 'Cooperativa creada exitosamente' });
  });
});

// Ruta para unirse a una cooperativa
app.post('/miembros', (req, res) => {
  const { cooperativeId, member } = req.body;
  const { userId, balance } = member;
  db.run('INSERT INTO miembros (userId, cooperativeId, balance) VALUES (?, ?, ?)', [userId, cooperativeId, balance], (err) => {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json({ message: 'Miembro agregado exitosamente' });
  });
});

app.post('/sync-users', (req, res) => {
  const { usuarios } = req.body;
  const stmt = db.prepare('INSERT OR REPLACE INTO usuarios (id, email, name) VALUES (?, ?, ?)');
  
  usuarios.forEach(usuario => {
    stmt.run([usuario.id, usuario.email, usuario.name], (err) => {
      if (err) {
        console.error('Error al sincronizar usuario:', err);
      }
    });
  });
  
  stmt.finalize((err) => {
    if (err) {
      res.status(500).json({ error: 'Error al sincronizar usuarios' });
    } else {
      res.json({ message: 'Usuarios sincronizados exitosamente' });
    }
  });
});

app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    db.get('SELECT * FROM usuarios WHERE email = ?', [email], (err, user) => {
      if (err) {
        return res.status(500).json({ error: "Error en la base de datos" });
      }
      if (!user) {
        return res.status(401).json({ error: "Usuario no encontrado" });
      }

      res.json({ message: "Login successful", user: { id: user.id, email: user.email, name: user.name } });
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get('/cooperativas', (req, res) => {
  db.all('SELECT * FROM cooperativas', [], (err, rows) => {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// Ruta para sincronizar cooperativas
app.post('/sync', (req, res) => {
  const { cooperativas } = req.body;
  const stmt = db.prepare('INSERT OR REPLACE INTO cooperativas (id, name, description) VALUES (?, ?, ?)');
  
  cooperativas.forEach(cooperativa => {
    stmt.run([cooperativa.id, cooperativa.name, cooperativa.description], (err) => {
      if (err) {
        console.error('Error al sincronizar cooperativa:', err);
      }
    });
  });

  app.post('/sync-miembros', (req, res) => {
    const { miembros } = req.body;
    const stmt = db.prepare('INSERT OR REPLACE INTO miembros (userId, cooperativeId, balance) VALUES (?, ?, ?)');
    
    miembros.forEach(miembro => {
      stmt.run([miembro.userId, miembro.cooperativeId, miembro.balance], (err) => {
        if (err) {
          console.error('Error al sincronizar miembro:', err);
        }
      });
    });
    
    stmt.finalize((err) => {
      if (err) {
        res.status(500).json({ error: 'Error al sincronizar miembros' });
      } else {
        res.json({ message: 'Miembros sincronizados exitosamente' });
      }
    });
  });
  
  stmt.finalize((err) => {
    if (err) {
      res.status(500).json({ error: 'Error al sincronizar cooperativas' });
    } else {
      res.json({ message: 'Cooperativas sincronizadas exitosamente' });
    }
  });
});

// Ruta raíz para verificar que el servidor está funcionando
app.get('/', (req, res) => {
  res.send('Servidor funcionando correctamente');
});

app.listen(port, () => {
  console.log(`Servidor escuchando en http://0.0.0.0:${port}`);
});
