const express = require('express');
const router = express.Router();

const incomeController = require('../controllers/incomeController');
const auth = require('../middlewares/authMiddleware');

router.use(auth);

router.post('/', incomeController.create);
router.get('/', incomeController.list);
router.put('/:id', incomeController.update);
router.delete('/grupo/:grupo', incomeController.removeGrupo); // todas as parcelas
router.delete('/:id', incomeController.remove);

module.exports = router;
