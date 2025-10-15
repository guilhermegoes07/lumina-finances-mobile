# Visual Guide - New Features

## 🎯 Feature 1: Pending Transactions & Forecast

### User Flow:
```
1. Add Transaction Screen
   ├─ Fill form (title, amount, date, category)
   ├─ ✅ Check "Transação pendente (futura)"
   └─ Select future date

2. Settings
   ├─ Enable "Exibir Previsão de Saldo" toggle
   └─ Navigate to "Previsão Financeira"

3. Dashboard
   ├─ Balance shown in YELLOW 🟡
   ├─ Shows predicted amount for month end
   ├─ "Ver Previsão" button appears
   └─ Counter: "X transações pendentes"

4. Forecast Screen
   ├─ Month selector (◀ Month/Year ▶)
   ├─ Predicted Balance Card (Yellow/Amber)
   ├─ Breakdown:
   │   ├─ Confirmed Income ✅
   │   ├─ Confirmed Expenses ✅
   │   ├─ Pending Income ⏱️
   │   └─ Pending Expenses ⏱️
   └─ List of pending transactions
```

### Visual Elements:
- **Yellow/Amber Theme**: Indicates prediction mode
- **Icons**: 
  - ✅ Confirmed transactions
  - ⏱️ Pending transactions
  - 📈 Trending up for forecast

---

## 🏷️ Feature 2: Custom Categories

### User Flow:
```
Settings → Gerenciar Categorias
├─ Tab: Despesas (Expenses)
│   ├─ List of existing categories
│   │   ├─ [Icon] Category Name
│   │   └─ [🗑️ Delete]
│   └─ [+ Adicionar Categoria]
│
└─ Tab: Receitas (Income)
    ├─ List of existing categories
    └─ [+ Adicionar Categoria]

Add Category Dialog:
├─ Text Field: "Nome da Categoria"
├─ Icon Selector (20+ options)
│   ├─ 🍴 Restaurant
│   ├─ 🚗 Car
│   ├─ 🏠 Home
│   ├─ 🎬 Movie
│   ├─ ❤️ Health
│   └─ ... (and more)
├─ Color Picker (10 colors)
│   ├─ 🔵 Blue
│   ├─ 🔴 Red
│   ├─ 🟢 Green
│   └─ ... (and more)
└─ [Cancel] [Adicionar]
```

### Visual Elements:
- **Icon Grid**: Visual icon selector with border on selection
- **Color Circles**: Color picker with checkmark on selected
- **Category Cards**: Icon + Name + Delete button

---

## 💰 Feature 3: Investment Savings Box (Caixinha)

### User Flow:
```
Settings → Caixinhas de Investimento
├─ Summary Card
│   ├─ Total Investido: R$ X,XXX.XX
│   ├─ Valor Atual: R$ X,XXX.XX
│   └─ Lucro Líquido: R$ XXX.XX
│
└─ Individual Savings Box Cards
    ├─ [📦 Caixinha Name] [⋮ Menu]
    ├─ Entry: DD/MM/YYYY
    ├─ Exit: DD/MM/YYYY (optional)
    ├─ Initial: R$ X,XXX.XX
    ├─ Current: R$ X,XXX.XX (green)
    └─ Net Profit: R$ XXX.XX (green box)

[+] Add New Caixinha (FAB)

Add/Edit Dialog:
├─ Text: "Nome"
├─ Number: "Valor Inicial" (R$)
├─ Date Picker: "Data de Entrada"
├─ Date Picker: "Data de Saída" (optional)
├─ Slider: "Taxa CDI: 100%" (50% - 120%)
├─ Text Area: "Descrição"
└─ [Cancel] [Adicionar/Salvar]

Details Dialog (on tap):
├─ Caixinha Name
├─ Description (if any)
├─ Taxa CDI: 100%
├─ Valor Inicial: R$ X,XXX.XX
├─ Valor Atual: R$ X,XXX.XX
├─ ──────────────────────
├─ Rendimento Bruto: R$ XXX.XX
├─ Imposto de Renda: - R$ XX.XX
├─ IOF: - R$ X.XX (if applicable)
├─ ──────────────────────
└─ Lucro Líquido: R$ XXX.XX ✨
```

### Visual Elements:
- **Green Theme**: For profits and positive values
- **Cards**: Clean card design with shadows
- **Summary**: Bold totals at top
- **Icons**: 💰, 📈, 💵 for financial elements
- **Slider**: Visual CDI rate selector

---

## 📱 Navigation Map

```
Main App
├─ Dashboard
│   ├─ Balance (Yellow if forecast ON)
│   └─ [Ver Previsão] → Forecast Screen
│
└─ Settings
    ├─ Gerenciar Categorias → Categories Screen
    ├─ Caixinhas de Investimento → Savings Box Screen
    ├─ Previsão Financeira → Forecast Screen
    └─ ⚙️ Toggles:
        └─ 🔄 Exibir Previsão de Saldo
```

---

## 🎨 Color Scheme

### Forecast/Pending:
- Primary: Yellow/Amber (#FFA000 - #FFC107)
- Confirmed: Green (#4CAF50)
- Pending: Orange (#FF9800)

### Categories:
- User selectable from 10 colors:
  - Blue, Red, Green, Orange, Purple
  - Pink, Teal, Amber, Indigo, Cyan

### Savings Box:
- Profit: Green (#4CAF50)
- Loss: Red (#F44336)
- Info: Blue (#2196F3)
- Cards: Material Design elevation

---

## 📊 Data Flow

```
User Input
    ↓
UI Screen (Flutter Widget)
    ↓
Model (ChangeNotifier)
    ↓
Storage Layer
    ├─ SharedPreferences (Transactions, Savings Boxes)
    └─ SQLite (Categories via DatabaseService)
    ↓
State Update (notifyListeners)
    ↓
UI Refresh (Provider)
```

---

## 🔢 Calculation Examples

### Pending Transaction Forecast:
```
Current Balance: R$ 5,000.00
+ Pending Income (Future): R$ 2,000.00
- Pending Expenses (Future): R$ 1,500.00
= Predicted Balance: R$ 5,500.00 🟡
```

### Savings Box Investment:
```
Initial Amount: R$ 10,000.00
Entry Date: 01/01/2024
Exit Date: 01/01/2025 (365 days)
CDI Rate: 100% of 13.65% = 13.65%

Daily Rate: 13.65% / 365 = 0.0374% per day
Current Value: R$ 10,000 * (1.000374)^365 = R$ 11,465.00

Gross Profit: R$ 1,465.00
Income Tax (720+ days = 15%): R$ 219.75
IOF (none after 30 days): R$ 0.00
Net Profit: R$ 1,245.25 ✨

Final Value: R$ 11,245.25
```

---

## 📖 Quick Start Guide

### For Pending Transactions:
1. Enable forecast in Settings
2. Add transactions with future dates
3. Check "Transação pendente"
4. Dashboard shows prediction in yellow

### For Custom Categories:
1. Go to Settings → Gerenciar Categorias
2. Add categories with icons and colors
3. Use them when creating transactions

### For Savings Box:
1. Go to Settings → Caixinhas de Investimento
2. Add investment with dates and CDI rate
3. View automatic calculations
4. Tap for detailed breakdown

---

## 🎉 All Features Are:
- ✅ Fully Implemented
- ✅ Tested
- ✅ Documented
- ✅ Ready to Use!
