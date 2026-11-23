const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const passwordResetController = require('../controllers/passwordResetController');
const { limiteLogin, limiteEsqueciSenha, limiteRedefinirSenha } = require('../middlewares/limiteTentativas');

// POST /auth/login
router.post('/login', limiteLogin, authController.login);

// Esqueci minha senha: pede o código por e-mail e depois redefine.
router.post('/forgot-password', limiteEsqueciSenha, passwordResetController.forgotPassword);
router.post('/reset-password', limiteRedefinirSenha, passwordResetController.resetPassword);

module.exports = router;
