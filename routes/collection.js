const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: "postgresql://neondb_owner:npg_P9STbE7ycDFv@ep-rough-term-a1wlwn6p-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
});


/**
 * Add recommendation to collection
 * POST /collections/:collectionId/recommendations
 */
router.post('/:collectionId/recommendations', async (req, res) => {
  const { collectionId } = req.params;
  const { recommendationId, userId } = req.body;
  
  // Validation
  if (!recommendationId || !userId) {
    return res.status(400).json({ error: 'Missing required fields: recommendationId, userId' });
  }
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Verify collection exists and belongs to user
    const collectionResult = await client.query(
      'SELECT * FROM collections WHERE id = $1 AND user_id = $2',
      [collectionId, userId]
    );
    
    if (collectionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(403).json({ 
        error: 'Collection not found or does not belong to the user' 
      });
    }
    
    // Verify recommendation exists and belongs to user
    const recommendationResult = await client.query(
      'SELECT * FROM recommendations WHERE id = $1 AND user_id = $2',
      [recommendationId, userId]
    );
    
    if (recommendationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(403).json({ 
        error: 'Recommendation not found or does not belong to the user' 
      });
    }
    
    // Check if recommendation is already in the collection
    const existingResult = await client.query(
      'SELECT * FROM collection_recommendations WHERE collection_id = $1 AND recommendation_id = $2',
      [collectionId, recommendationId]
    );
    
    if (existingResult.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ 
        error: 'Recommendation is already in this collection' 
      });
    }
    
    // Add recommendation to collection
    await client.query(
      'INSERT INTO collection_recommendations (collection_id, recommendation_id) VALUES ($1, $2)',
      [collectionId, recommendationId]
    );
    
    await client.query('COMMIT');
    
    res.status(201).json({ 
      message: 'Recommendation added to collection successfully',
      collectionId,
      recommendationId
    });
    
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error adding recommendation to collection:', err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    client.release();
  }
});

/**
 * Remove recommendation from collection
 * DELETE /collections/:collectionId/recommendations/:recommendationId
 */
router.delete('/:collectionId/recommendations/:recommendationId', async (req, res) => {
  const { collectionId, recommendationId } = req.params;
  const { userId } = req.body;
  
  // Validation
  if (!userId) {
    return res.status(400).json({ error: 'Missing required field: userId' });
  }
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Verify collection exists and belongs to user
    const collectionResult = await client.query(
      'SELECT * FROM collections WHERE id = $1 AND user_id = $2',
      [collectionId, userId]
    );
    
    if (collectionResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(403).json({ 
        error: 'Collection not found or does not belong to the user' 
      });
    }
    
    // Remove recommendation from collection
    const deleteResult = await client.query(
      'DELETE FROM collection_recommendations WHERE collection_id = $1 AND recommendation_id = $2 RETURNING *',
      [collectionId, recommendationId]
    );
    
    if (deleteResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ 
        error: 'Recommendation not found in this collection' 
      });
    }
    
    await client.query('COMMIT');
    
    res.status(200).json({ 
      message: 'Recommendation removed from collection successfully',
      collectionId,
      recommendationId
    });
    
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error removing recommendation from collection:', err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    client.release();
  }
});

/**
 * View recommendations of a collection
 * GET /collections/:collectionId/recommendations
 */
router.get('/:collectionId/recommendations', async (req, res) => {
  const { collectionId } = req.params;
  const { userId } = req.query;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;
  
  // Validation
  if (!userId) {
    return res.status(400).json({ error: 'Missing required query parameter: userId' });
  }
  
  const client = await pool.connect();
  
  try {
    // Verify collection exists and belongs to user
    const collectionResult = await client.query(
      'SELECT * FROM collections WHERE id = $1 AND user_id = $2',
      [collectionId, userId]
    );
    
    if (collectionResult.rows.length === 0) {
      return res.status(403).json({ 
        error: 'Collection not found or does not belong to the user' 
      });
    }
    
    // Get collection recommendations with pagination
    const recommendationsResult = await client.query(
      `SELECT r.*, cr.created_at as added_at
       FROM recommendations r
       JOIN collection_recommendations cr ON r.id = cr.recommendation_id
       WHERE cr.collection_id = $1
       ORDER BY cr.created_at DESC
       LIMIT $2 OFFSET $3`,
      [collectionId, limit, offset]
    );
    
    // Get total count for pagination
    const countResult = await client.query(
      'SELECT COUNT(*) FROM collection_recommendations WHERE collection_id = $1',
      [collectionId]
    );
    
    const totalCount = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(totalCount / limit);
    
    res.status(200).json({
      collection: collectionResult.rows[0],
      recommendations: recommendationsResult.rows,
      pagination: {
        totalCount,
        totalPages,
        currentPage: page,
        limit
      }
    });
    
  } catch (err) {
    console.error('Error fetching collection recommendations:', err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    client.release();
  }
});

/**
 * View all collections and their recommendations for a user
 * GET /collections
 */
router.get('/', async (req, res) => {
  const { userId } = req.query;
  
  // Validation
  if (!userId) {
    return res.status(400).json({ error: 'Missing required query parameter: userId' });
  }
  
  const client = await pool.connect();
  
  try {
    // Verify user exists
    const userResult = await client.query(
      'SELECT * FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Get all collections for the user
    const collectionsResult = await client.query(
      'SELECT * FROM collections WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    
    // For each collection, get recommendations
    const collectionsWithRecommendations = await Promise.all(
      collectionsResult.rows.map(async (collection) => {
        const recommendationsResult = await client.query(
          `SELECT r.* 
           FROM recommendations r
           JOIN collection_recommendations cr ON r.id = cr.recommendation_id
           WHERE cr.collection_id = $1
           LIMIT 5`, // Get a preview of 5 recommendations per collection
          [collection.id]
        );
        
        const countResult = await client.query(
          'SELECT COUNT(*) FROM collection_recommendations WHERE collection_id = $1',
          [collection.id]
        );
        
        return {
          ...collection,
          recommendations: recommendationsResult.rows,
          totalRecommendations: parseInt(countResult.rows[0].count)
        };
      })
    );
    
    res.status(200).json({
      user: userResult.rows[0],
      collections: collectionsWithRecommendations
    });
    
  } catch (err) {
    console.error('Error fetching user collections:', err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    client.release();
  }
});

module.exports = router;