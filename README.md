# Lumina Finances - Aplicativo de Finanças Pessoais

Lumina Finances é um aplicativo mobile de código aberto para gerenciamento de finanças pessoais, desenvolvido com o objetivo de estudo e aplicação prática do framework Flutter.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow?style=for-the-badge)](https://github.com/guilhermegoes07/LuminaFinancesMobile)
[![Licença](https://img.shields.io/github/license/guilhermegoes07/LuminaFinancesMobile?style=for-the-badge)](LICENSE)

---

## Sobre o Projeto

O projeto busca oferecer uma interface limpa e intuitiva para que o usuário possa organizar suas receitas e despesas de forma eficiente. A ideia é criar uma ferramenta funcional enquanto aprofundo meus conhecimentos em Dart, Flutter e desenvolvimento de aplicações multiplataforma.

## ✨ Funcionalidades

O aplicativo oferece uma solução completa para gerenciamento de finanças pessoais:

### 📊 Gestão Financeira
* [x] **Cadastro de Transações**: Registro completo de receitas e despesas com categorização
* [x] **Categorização Inteligente**: Classificação automática de gastos (moradia, transporte, lazer, etc.)
* [x] **Dashboard Visual**: Gráficos interativos e resumos do balanço mensal com análise detalhada
* [x] **Histórico de Lançamentos**: Lista detalhada e pesquisável de todas as transações

### 🎯 Metas e Objetivos
* [x] **Metas Financeiras**: Definição e acompanhamento de objetivos financeiros
* [x] **Acompanhamento de Progresso**: Visualização em tempo real do progresso das metas
* [x] **Contribuições Regulares**: Sistema de depósitos para alcançar metas

### 💼 Investimentos
* [x] **Sugestões de Investimentos**: Recomendações baseadas no perfil do investidor
* [x] **Portfólio Completo**: Visualização detalhada de todos os investimentos
* [x] **Categorias de Risco**: Investimentos conservadores, moderados e arrojados
* [x] **Cálculo Automático de Rendimentos**: Acompanhamento em tempo real da rentabilidade

### 🔒 Segurança
* [x] **Autenticação Biométrica**: Acesso por impressão digital ou Face ID
* [x] **Código PIN**: Proteção adicional com PIN de 4 dígitos
* [x] **Criptografia de Dados**: Armazenamento seguro de informações sensíveis

### 📱 Recursos Adicionais
* [x] **Exportação de Dados**: Exportar transações em formato CSV ou PDF
* [x] **Relatórios em PDF**: Relatórios profissionais com gráficos e análises
* [x] **Assistente Virtual**: Chat com suporte automatizado para dúvidas
* [x] **Suporte por Email**: Contato direto com a equipe de suporte
* [x] **Tema Escuro**: Interface adaptável para conforto visual
* [x] **Multi-idioma**: Suporte para português brasileiro

## 🚀 Tecnologias Utilizadas

* **Framework**: Flutter 3.x
* **Linguagem**: Dart
* **Gerenciamento de Estado**: Provider
* **Armazenamento Local**: SQLite + Shared Preferences
* **Gráficos**: FL Chart
* **Exportação**: PDF & CSV
* **Segurança**: Local Auth (Biometria)
* **UI/UX**: Material Design 3

## ⚙️ Como Executar o Projeto

Para executar o projeto localmente, certifique-se de ter o [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado e configurado.

1.  **Clone o repositório:**
    ```sh
    git clone [https://github.com/guilhermegoes07/LuminaFinancesMobile.git](https://github.com/guilhermegoes07/LuminaFinancesMobile.git)
    ```

2.  **Acesse a pasta do projeto:**
    ```sh
    cd LuminaFinancesMobile
    ```

3.  **Instale as dependências:**
    ```sh
    flutter pub get
    ```

4.  **Execute a aplicação:**
    ```sh
    flutter run
    ```
    O Flutter se encarregará de iniciar a aplicação no emulador/dispositivo conectado.

## 📂 Estrutura de Pastas

A organização dos arquivos segue o padrão da comunidade Flutter:
```
LuminaFinancesMobile/
├── lib/                       # Código-fonte principal em Dart
│   ├── main.dart              # Ponto de entrada da aplicação
│   ├── models/                # Modelos de dados
│   ├── screens/               # Telas da aplicação
│   ├── services/              # Serviços (autenticação, banco de dados, PDF)
│   └── utils/                 # Utilitários e helpers
├── resources/                 # Assets como imagens, fontes, etc.
├── android/                   # Arquivos específicos da plataforma Android
├── ios/                       # Arquivos específicos da plataforma iOS
└── pubspec.yaml               # Definição do projeto e dependências
```

## 🎨 Capturas de Tela

O aplicativo oferece uma interface moderna e intuitiva com:
- Dashboard interativo com gráficos
- Gestão completa de transações
- Portfólio de investimentos
- Sistema de metas financeiras
- Configurações avançadas de segurança

## Autor

**Guilherme Goes**

* **GitHub**: [@guilhermegoes07](https://github.com/guilhermegoes07)
