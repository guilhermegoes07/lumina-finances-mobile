# Lumina Finances - Novas Funcionalidades Implementadas

## 1. Lançamentos Pendentes (Transações Futuras)

### Descrição
Sistema completo para gerenciar transações futuras e visualizar previsões financeiras.

### Funcionalidades Implementadas:
- ✅ Campo `isPending` adicionado ao modelo Transaction
- ✅ Checkbox "Transação pendente (futura)" na tela de adicionar/editar transações
- ✅ Tela de Previsão Financeira (ForecastScreen)
  - Navegação por meses (atual e próximos 12 meses)
  - Exibição de saldo previsto para final do mês
  - Detalhamento: entradas/saídas confirmadas e pendentes
  - Lista de transações pendentes do mês selecionado
- ✅ Toggle "Exibir Previsão de Saldo" nas configurações
- ✅ Dashboard atualizado:
  - Saldo exibido em amarelo quando previsão está ativa
  - Botão "Ver Previsão" para acesso rápido
  - Contador de transações pendentes
- ✅ Métodos no TransactionModel:
  - `getPredictedBalanceForMonth()` - calcula saldo previsto
  - `getMonthForecast()` - retorna detalhamento completo do mês

### Como Usar:
1. Ao adicionar uma transação, marque "Transação pendente (futura)"
2. Escolha uma data futura
3. Nas Configurações, ative "Exibir Previsão de Saldo"
4. No Dashboard, o saldo ficará amarelo e mostrará a previsão
5. Acesse "Previsão Financeira" no menu de Configurações para ver detalhes

---

## 2. Categorias Customizadas

### Descrição
Permite criar e gerenciar categorias personalizadas para organizar transações.

### Funcionalidades Implementadas:
- ✅ Tela de Gerenciamento de Categorias (CategoriesManagementScreen)
- ✅ Duas abas: Despesas e Receitas
- ✅ Adicionar nova categoria:
  - Nome da categoria
  - Seleção de ícone (20+ opções disponíveis)
  - Seleção de cor (10 cores pré-definidas)
- ✅ Excluir categorias existentes
- ✅ Integração com DatabaseService
- ✅ Método `updateCategory()` adicionado ao DatabaseService

### Como Usar:
1. Acesse Configurações > Gerenciar Categorias
2. Escolha a aba (Despesas ou Receitas)
3. Clique em "Adicionar Categoria"
4. Escolha nome, ícone e cor
5. As novas categorias aparecerão automaticamente nas transações

---

## 3. Caixinhas de Investimento

### Descrição
Simulador de investimentos com cálculo automático de rendimento, impostos (IR e IOF).

### Funcionalidades Implementadas:
- ✅ Modelo SavingsBox completo com:
  - Nome, valor inicial, datas de entrada/saída
  - Taxa CDI configurável (50% a 120%)
  - Descrição opcional
- ✅ Tela de Gerenciamento (SavingsBoxScreen)
- ✅ Cálculos automáticos:
  - Rendimento baseado em CDI (13.65% ao ano de referência)
  - Imposto de Renda regressivo:
    - 22.5% até 6 meses
    - 20% de 6 a 12 meses
    - 17.5% de 1 a 2 anos
    - 15% acima de 2 anos
  - IOF regressivo (primeiros 30 dias)
  - Lucro líquido (após impostos)
- ✅ Resumo de investimentos:
  - Total investido
  - Valor atual
  - Lucro líquido total
- ✅ Cartões individuais com detalhes
- ✅ Dialog de detalhes expandido

### Como Usar:
1. Acesse Configurações > Caixinhas de Investimento
2. Clique no botão "+" para adicionar nova caixinha
3. Preencha:
   - Nome (ex: "Reserva de Emergência")
   - Valor inicial
   - Data de entrada (pode ser no passado)
   - Data de saída (opcional, deixe em branco para cálculo até hoje)
   - Taxa CDI (use o slider, padrão 100%)
   - Descrição (opcional)
4. Visualize o resumo e detalhes de cada caixinha
5. Toque em uma caixinha para ver detalhamento completo

---

## Arquivos Criados/Modificados

### Novos Arquivos:
- `lib/models/savings_box.dart` - Modelo para caixinhas de investimento
- `lib/screens/forecast_screen.dart` - Tela de previsão financeira
- `lib/screens/categories_management_screen.dart` - Gerenciamento de categorias
- `lib/screens/savings_box_screen.dart` - Gerenciamento de caixinhas

### Arquivos Modificados:
- `lib/models/transaction.dart` - Adicionado campo isPending e métodos de previsão
- `lib/models/app_settings.dart` - Adicionado toggle showForecast
- `lib/main.dart` - Adicionado SavingsBoxModel provider
- `lib/services/database_service.dart` - Adicionado método updateCategory
- `lib/screens/transaction_screen.dart` - Adicionado checkbox para transações pendentes
- `lib/screens/settings_screen.dart` - Adicionados links para novas telas e toggle de previsão
- `lib/screens/dashboard_screen.dart` - Atualizado para mostrar saldo previsto em amarelo

---

## Navegação

### Configurações:
- Gerenciar Categorias
- Caixinhas de Investimento
- Previsão Financeira

### Dashboard:
- Botão "Ver Previsão" (quando previsão está ativa)
- Saldo em amarelo indica modo de previsão

### Transações:
- Checkbox "Transação pendente (futura)" ao adicionar/editar

---

## Notas Técnicas

### Compatibilidade:
- Migração automática para adicionar campo `isPending` em transações existentes
- Retrocompatível com dados anteriores
- Todos os dados são salvos localmente (SharedPreferences para caixinhas)

### Cálculos de Investimento:
- CDI de referência: 13.65% ao ano
- Fórmula: M = C * (1 + i)^t
- Taxa diária calculada: (CDI_rate * taxa_usuario) / 365
- Impostos aplicados sobre rendimento bruto

### Armazenamento:
- Transações: SharedPreferences com chave por usuário
- Caixinhas: SharedPreferences com chave por usuário
- Categorias: SQLite (database service)
