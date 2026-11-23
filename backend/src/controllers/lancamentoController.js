const dbAsync = require('../utils/dbAsync');
const {
  HttpError,
  isPositiveNumber,
  isValidDate,
  isValidMonth,
  assertCategory,
  handleError,
} = require('../utils/validators');
const {
  MIN_PARCELAS,
  MAX_PARCELAS,
  dividirValor,
  datasParcelas,
  novoGrupo,
} = require('../utils/parcelas');

/**
 * Fábrica dos controllers de receitas (/incomes) e despesas (/expenses).
 * As duas tabelas têm a mesma estrutura; a diferença é que a despesa
 * exige categoria e a receita aceita ficar sem.
 *
 * @param {object} cfg
 * @param {'incomes'|'expenses'} cfg.table
 * @param {'income'|'expense'} cfg.type     tipo de categoria aceito
 * @param {boolean} cfg.categoryRequired
 * @param {string} cfg.label                 "Receita" / "Despesa"
 */
module.exports = function lancamentoController({ table, type, categoryRequired, label }) {
  const notFound = `${label} não encontrada`;

  /** Valida categoria (se veio) e devolve o valor a gravar. */
  async function resolveCategory(categoryId, userId) {
    if (categoryId === undefined || categoryId === null) {
      if (categoryRequired) throw new HttpError(400, 'category_id é obrigatório');
      return null;
    }
    await assertCategory(categoryId, userId, type);
    return categoryId;
  }

  /**
   * Cria uma compra/receita parcelada: `amount` é o valor TOTAL, dividido
   * em `n` lançamentos mensais ligados pelo mesmo parcela_grupo.
   *
   * Todas as parcelas vão num ÚNICO INSERT (várias linhas), que o SQLite grava
   * de forma atômica: ou entram todas, ou nenhuma. Antes era usado BEGIN/COMMIT
   * na conexão única compartilhada por todas as requisições, e compras
   * parceladas simultâneas falhavam com erro 500 (DEF-16).
   */
  async function criarParcelado(req, res, { amount, description, date, categoryId, n }) {
    const grupo = novoGrupo();
    const valores = dividirValor(amount, n);
    const datas = datasParcelas(date, n);

    const linhas = valores.map(() => '(?, ?, ?, ?, 1, ?, ?, ?, ?)').join(', ');
    const params = valores.flatMap((v, i) => [
      v, description || null, datas[i], categoryId, req.userId, grupo, i + 1, n,
    ]);
    await dbAsync.run(
      `INSERT INTO ${table}
         (amount, description, date, category_id, parcelado, user_id,
          parcela_grupo, parcela_numero, parcela_total)
       VALUES ${linhas}`,
      params
    );
    const ids = await dbAsync.all(
      `SELECT id, parcela_numero FROM ${table} WHERE parcela_grupo = ? ORDER BY parcela_numero`,
      [grupo]
    );
    const criadas = ids.map((r, i) => ({
      id: r.id, amount: valores[i], date: datas[i], parcela_numero: r.parcela_numero,
    }));

    res.status(201).json({
      ...criadas[0],
      description: description || null,
      category_id: categoryId,
      parcelado: 1,
      user_id: req.userId,
      parcela_grupo: grupo,
      parcela_total: n,
      valor_total: amount,
      parcelas: criadas,
    });
  }

  // POST /
  // Campo opcional `parcelas` (2 a 48): divide `amount` em parcelas mensais.
  async function create(req, res) {
    try {
      const { amount, description, date, category_id, parcelado, parcelas } = req.body;

      if (amount === undefined || amount === null || !date) {
        throw new HttpError(400, 'amount e date são obrigatórios');
      }
      if (!isPositiveNumber(amount)) {
        throw new HttpError(400, 'amount deve ser um número positivo');
      }
      if (!isValidDate(date)) {
        throw new HttpError(400, 'date deve estar no formato AAAA-MM-DD');
      }
      if (description != null && (typeof description !== 'string' || description.length > 200)) {
        throw new HttpError(400, 'description deve ser um texto de até 200 caracteres');
      }
      if (parcelas !== undefined && parcelas !== null && parcelas !== 1) {
        if (!Number.isInteger(parcelas) || parcelas < MIN_PARCELAS || parcelas > MAX_PARCELAS) {
          throw new HttpError(
            400,
            `parcelas deve ser um número inteiro de ${MIN_PARCELAS} a ${MAX_PARCELAS}`
          );
        }
        if (amount < parcelas * 0.01) {
          throw new HttpError(400, 'amount é pequeno demais para tantas parcelas');
        }
      }
      const categoryId = await resolveCategory(category_id, req.userId);

      if (Number.isInteger(parcelas) && parcelas >= MIN_PARCELAS) {
        return await criarParcelado(req, res, {
          amount, description, date, categoryId, n: parcelas,
        });
      }

      const { lastID } = await dbAsync.run(
        `INSERT INTO ${table} (amount, description, date, category_id, parcelado, user_id)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [amount, description || null, date, categoryId, parcelado ? 1 : 0, req.userId]
      );

      res.status(201).json({
        id: lastID,
        amount,
        description: description || null,
        date,
        category_id: categoryId,
        parcelado: parcelado ? 1 : 0,
        user_id: req.userId,
      });
    } catch (err) {
      handleError(res, err);
    }
  }

  // GET /   (aceita ?month=AAAA-MM)
  async function list(req, res) {
    try {
      const { month } = req.query;
      const params = [req.userId];
      let filtro = '';

      if (month !== undefined) {
        if (!isValidMonth(month)) {
          throw new HttpError(400, 'month deve estar no formato AAAA-MM');
        }
        filtro = ` AND strftime('%Y-%m', t.date) = ?`;
        params.push(month);
      }

      const rows = await dbAsync.all(
        `SELECT t.*, c.name AS category_name
         FROM ${table} t
         LEFT JOIN categories c ON c.id = t.category_id
         WHERE t.user_id = ?${filtro}
         ORDER BY t.date DESC, t.id DESC`,
        params
      );
      res.json(rows);
    } catch (err) {
      handleError(res, err);
    }
  }

  // PUT /:id
  async function update(req, res) {
    try {
      const { id } = req.params;
      const { amount, description, date, category_id, parcelado } = req.body;

      const fields = [];
      const params = [];

      if (amount !== undefined) {
        if (!isPositiveNumber(amount)) {
          throw new HttpError(400, 'amount deve ser um número positivo');
        }
        fields.push('amount = ?');
        params.push(amount);
      }
      if (description !== undefined) {
        if (description !== null && (typeof description !== 'string' || description.length > 200)) {
          throw new HttpError(400, 'description deve ser um texto de até 200 caracteres');
        }
        fields.push('description = ?');
        params.push(description);
      }
      if (date !== undefined) {
        if (!isValidDate(date)) {
          throw new HttpError(400, 'date deve estar no formato AAAA-MM-DD');
        }
        fields.push('date = ?');
        params.push(date);
      }
      if (category_id !== undefined) {
        fields.push('category_id = ?');
        params.push(await resolveCategory(category_id, req.userId));
      }
      if (parcelado !== undefined) {
        fields.push('parcelado = ?');
        params.push(parcelado ? 1 : 0);
      }

      if (fields.length === 0) {
        throw new HttpError(400, 'Nenhum campo para atualizar');
      }

      params.push(id, req.userId);
      const { changes } = await dbAsync.run(
        `UPDATE ${table} SET ${fields.join(', ')} WHERE id = ? AND user_id = ?`,
        params
      );
      if (changes === 0) throw new HttpError(404, notFound);

      res.json({ message: `${label} atualizada` });
    } catch (err) {
      handleError(res, err);
    }
  }

  // DELETE /:id
  async function remove(req, res) {
    try {
      const { changes } = await dbAsync.run(
        `DELETE FROM ${table} WHERE id = ? AND user_id = ?`,
        [req.params.id, req.userId]
      );
      if (changes === 0) throw new HttpError(404, notFound);
      res.status(204).send();
    } catch (err) {
      handleError(res, err);
    }
  }

  // DELETE /grupo/:grupo - exclui todas as parcelas de uma compra/receita
  async function removeGrupo(req, res) {
    try {
      const { changes } = await dbAsync.run(
        `DELETE FROM ${table} WHERE parcela_grupo = ? AND user_id = ?`,
        [req.params.grupo, req.userId]
      );
      if (changes === 0) throw new HttpError(404, 'Parcelamento não encontrado');
      res.json({ removidas: changes });
    } catch (err) {
      handleError(res, err);
    }
  }

  return { create, list, update, remove, removeGrupo };
};
