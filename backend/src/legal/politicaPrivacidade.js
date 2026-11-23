/**
 * Política de Privacidade do FinUp — fonte única do texto.
 *
 * A API publica este conteúdo em GET /privacidade (página HTML, o endereço
 * público que lojas de aplicativos pedem) e GET /privacidade.json (o app exibe
 * na tela "Política de privacidade" e no cadastro).
 *
 * O texto descreve o que o código faz de fato (tabelas do db.js, dados salvos
 * no aparelho, bibliotecas do app). Campos entre colchetes devem ser
 * preenchidos pela equipe antes da publicação.
 */
const VERSAO = '1.0';
const ATUALIZADA_EM = '22/11/2026';
const CONTATO = process.env.PRIVACIDADE_CONTATO || '[e-mail de contato da equipe]';

const secoes = [
  {
    titulo: '1. Quem somos',
    paragrafos: [
      'O FinUp é um aplicativo de gestão financeira pessoal desenvolvido como projeto acadêmico (PIM) do curso de Análise e Desenvolvimento de Sistemas. A equipe do projeto é a controladora dos dados tratados pelo aplicativo, nos termos da Lei Geral de Proteção de Dados (Lei nº 13.709/2018 — LGPD).',
      `Contato para assuntos de privacidade: ${CONTATO}.`,
    ],
  },
  {
    titulo: '2. Quais dados coletamos',
    paragrafos: [
      'Dados da conta: nome, e-mail e senha. A senha nunca é guardada como foi digitada: armazenamos apenas um resumo criptográfico (hash bcrypt) que não permite recuperá-la.',
      'Dados que você registra: receitas e despesas (valor, descrição, data, categoria e parcelamento), categorias que você cria e metas financeiras (título, valor da meta, valor guardado e ícone).',
      'Recuperação de senha: quando você pede um código, guardamos apenas o hash do código, a validade (15 minutos) e o número de tentativas.',
      'No seu aparelho: o token de sessão (para manter você conectado) e a preferência de tema (claro ou escuro).',
      'Não coletamos localização, contatos, fotos, câmera, microfone, dados de cartão ou de conta bancária. O FinUp não se conecta a bancos: todos os valores são digitados por você. Não usamos ferramentas de publicidade nem de análise de comportamento.',
    ],
  },
  {
    titulo: '3. Para que usamos os dados',
    paragrafos: [
      'Para criar e proteger sua conta, permitir o login e a recuperação de senha, guardar seus lançamentos e metas e calcular saldos, totais e gráficos exibidos no aplicativo.',
      'A base legal é a execução do serviço que você solicitou ao criar a conta (art. 7º, V, da LGPD). Não usamos seus dados para nenhuma outra finalidade.',
    ],
  },
  {
    titulo: '4. Com quem compartilhamos',
    paragrafos: [
      'Não vendemos nem compartilhamos seus dados com terceiros para fins comerciais.',
      'Alguns serviços são necessários para o funcionamento: o provedor de hospedagem do servidor; o provedor de e-mail que envia o código de recuperação de senha (recebe apenas seu e-mail, seu primeiro nome e o código); e o serviço Google Fonts, de onde o aplicativo pode baixar a fonte de letra (o Google recebe o endereço IP do aparelho, como em qualquer acesso à internet).',
    ],
  },
  {
    titulo: '5. Por quanto tempo guardamos',
    paragrafos: [
      'Mantemos os dados enquanto sua conta existir. Ao excluir a conta, seus dados (conta, lançamentos, categorias, metas e pedidos de recuperação) são apagados imediatamente do banco de dados do servidor.',
      'Códigos de recuperação de senha deixam de valer em 15 minutos.',
    ],
  },
  {
    titulo: '6. Seus direitos',
    paragrafos: [
      'Pela LGPD (art. 18) você pode: confirmar e acessar seus dados (todos aparecem no próprio aplicativo); corrigir nome e e-mail (Perfil → Editar perfil); excluir sua conta e todos os dados (Perfil → Excluir conta); e pedir informações sobre o tratamento ou a portabilidade dos dados pelo contato da seção 1.',
    ],
  },
  {
    titulo: '7. Segurança',
    paragrafos: [
      'Senhas e códigos de recuperação são guardados apenas como hash; cada usuário só acessa os próprios dados; as sessões expiram em 7 dias e são encerradas quando a senha é trocada ou redefinida; tentativas repetidas de login e de recuperação de senha são bloqueadas temporariamente; e, em produção, a comunicação entre o aplicativo e o servidor é feita por HTTPS (criptografada).',
    ],
  },
  {
    titulo: '8. Crianças e adolescentes',
    paragrafos: [
      'O FinUp não é destinado a menores de 18 anos sem a supervisão de um responsável.',
    ],
  },
  {
    titulo: '9. Alterações nesta política',
    paragrafos: [
      'Se esta política mudar, a nova versão será publicada neste endereço e no aplicativo, com a data de atualização.',
    ],
  },
];

const escapar = (t) => String(t).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

function html() {
  const corpo = secoes
    .map((s) => `<h2>${escapar(s.titulo)}</h2>\n${s.paragrafos.map((p) => `<p>${escapar(p)}</p>`).join('\n')}`)
    .join('\n');
  return `<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Política de Privacidade — FinUp</title>
<style>
  body { font-family: Roboto, Arial, sans-serif; max-width: 760px; margin: 0 auto; padding: 24px 16px 48px; color: #1e293b; line-height: 1.6; background: #f4f6fb; }
  h1 { color: #0e1b3d; margin-bottom: 4px; } h2 { color: #0e1b3d; font-size: 1.15rem; margin-top: 28px; }
  .sub { color: #475569; margin-top: 0; }
</style></head><body>
<h1>Política de Privacidade — FinUp</h1>
<p class="sub">Versão ${VERSAO} · atualizada em ${ATUALIZADA_EM}</p>
${corpo}
</body></html>`;
}

module.exports = {
  json: () => ({ versao: VERSAO, atualizada_em: ATUALIZADA_EM, secoes }),
  html,
};
