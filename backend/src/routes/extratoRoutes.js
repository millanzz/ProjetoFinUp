const express = require('express');
const router = express.Router();

const extratoController = require('../controllers/extratoController');
const auth = require('../middlewares/authMiddleware');

router.use(auth);

router.get('/', extratoController.list);
router.get('/meses', extratoController.meses);

module.exports = router;
