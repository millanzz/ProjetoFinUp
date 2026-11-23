# Hospedar a API do FinUp na Oracle Cloud (grátis, com HTTPS)

Resultado: a API fica no ar 24 h em `https://SEU-NOME.duckdns.org`. O certificado HTTPS vem do Let's Encrypt e é renovado sozinho. O banco fica no disco do servidor e tem backup diário. Custo: zero, no plano **Always Free** da Oracle.

Como funciona: o **Caddy** recebe o HTTPS nas portas 443 e 80 e repassa para a API, que escuta só em `127.0.0.1:3000`. A API roda como serviço do sistema (`finup-api`) com `NODE_ENV=production` e `TRUST_PROXY=1`, então recusa qualquer acesso que não tenha chegado por HTTPS.

## 1. Criar a conta na Oracle (você)

1. Acesse <https://signup.cloud.oracle.com/> e crie a conta. Escolha uma **Home Region** próxima, por exemplo *Brazil East (São Paulo)*. Ela não pode ser trocada depois.
2. O cartão é pedido só para verificação. Contas Always Free não são cobradas enquanto você usa apenas recursos marcados como *Always Free*.

## 2. Criar o servidor

Menu → **Compute → Instances → Create instance**:

| Campo | Valor |
|---|---|
| Name | `finup-api` |
| Image | **Canonical Ubuntu 24.04** |
| Shape | **VM.Standard.A1.Flex** (Ampere, 1 OCPU e 6 GB) — *Always Free*. Se aparecer "Out of capacity", use **VM.Standard.E2.1.Micro** (também *Always Free*) |
| Networking | deixe criar a VCN nova, com **Assign a public IPv4 address** marcado |
| SSH keys | **Save private key**: guarde o arquivo `.key` baixado, por exemplo em `%USERPROFILE%\.ssh\finup.key` (a pasta `.ssh` dentro do seu usuário) |

Clique em **Create**. Quando ficar *Running*, anote o **Public IP address**.

## 3. Abrir as portas 80 e 443 na Oracle

Na instância → **Subnet** → **Security Lists** → *Default Security List* → **Add Ingress Rules**. Adicione duas regras:

| Source CIDR | IP Protocol | Destination Port |
|---|---|---|
| `0.0.0.0/0` | TCP | `80` |
| `0.0.0.0/0` | TCP | `443` |

A porta 80 é necessária para o Let's Encrypt emitir o certificado.

## 4. Endereço grátis (DuckDNS)

1. Entre em <https://www.duckdns.org/> (login com GitHub ou Google).
2. Crie um subdomínio, por exemplo `finup-pim`, e em **current ip** coloque o **IP público** da instância → **update ip**.
3. O endereço da API será `finup-pim.duckdns.org`.

O IP público da instância não muda enquanto ela existir, então isso é feito uma vez só.

## 5. Instalar (no servidor)

No PowerShell do seu computador:

```powershell
ssh -i $HOME\.ssh\finup.key ubuntu@IP_PUBLICO
```

Se o Windows reclamar das permissões do `.key`, ajuste-as uma vez com:

```powershell
icacls $HOME\.ssh\finup.key /inheritance:r /grant:r "$($env:USERNAME):R"
```

Já no servidor:

```bash
git clone -b redesign-fusao-tema-escuro https://github.com/millanzz/ProjetoFinUp.git
cd ProjetoFinUp
sudo bash deploy/oracle/instalar.sh finup-pim.duckdns.org email-de-contato@exemplo.com
```

Depois que o PR for juntado na `main`, o `-b redesign-fusao-tema-escuro` deixa de ser necessário. O e-mail aparece na Política de Privacidade.

No fim, abra `https://finup-pim.duckdns.org/`. A resposta deve ser `{"status":"ok",…}`, com o cadeado no navegador.

## 6. Apontar o app para a API

No seu computador, dentro de `frontend`:

```powershell
flutter build apk --release --dart-define=API_URL=https://finup-pim.duckdns.org
```

## Manutenção

| Tarefa | Comando (no servidor) |
|---|---|
| Ver se está no ar | `systemctl status finup-api caddy` |
| Ver o log da API | `sudo journalctl -u finup-api -f` |
| Atualizar para a versão nova do GitHub | `cd ~/ProjetoFinUp && sudo bash deploy/oracle/atualizar.sh` (faz backup antes) |
| Configuração (segredo, SMTP, contato) | `sudo nano /etc/finup/finup.env` e depois `sudo systemctl restart finup-api` |
| Backups (diários às 03:30, guarda 14) | `ls /var/lib/finup/backups/` |
| Backup na hora | `sudo -u finup /usr/local/bin/finup-backup` |
| Copiar um backup para o seu PC | `scp -i $HOME\.ssh\finup.key ubuntu@IP_PUBLICO:/var/lib/finup/backups/finup-AAAA-MM-DD.db .` |

**"Esqueci minha senha":** sem SMTP configurado, o código de recuperação só aparece no log (`journalctl -u finup-api`). Para enviar e-mail de verdade, preencha `SMTP_*` em `/etc/finup/finup.env`, por exemplo com uma senha de app do Gmail.

**Cuidados:**
- O `JWT_SECRET` é gerado na instalação e fica só em `/etc/finup/finup.env`. Se ele for trocado, todos os usuários precisam entrar de novo.
- Os backups ficam no mesmo servidor. Copie um para fora de vez em quando: se a instância for apagada, eles vão junto.
- A Oracle pode recuperar instâncias Always Free que ficam **ociosas** (CPU muito baixa por 7 dias) em contas sem cartão ativo como pagamento. Se receber esse aviso, a saída é converter a conta para *Pay As You Go*. Os recursos Always Free continuam sem custo.

## Problemas comuns

| Sintoma | Causa provável |
|---|---|
| O navegador não abre o endereço | Portas 80/443 não liberadas na Security List (passo 3), ou o DuckDNS com IP errado |
| Erro de certificado nos primeiros minutos | O Caddy ainda está emitindo. Veja `sudo journalctl -u caddy -n 50` |
| `{"error":"Use HTTPS para acessar a API"}` | Foi acessado por `http://` direto na porta 3000. Use o endereço `https://` |
| A API não sobe | `sudo journalctl -u finup-api -n 50` |
