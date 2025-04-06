const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const collectionsRoutes = require('./routes/collection');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: "postgresql://neondb_owner:npg_P9STbE7ycDFv@ep-rough-term-a1wlwn6p-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require",
});

// Test database connection
app.get('/health', async (req, res) => {
  try {
    const client = await pool.connect();
    await client.query('SELECT NOW()');
    client.release();
    res.status(200).send('OK');
  } catch (err) {
    console.error('Database connection error:', err);
    res.status(500).send('Database connection error');
  }
});


app.use('/collections', collectionsRoutes);


app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
      error: 'Server error',
      message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  });

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

module.exports = app;