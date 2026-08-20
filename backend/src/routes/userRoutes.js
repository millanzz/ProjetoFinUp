const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const auth = require('../middlewares/authMiddleware');

// rota pública - cadastro
router.post('/', userController.create);

// rotas protegidas
router.get('/me', auth, userController.me);
router.put('/me', auth, userController.update);
router.put('/me/password', auth, userController.updatePassword);

module.exports = router;
