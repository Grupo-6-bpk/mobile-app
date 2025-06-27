# 🚗 BPKar - Aplicativo de Caronas do Biopark

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-14+-green.svg)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Sobre o Projeto

O **BPKar** é um aplicativo de caronas exclusivo para a comunidade do Biopark, desenvolvido para proporcionar uma solução segura, econômica e sustentável de compartilhamento de transporte. O projeto visa resolver problemas comuns de mobilidade urbana, promovendo o uso eficiente de recursos e fortalecendo os laços da comunidade acadêmica e profissional.

### 🌟 Diferenciais
- **Segurança**: Verificação obrigatória de vínculo com o Biopark
- **Transparência**: Cálculo automático e justo da divisão de custos
- **Sustentabilidade**: Redução do número de veículos em circulação
- **Comunidade**: Fortalecimento dos laços entre alunos e colaboradores

## 🎯 Principais Objetivos

- ✅ Criar um sistema confiável de caronas para alunos e colaboradores do Biopark
- ✅ Garantir transparência total na divisão de custos entre motoristas e passageiros
- ✅ Oferecer um ambiente seguro através de verificação de identidade e sistema de avaliações
- ✅ Facilitar a organização de grupos de carona recorrentes
- ✅ Reduzir o impacto ambiental através do compartilhamento de veículos
- ✅ Promover integração e networking entre membros da comunidade

## 🚀 Tecnologias Utilizadas

### Frontend
- **Flutter/Dart** - Framework de desenvolvimento mobile multiplataforma
- **Provider** - Gerenciamento de estado reativo
- **Google Maps API** - Integração com mapas e rotas

### Backend
- **Node.js** - Runtime JavaScript para servidor
- **Express.js** - Framework web minimalista
- **MySQL** - Banco de dados relacional para dados estruturados
- **MongoDB** - Banco de dados NoSQL para dados não estruturados

### Serviços em Nuvem
- **Firebase Authentication** - Autenticação segura de usuários
- **Firebase Cloud Messaging** - Sistema de notificações push
- **Google Cloud Platform** - Hospedagem e serviços de nuvem

### DevOps
- **Docker** - Containerização de aplicações
- **Docker Compose** - Orquestração de containers
- **Git** - Controle de versão

## 🏗️ Arquitetura do Sistema

O BPKar segue uma **arquitetura de microsserviços** moderna e escalável:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   App Flutter   │    │   API RESTful   │    │   Banco MySQL   │
│  (Interface)    │◄──►│  (Node.js)      │◄──►│  (Dados Rel.)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Firebase      │
                       │  (Auth + Push)  │
                       └─────────────────┘
```

### Componentes Principais:
- **App Flutter**: Interface nativa para Android com experiência otimizada
- **API RESTful**: Backend Node.js que centraliza todas as regras de negócio
- **MySQL**: Armazenamento de dados estruturados (usuários, caronas, pagamentos)
- **MongoDB**: Dados não estruturados (logs, analytics, chat)
- **Firebase**: Autenticação segura e notificações push em tempo real

## 💡 Funcionalidades

### 👤 Gestão de Usuários
- [x] Cadastro e verificação de usuários com vínculo ao Biopark
- [x] Sistema de perfis com informações pessoais e profissionais
- [x] Validação de documentos e comprovantes de vínculo
- [x] Sistema de avaliação e reputação de usuários

### 🚗 Gestão de Veículos
- [x] Cadastro e validação de veículos para motoristas
- [x] Verificação de documentação veicular
- [x] Controle de capacidade e características do veículo

### 🗺️ Sistema de Caronas
- [x] Criação de caronas com definição de rotas otimizadas
- [x] Busca inteligente de caronas por proximidade e horário
- [x] Cálculo automático e transparente da divisão de custos
- [x] Agendamento de caronas recorrentes

### 💬 Comunicação
- [x] Chat integrado para comunicação entre motoristas e passageiros
- [x] Notificações push para lembretes de viagens
- [x] Alertas de pagamentos e mudanças de status

### 👥 Grupos e Comunidade
- [x] Formação de grupos de carona com controle de saldo
- [x] Sistema de convites para grupos privados
- [x] Ranking de usuários mais ativos

### 💰 Sistema Financeiro
- [x] Controle de pagamentos e recebimentos
- [x] Histórico completo de transações
- [x] Sistema de créditos e débitos
- [x] Controle de inadimplência

## 🛠️ Configuração do Ambiente de Desenvolvimento

### Pré-requisitos
Certifique-se de ter instalado:

- [Flutter SDK 3.0+](https://flutter.dev/docs/get-started/install)
- [Node.js 14+](https://nodejs.org/)
- [Docker](https://www.docker.com/) e [Docker Compose](https://docs.docker.com/compose/)
- [MySQL 8.0+](https://dev.mysql.com/downloads/)
- Conta no [Firebase](https://firebase.google.com/)
- [Git](https://git-scm.com/)

### 🔧 Configuração do Backend

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/seu-usuario/bpkar.git
   cd bpkar/backend
   ```

