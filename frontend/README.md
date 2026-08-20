# Gestão Financeira — Frontend (Flutter)

Aplicativo de gestão financeira pessoal (projeto de extensão — ADS).
UI skeuomórfica azul/branco, integrada ao back-end Node.js/Express + SQLite.

## Funcionalidades

- Login e cadastro com autenticação JWT (sessão persistente)
- Dashboard com saldo, resumo de entradas/saídas e gráficos (pizza e barras)
- Registro de receitas e despesas com categoria, data e parcelamento
- Exclusão de lançamentos (segurar o item na lista)
- Histórico com filtros por período (este mês, 3 meses, 6 meses, tudo)
- Metas financeiras: criação com ícone, aportes e exclusão
- Perfil: edição de nome/e-mail e alteração de senha

## Como rodar

1. Suba o back-end primeiro (veja `backend/README.md`):
   ```bash
   cd ../backend
   npm install
   npm run dev
   ```

2. Ajuste a URL da API em `lib/core/api_config.dart`:
   - **Emulador Android**: `http://10.0.2.2:3000` (padrão)
   - **Dispositivo físico**: `http://SEU_IP_LOCAL:3000` (ex.: `http://192.168.0.10:3000`)
   - **Web/desktop**: `http://localhost:3000`

3. Instale as dependências e execute:
   ```bash
   flutter pub get
   flutter create .
   flutter run
   ```

## Estrutura

```
lib/
├── core/         # tema, rotas e configuração da API
├── models/       # LancamentoModel, MetaModel
├── services/     # ApiClient + serviços (auth, lançamentos, categorias, metas)
├── screens/      # telas do app
└── widgets/      # componentes skeuomórficos reutilizáveis
```
