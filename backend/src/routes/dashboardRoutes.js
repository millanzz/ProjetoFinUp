const express = require('express');
const router = express.Router();

const dashboardController = require('../controllers/dashboardController');
const auth = require('../middlewares/authMiddleware');

router.use(auth);

// GET /dashboard  (aceita ?month=YYYY-MM)
router.get('/', dashboardController.summary);

module.exports = router;
