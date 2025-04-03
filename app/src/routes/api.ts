import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({
    message: 'API is working',
    version: '1.0.0',
  });
});

router.get('/items', (req, res) => {
  // This would typically fetch from a database
  res.json([
    { id: 1, name: 'Item 1' },
    { id: 2, name: 'Item 2' },
    { id: 3, name: 'Item 3' },
  ]);
});

router.post('/items', (req, res) => {
  const { name } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Name is required' });
  }
  
  // This would typically save to a database
  res.status(201).json({
    id: Math.floor(Math.random() * 1000),
    name,
    createdAt: new Date().toISOString(),
  });
});

export { router as apiRouter };