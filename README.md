# BPKar - Aplicativo de Caronas do Biopark

## 📋 Sobre o Projeto
BPKar é um aplicativo de caronas exclusivo para a comunidade do Biopark, desenvolvido para proporcionar uma solução segura, econômica e organizada de compartilhamento de transporte. O projeto visa resolver problemas comuns de mobilidade, promovendo o uso eficiente de recursos e fortalecendo os laços da comunidade.

## 🎯 Principais Objetivos
- Criar um sistema confiável de caronas para alunos e colaboradores do Biopark;
- Garantir transparência na divisão de custos entre motoristas e passageiros;
- Oferecer um ambiente seguro através de verificação de identidade e sistema de avaliações;
- Facilitar a organização de grupos de carona recorrentes;
- Reduzir o número de veículos circulando e o impacto ambiental.

## 🚀 Tecnologias Utilizadas
- Flutter/Dart
- Provider (gerenciamento de estado)
- Firebase Authentication
- Google Maps API
- Node.js com Express
- MySQL e MongoDB
- Firebase Cloud Messaging para notificações
- Docker para containerização

## 🏗️ Arquitetura do Projeto
O BPKar segue uma arquitetura de microsserviços, com:
- App Flutter: Interface do usuário com experiência nativa em dispositivos Android
- API RESTful: Backend Node.js que gerencia todas as regras de negócio
- Banco de Dados Relacional: MySQL para armazenamento de dados estruturados
- Firebase: Para autenticação e serviços de notificação push

## 💡 Funcionalidades
- Cadastro e verificação de usuários com vínculo ao Biopark
- Cadastro e validação de veículos para motoristas
- Criação e busca de caronas com definição de rotas
- Cálculo automático e transparente da divisão de custos
- Sistema de avaliação de usuários
- Chat integrado para comunicação entre motoristas e passageiros
- Formação de grupos de carona com controle de saldo
- Sistema de notificações para lembretes de viagens e pagamentos
- Controle de inadimplência para manter a confiança na plataforma

## 🛠️ Como Configurar o Ambiente de Desenvolvimento
### Pré-requisitos:
- Flutter SDK 3.0+
- Node.js 14+
- Docker e Docker Compose
- Conta no Firebase
- MySQL 8.0+

### Configuração do Backend:
- Clone o repositório:
git clone https://github.com/seu-usuario/bpkar.git
cd bpkar/backend
- Instale as dependências:
npm install
- Configure as variáveis de ambiente:
cp .env.example .env
- Edite o arquivo .env com suas configurações.
- Inicie o servidor de desenvolvimento:
npm run dev

### Configuração do Frontend:
- Na pasta do projeto: 
cd ../frontend
- Obtenha as dependências do Flutter: 
flutter pub get
- Execute o app em modo debug:
flutter run

## 👥 Equipe
- [Maria Fernanda Bordignon](https://github.com/mafebordignon)
- [Gabriel Costa](https://github.com/gabrielscostaa)
- [Pedro Piveta](https://github.com/PedroPiveta)
- [Gabriel Xander](https://github.com/Gabriel-Xander)
- [Daniel Rossano](https://github.com/DanielRossano)
