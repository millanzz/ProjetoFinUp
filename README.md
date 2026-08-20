# Sistema de Gestão Financeira

Projeto de extensão — Análise e Desenvolvimento de Sistemas.
Aplicativo de gestão financeira pessoal, full stack.

| Camada    | Tecnologia                          |
|-----------|-------------------------------------|
| Frontend  | Flutter (UI skeuomórfica azul/branco) |
| Backend   | Node.js + Express                   |
| Banco     | SQLite                              |
| Auth      | JWT + bcrypt                        |

## Como rodar

### 1. Backend
```bash
cd backend
npm install
cp .env.example .env   # ajuste o JWT_SECRET se quiser
npm run dev            # sobe em http://localhost:3000
```

### 2. Frontend
```bash
cd frontend
flutter pub get
# ajuste lib/core/api_config.dart conforme o dispositivo (ver README do frontend)
flutter run
```

## Funcionalidades

- Cadastro e login com JWT (sessão persistente no app)
- Dashboard com saldo, entradas/saídas e gráficos
- Receitas e despesas com categoria, data e parcelamento
- Histórico com filtro por período
- Metas financeiras com aportes e ícones
- Perfil com edição de dados e troca de senha

Detalhes de cada camada nos READMEs em `backend/` e `frontend/`.
