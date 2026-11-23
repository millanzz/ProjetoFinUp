const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const auth = require('../middlewares/authMiddleware');
const { limiteCadastro, limiteTentativas } = require('../middlewares/limiteTentativas');

// 5 senhas erradas ao tentar excluir a conta, por usuário, a cada 15 min
const limiteExcluirConta = limiteTentativas({
  janelaMs: 15 * 60 * 1000, max: 5, contar: 'falhas',
  chave: (req) => `excluir:${req.userId}`,
});

// rota pública - cadastro
router.post('/', limiteCadastro, userController.create);

// rotas protegidas
router.get('/me', auth, userController.me);
router.put('/me', auth, userController.update);
router.put('/me/password', auth, userController.updatePassword);
router.delete('/me', auth, limiteExcluirConta, userController.remove);

module.exports = router;