2. **Instale as dependências:**
   ```bash
   npm install
   ```

3. **Configure as variáveis de ambiente:**
   ```bash
   cp .env.example .env
   ```
   Edite o arquivo `.env` com suas configurações específicas.

4. **Inicie o banco de dados (Docker):**
   ```bash
   docker-compose up -d
   ```

5. **Execute as migrações:**
   ```bash
   npm run migrate
   ```

6. **Inicie o servidor de desenvolvimento:**
   ```bash
   npm run dev
   ```

### 📱 Configuração do Frontend

1. **Navegue para a pasta do frontend:**
   ```bash
   cd ../frontend
   ```

2. **Instale as dependências do Flutter:**
   ```bash
   flutter pub get
   ```

3. **Configure o Firebase:**
   - Adicione os arquivos de configuração do Firebase (`google-services.json` para Android)
   - Configure as chaves de API no arquivo de configuração

4. **Execute o aplicativo:**
   ```bash
   flutter run
   ```

### 🐳 Usando Docker (Alternativa)

Para uma configuração mais rápida, você pode usar Docker:

```bash
# Inicie todos os serviços
docker-compose up -d

# Visualize os logs
docker-compose logs -f
```

## 📊 Estrutura do Projeto

```
bpkar/
├── 📁 backend/
│   ├── 📁 src/
│   │   ├── 📁 controllers/
│   │   ├── 📁 models/
│   │   ├── 📁 routes/
│   │   ├── 📁 services/
│   │   └── 📁 utils/
│   ├── 📁 tests/
│   ├── 📄 package.json
│   └── 📄 .env.example
├── 📁 frontend/
│   ├── 📁 lib/
│   │   ├── 📁 models/
│   │   ├── 📁 providers/
│   │   ├── 📁 screens/
│   │   ├── 📁 services/
│   │   └── 📁 widgets/
│   ├── 📁 assets/
│   └── 📄 pubspec.yaml
├── 📁 docs/
├── 📄 docker-compose.yml
├── 📄 README.md
└── 📄 LICENSE
```

## 🧪 Testes

### Backend
```bash
cd backend
npm test
npm run test:coverage
```

### Frontend
```bash
cd frontend
flutter test
flutter test --coverage
```

## 🚀 Deploy

### Ambiente de Produção
1. Configure as variáveis de ambiente para produção
2. Execute o build do Flutter: `flutter build apk --release`
3. Deploy do backend: `npm run build && npm start`

### CI/CD
O projeto utiliza GitHub Actions para integração e deploy contínuo.

## 🤝 Como Contribuir

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### 📋 Padrões de Código
- Siga as convenções do Dart/Flutter para o frontend
- Use ESLint e Prettier para o backend Node.js
- Escreva testes para novas funcionalidades
- Documente APIs usando JSDoc

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Equipe de Desenvolvimento

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/mafebordignon">
        <img src="https://github.com/mafebordignon.png" width="100px;" alt=""/><br>
        <sub><b>Maria Fernanda Bordignon</b></sub>
      </a><br>
      <sub>Project Manegement</sub>
    </td>
    <td align="center">
      <a href="https://github.com/gabrielscostaa">
        <img src="https://github.com/gabrielscostaa.png" width="100px;" alt=""/><br>
        <sub><b>Gabriel Costa</b></sub>
      </a><br>
      <sub>Backend Developer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/PedroPiveta">
        <img src="https://github.com/PedroPiveta.png" width="100px;" alt=""/><br>
        <sub><b>Pedro Piveta</b></sub>
      </a><br>
      <sub>Full Stack Developer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/Gabriel-Xander">
        <img src="https://github.com/Gabriel-Xander.png" width="100px;" alt=""/><br>
        <sub><b>Gabriel Xander</b></sub>
      </a><br>
      <sub>Mobile Developer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/DanielRossano">
        <img src="https://github.com/DanielRossano.png" width="100px;" alt=""/><br>
        <sub><b>Daniel Rossano</b></sub>
      </a><br>
      <sub>DevOps Engineer</sub>
    </td>
  </tr>
</table>


