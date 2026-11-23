/**
 * Limitação de tentativas (rate limiting) em memória, sem dependências (DEF-14).
 *
 * Conta requisições por chave (ex.: IP + e-mail) numa janela de tempo. Ao passar
 * do limite, responde 429 com o cabeçalho Retry-After.
 *
 * `contar` decide quais respostas contam:
 *   - 'todas'   : toda requisição (ex.: pedir código de recuperação)
 *   - 'falhas'  : só respostas 4xx (ex.: login com senha errada)
 *   - 'sucessos': só respostas 2xx (ex.: contas criadas)
 *
 * Em memória serve para um único processo da API (o caso do FinUp). Com mais
 * de um processo, o contador precisaria ficar num armazenamento compartilhado.
 */
function limiteTentativas({ janelaMs, max, chave, contar = 'todas', mensagem }) {
  const registros = new Map(); // chave -> { n, inicio }

  const limpeza = setInterval(() => {
    const agora = Date.now();
    for (const [k, r] of registros) if (agora - r.inicio >= janelaMs) registros.delete(k);
  }, Math.min(janelaMs, 60_000));
  limpeza.unref();

  return (req, res, next) => {
    const k = chave(req);
    const agora = Date.now();
    let r = registros.get(k);
    if (!r || agora - r.inicio >= janelaMs) {
      r = { n: 0, inicio: agora };
      registros.set(k, r);
    }

    if (r.n >= max) {
      const segundos = Math.ceil((r.inicio + janelaMs - agora) / 1000);
      res.set('Retry-After', String(segundos));
      return res.status(429).json({
        error: mensagem || `Muitas tentativas. Tente novamente em ${Math.ceil(segundos / 60)} minuto(s).`,
      });
    }

    if (contar === 'todas') {
      r.n++;
    } else {
      res.on('finish', () => {
        const s = res.statusCode;
        if ((contar === 'falhas' && s >= 400 && s < 500) || (contar === 'sucessos' && s >= 200 && s < 300)) {
          r.n++;
        }
      });
    }
    next();
  };
}

const ip = (req) => req.ip || req.socket.remoteAddress || '?';
const emailDoCorpo = (req) =>
  (typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '');

const QUINZE_MIN = 15 * 60 * 1000;

module.exports = {
  limiteTentativas,
  // 10 logins errados por IP + e-mail a cada 15 min
  limiteLogin: limiteTentativas({
    janelaMs: QUINZE_MIN, max: 10, contar: 'falhas',
    chave: (req) => `login:${ip(req)}:${emailDoCorpo(req)}`,
    mensagem: 'Muitas tentativas de login. Aguarde 15 minutos e tente de novo.',
  }),
  // 10 pedidos de código por IP a cada 15 min
  limiteEsqueciSenha: limiteTentativas({
    janelaMs: QUINZE_MIN, max: 10,
    chave: (req) => `esqueci:${ip(req)}`,
  }),
  // 20 tentativas de redefinir por IP + e-mail a cada 15 min (além das 5 por código)
  limiteRedefinirSenha: limiteTentativas({
    janelaMs: QUINZE_MIN, max: 20,
    chave: (req) => `redefinir:${ip(req)}:${emailDoCorpo(req)}`,
  }),
  // 50 contas criadas por IP por hora
  limiteCadastro: limiteTentativas({
    janelaMs: 60 * 60 * 1000, max: 50, contar: 'sucessos',
    chave: (req) => `cadastro:${ip(req)}`,
  }),
};
