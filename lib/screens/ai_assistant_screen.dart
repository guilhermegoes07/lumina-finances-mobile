import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../models/financial_goal.dart';
import 'package:intl/intl.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  List<double> _typingDotOpacities = [1.0, 0.8, 0.6];

  // Adicionar padrões dos brasileiros para comparação
  final Map<String, double> _tipicalBudgetPercentages = {
    'Moradia': 0.30,
    'Alimentação': 0.15,
    'Transporte': 0.10,
    'Saúde': 0.10,
    'Educação': 0.05,
    'Lazer': 0.05,
    'Vestuário': 0.05,
    'Poupança/Investimentos': 0.15,
    'Outros': 0.05,
  };

  @override
  void initState() {
    super.initState();
    // Iniciar animação das bolinhas de digitação
    _startTypingAnimation();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendWelcomeMessage() {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
    
    // Obter análises financeiras avançadas
    final healthData = _calculateFinancialHealth();
    final budgetData = _analyzeBudget();
    
    // Análise básica dos dados financeiros
    final balance = transactionModel.balance;
    final goals = goalModel.goals;
    final hasGoals = goals.isNotEmpty;
    final totalIncome = transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpenses = transactionModel.expenses.fold(0.0, (sum, item) => sum + item.amount);
    
    // Criar a mensagem de boas-vindas mais personalizada
    String welcomeMessage = 'Olá ${userProfile.name}, sou seu assistente de finanças pessoais! ';
    
    // Adicionar análise de saúde financeira
    welcomeMessage += 'Sua saúde financeira está ${healthData['status'].toLowerCase()}. ';
    
    if (balance > 0) {
      welcomeMessage += 'Você tem um saldo positivo de R\$ ${balance.toStringAsFixed(2)}, o que é ótimo! ';
      
      // Adicionar mensagem sobre taxa de poupança
      final savingsRate = healthData['savingsRate'] as double;
      if (savingsRate > 0.2) {
        welcomeMessage += 'Está conseguindo poupar ${(savingsRate * 100).toStringAsFixed(1)}% da sua renda, excelente! ';
      } else if (savingsRate > 0.1) {
        welcomeMessage += 'Está poupando ${(savingsRate * 100).toStringAsFixed(1)}% da sua renda, está no caminho certo! ';
      } else if (savingsRate > 0) {
        welcomeMessage += 'Está poupando apenas ${(savingsRate * 100).toStringAsFixed(1)}% da sua renda, podemos melhorar isso. ';
      }
    } else if (balance < 0) {
      welcomeMessage += 'Notei que seu saldo está negativo (R\$ ${balance.toStringAsFixed(2)}). Posso ajudar com estratégias para reverter isso. ';
    } else {
      welcomeMessage += 'Seu saldo está zerado. Vamos trabalhar juntos para melhorar sua situação financeira. ';
    }
    
    // Adicionar mensagem sobre o orçamento
    if (budgetData['concernCategories'].isNotEmpty) {
      final concerns = budgetData['concernCategories'] as List<String>;
      if (concerns.length == 1) {
        welcomeMessage += 'Notei que seus gastos com ${concerns.first} estão acima do recomendado. ';
      } else if (concerns.length <= 3) {
        welcomeMessage += 'Observei que seus gastos com ${concerns.join(", ")} estão acima do ideal. ';
      } else {
        welcomeMessage += 'Identifiquei várias categorias de gastos acima do recomendado. ';
      }
    }
    
    // Mensagem sobre metas
    if (hasGoals) {
      welcomeMessage += 'Você tem ${goals.length} meta(s) financeira(s) definida(s). ';
      
      // Verificar progresso das metas
      int completedGoals = 0;
      int goodProgressGoals = 0;
      
      for (var goal in goals) {
        final progress = goal.currentAmount / goal.targetAmount;
        if (progress >= 1.0) {
          completedGoals++;
        } else if (progress >= 0.5) {
          goodProgressGoals++;
        }
      }
      
      if (completedGoals > 0) {
        welcomeMessage += 'Parabéns por já ter completado $completedGoals meta(s)! ';
      }
      
      if (goodProgressGoals > 0) {
        welcomeMessage += 'Está fazendo bom progresso em $goodProgressGoals meta(s). ';
      }
    } else {
      welcomeMessage += 'Ainda não vejo metas financeiras definidas. Criar metas pode ajudar a manter o foco no longo prazo. ';
    }
    
    welcomeMessage += 'Como posso ajudar você hoje?';
    
    // Adicionar sugestões mais personalizadas com base nos dados
    List<String> suggestions = [];
    
    // Sugestões baseadas na relação receitas/despesas
    final expenseToIncomeRatio = healthData['expenseToIncomeRatio'] as double;
    if (expenseToIncomeRatio > 0.9) {
      suggestions.add('Suas despesas estão muito próximas ou ultrapassam suas receitas. Vamos analisar onde reduzir gastos?');
    } else if (expenseToIncomeRatio > 0.7) {
      suggestions.add('Você gasta ${(expenseToIncomeRatio * 100).toStringAsFixed(0)}% da sua renda. Posso ajudar a economizar mais?');
    }
    
    // Sugestões baseadas na categoria de maior gasto
    if (budgetData['topExpenseCategory'] != null) {
      final topCategory = budgetData['topExpenseCategory'] as String;
      final topAmount = budgetData['topExpenseAmount'] as double;
      
      if (totalIncome > 0 && topAmount / totalIncome > 0.25) {
        suggestions.add('Seus gastos com $topCategory representam ${((topAmount / totalIncome) * 100).toStringAsFixed(0)}% da sua renda. Vamos analisar isso?');
      }
    }
    
    // Sugestões sobre metas
    if (!hasGoals) {
      suggestions.add('Criar metas financeiras é essencial para seu futuro. Posso ajudar a definir metas realistas.');
    } else if (goals.length < 3) {
      suggestions.add('Que tal diversificar suas metas financeiras? Posso sugerir algumas ideias.');
    }
    
    // Sugestão baseada na saúde financeira
    final score = healthData['score'] as int;
    if (score < 50) {
      suggestions.add('Sua pontuação de saúde financeira está em $score/100. Vamos trabalhar para melhorar isso?');
    }
    
    // Adicionar mais sugestões específicas
    if (transactionModel.transactions.isEmpty) {
      suggestions.add('Comece registrando suas transações para obter análises mais precisas e personalizadas.');
    }
    
    setState(() {
      _messages.add({
        'isUser': false,
        'message': welcomeMessage,
        'suggestions': suggestions,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    _messageController.clear();
    
    setState(() {
      _messages.add({
        'isUser': true,
        'message': userMessage,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });
    
    // Simular resposta após breve delay
    Future.delayed(const Duration(seconds: 1), () {
      _generateResponse(userMessage);
    });
    
    // Scroll para o final
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _generateResponse(String userMessage) {
    // Analisar a mensagem e gerar uma resposta com base nas finanças do usuário
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    
    // Obter análises financeiras avançadas
    final healthData = _calculateFinancialHealth();
    final budgetData = _analyzeBudget();
    
    String response = '';
    List<String> suggestions = [];
    
    // Converter para minúsculas para facilitar a verificação
    final lowerMsg = userMessage.toLowerCase();
    
    // Verificar saudação/apresentação
    if (_isGreeting(lowerMsg)) {
      response = 'Olá ${userProfile.name}! Estou aqui para ajudar com suas finanças. O que gostaria de saber hoje?';
      suggestions.add('Como está minha saúde financeira?');
      suggestions.add('Onde estou gastando mais?');
      suggestions.add('Como melhorar minhas finanças?');
    }
    // Mensagens sobre saúde financeira geral
    else if (lowerMsg.contains('saúde financeira') || 
             lowerMsg.contains('situação financeira') ||
             lowerMsg.contains('como estou') ||
             lowerMsg.contains('minha pontuação')) {
      
      final score = healthData['score'] as int;
      final status = healthData['status'] as String;
      final savingsRate = healthData['savingsRate'] as double;
      
      response = 'Sua saúde financeira está ${status.toLowerCase()}, com uma pontuação de $score/100. ';
      
      if (score >= 80) {
        response += 'Parabéns! Você está administrando muito bem suas finanças. ';
      } else if (score >= 60) {
        response += 'Você está num bom caminho, mas ainda há espaço para melhorias. ';
      } else if (score >= 40) {
        response += 'Sua situação é regular, mas requer atenção em alguns pontos. ';
      } else {
        response += 'Sua situação financeira precisa de atenção urgente. ';
      }
      
      // Adicionar detalhes sobre a taxa de poupança
      response += 'Atualmente ';
      if (savingsRate <= 0) {
        response += 'você não está conseguindo poupar nada, o que é preocupante. ';
        suggestions.add('Como posso começar a poupar dinheiro?');
      } else {
        response += 'você está poupando ${(savingsRate * 100).toStringAsFixed(1)}% da sua renda. ';
        if (savingsRate < 0.1) {
          response += 'Especialistas recomendam poupar pelo menos 10% da renda.';
          suggestions.add('Como aumentar minha taxa de poupança?');
        } else if (savingsRate < 0.2) {
          response += 'Você está no caminho certo, mas aumentar para 20% seria ideal.';
        } else {
          response += 'Excelente taxa de poupança!';
        }
      }
      
      // Adicionar sugestões baseadas na pontuação
      if (score < 70) {
        if (budgetData['concernCategories'].isNotEmpty) {
          suggestions.add('Quais categorias estão consumindo muito do meu orçamento?');
        }
        if (healthData['expenseToIncomeRatio'] > 0.8) {
          suggestions.add('Como reduzir minhas despesas?');
        }
      }
    }
    // Mensagens sobre saldo
    else if (lowerMsg.contains('saldo') || 
             lowerMsg.contains('quanto tenho') ||
             lowerMsg.contains('meu dinheiro') ||
             lowerMsg.contains('quanto sobrou')) {
      
      final balance = transactionModel.balance;
      final totalIncome = transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount);
      final totalExpenses = transactionModel.expenses.fold(0.0, (sum, item) => sum + item.amount);
      
      response = 'Seu saldo atual é de R\$ ${balance.toStringAsFixed(2)}. ';
      
      // Adicionar mais contexto sobre receitas e despesas
      if (totalIncome > 0 || totalExpenses > 0) {
        response += 'Você teve receitas de R\$ ${totalIncome.toStringAsFixed(2)} e despesas de R\$ ${totalExpenses.toStringAsFixed(2)}. ';
      }
      
      if (balance > 0) {
        if (balance > totalIncome * 0.5) {
          response += 'Você está economizando mais de 50% da sua renda, excelente trabalho!';
          suggestions.add('Onde investir meu dinheiro guardado?');
        } else {
          response += 'Você está no positivo, o que é bom!';
          suggestions.add('Como aumentar meu saldo disponível?');
        }
      } else if (balance < 0) {
        response += 'Infelizmente você está no negativo.';
        suggestions.add('Como equilibrar minhas contas?');
        suggestions.add('Onde posso cortar gastos?');
      } else {
        response += 'Seu saldo está zerado.';
        suggestions.add('Como evitar ficar sem dinheiro no fim do mês?');
      }
    } 
    // Mensagens sobre gastos
    else if (lowerMsg.contains('gasto') || 
             lowerMsg.contains('despesa') ||
             lowerMsg.contains('saída') ||
             lowerMsg.contains('onde gasto') ||
             lowerMsg.contains('gastando')) {
      
      final totalExpenses = transactionModel.expenses.fold(0.0, (sum, item) => sum + item.amount);
      final totalIncome = transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount);
      
      // Verificar se a pergunta é sobre uma categoria específica
      String? specificCategory;
      for (var expense in transactionModel.expenses) {
        if (lowerMsg.contains(expense.category.toLowerCase())) {
          specificCategory = expense.category;
          break;
        }
      }
      
      if (specificCategory != null) {
        // Resposta para uma categoria específica
        final categoryExpenses = transactionModel.expenses
            .where((e) => e.category == specificCategory)
            .fold(0.0, (sum, item) => sum + item.amount);
        
        final percentOfTotal = totalExpenses > 0 ? (categoryExpenses / totalExpenses) * 100 : 0;
        final percentOfIncome = totalIncome > 0 ? (categoryExpenses / totalIncome) * 100 : 0;
        
        response = 'Seus gastos com $specificCategory totalizam R\$ ${categoryExpenses.toStringAsFixed(2)}, ';
        response += 'representando ${percentOfTotal.toStringAsFixed(1)}% das suas despesas totais ';
        response += 'e ${percentOfIncome.toStringAsFixed(1)}% da sua renda. ';
        
        // Verificar se esta categoria está acima do recomendado
        if (budgetData['concernCategories'].contains(specificCategory)) {
          response += 'Este gasto está acima do recomendado para esta categoria.';
          suggestions.add('Como reduzir gastos com $specificCategory?');
        } else {
          response += 'Este gasto está dentro de limites razoáveis.';
        }
      } else {
        // Resposta geral sobre gastos
        response = 'Suas despesas totais são de R\$ ${totalExpenses.toStringAsFixed(2)}';
        
        if (totalIncome > 0) {
          final expenseRatio = totalExpenses / totalIncome;
          response += ', o que representa ${(expenseRatio * 100).toStringAsFixed(1)}% da sua renda. ';
          
          if (expenseRatio > 1) {
            response += 'Suas despesas estão superando sua renda, o que é preocupante.';
            suggestions.add('Como reduzir minhas despesas urgentemente?');
          } else if (expenseRatio > 0.9) {
            response += 'Você está gastando quase toda sua renda, o que deixa pouca margem para imprevistos.';
            suggestions.add('Como criar uma reserva de emergência?');
          } else if (expenseRatio > 0.7) {
            response += 'Sua taxa de gastos está em um nível moderado.';
          } else {
            response += 'Parabéns! Você está mantendo seus gastos bem controlados.';
          }
        } else {
          response += '.';
        }
        
        // Adicionar informações sobre categorias principais
        if (budgetData['topExpenseCategory'] != null) {
          final topCategory = budgetData['topExpenseCategory'] as String;
          final topAmount = budgetData['topExpenseAmount'] as double;
          
          response += ' Sua maior categoria de despesa é "${topCategory}" com R\$ ${topAmount.toStringAsFixed(2)}.';
          
          // Adicionar sugestões relacionadas
          suggestions.add('Detalhar gastos com ${topCategory}');
          
          if (budgetData['concernCategories'].contains(topCategory)) {
            suggestions.add('Como reduzir gastos com ${topCategory}?');
          }
        }
        
        // Adicionar informação sobre categorias preocupantes
        final concerns = budgetData['concernCategories'] as List<String>;
        if (concerns.isNotEmpty && concerns.length <= 3) {
          response += ' As categorias ${concerns.join(", ")} estão consumindo uma proporção maior do que o recomendado da sua renda.';
        } else if (concerns.length > 3) {
          response += ' Você tem ${concerns.length} categorias de gastos acima do recomendado.';
          suggestions.add('Quais categorias estão acima do recomendado?');
        }
      }
    }
    // Mensagens sobre receitas
    else if (lowerMsg.contains('receita') || 
             lowerMsg.contains('ganho') ||
             lowerMsg.contains('entrada') ||
             lowerMsg.contains('renda') ||
             lowerMsg.contains('salário')) {
      
      final totalIncome = transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount);
      final incomesByCategory = <String, double>{};
      
      // Agrupar receitas por categoria
      for (var income in transactionModel.incomes) {
        incomesByCategory[income.category] = (incomesByCategory[income.category] ?? 0) + income.amount;
      }
      
      response = 'Suas receitas totais são de R\$ ${totalIncome.toStringAsFixed(2)}. ';
      
      // Adicionar informações sobre fontes de renda
      if (incomesByCategory.isNotEmpty) {
        if (incomesByCategory.length == 1) {
          final category = incomesByCategory.keys.first;
          response += 'Toda sua renda vem de "${category}". ';
          suggestions.add('Como diversificar minhas fontes de renda?');
        } else {
          response += 'Suas fontes de renda são: ';
          incomesByCategory.forEach((category, amount) {
            final percentage = (amount / totalIncome) * 100;
            response += '${category} (${percentage.toStringAsFixed(1)}%), ';
          });
          response = response.substring(0, response.length - 2) + '. ';
          
          if (incomesByCategory.length == 2) {
            suggestions.add('Como diversificar mais minhas fontes de renda?');
          }
        }
      }
      
      // Adicionar recomendações com base na renda
      final expenseRatio = healthData['expenseToIncomeRatio'] as double;
      if (expenseRatio > 0.9) {
        response += 'Suas despesas estão consumindo ${(expenseRatio * 100).toStringAsFixed(1)}% da sua renda, o que é muito alto.';
        suggestions.add('Como distribuir melhor minha renda?');
      } else {
        final savingsRate = healthData['savingsRate'] as double;
        response += 'Você está conseguindo poupar ${(savingsRate * 100).toStringAsFixed(1)}% da sua renda.';
        
        if (savingsRate < 0.2) {
          suggestions.add('Como distribuir minha renda de forma ideal?');
        } else {
          suggestions.add('Onde investir o dinheiro que estou poupando?');
        }
      }
    }
    // Mensagens sobre metas
    else if (lowerMsg.contains('meta') || 
             lowerMsg.contains('objetivo') ||
             lowerMsg.contains('sonho') ||
             lowerMsg.contains('plano')) {
      
      final goals = goalModel.goals;
      
      // Verificar se a pergunta é sobre uma meta específica
      FinancialGoal? specificGoal;
      for (var goal in goals) {
        if (lowerMsg.contains(goal.name.toLowerCase())) {
          specificGoal = goal;
          break;
        }
      }
      
      if (specificGoal != null) {
        // Resposta para uma meta específica
        final progress = (specificGoal.currentAmount / specificGoal.targetAmount) * 100;
        final remaining = specificGoal.targetAmount - specificGoal.currentAmount;
        
        response = 'Sua meta "${specificGoal.name}" tem um objetivo de R\$ ${specificGoal.targetAmount.toStringAsFixed(2)}. ';
        response += 'Você já acumulou R\$ ${specificGoal.currentAmount.toStringAsFixed(2)}, ';
        response += 'o que representa ${progress.toStringAsFixed(1)}% do objetivo. ';
        response += 'Faltam R\$ ${remaining.toStringAsFixed(2)} para completar esta meta.';
        
        // Analisar quanto tempo levaria para atingir com contribuições constantes
        final monthlySavingTarget = specificGoal.getMonthlySavingTarget();
        if (monthlySavingTarget > 0) {
          final monthsRemaining = remaining / monthlySavingTarget;
          if (monthsRemaining > 0) {
            final years = (monthsRemaining / 12).floor();
            final months = (monthsRemaining % 12).ceil();
            
            if (years > 0 && months > 0) {
              response += ' No ritmo atual de contribuição mensal, você atingirá esta meta em aproximadamente $years anos e $months meses.';
            } else if (years > 0) {
              response += ' No ritmo atual, você atingirá esta meta em aproximadamente $years anos.';
            } else {
              response += ' No ritmo atual, você atingirá esta meta em aproximadamente $months meses.';
            }
          }
        } else {
          response += ' Você não definiu contribuições mensais para esta meta.';
          suggestions.add('Como acelerar o progresso desta meta?');
        }
        
        if (progress < 50) {
          suggestions.add('Como atingir esta meta mais rapidamente?');
        } else {
          suggestions.add('Qual seria o impacto de aumentar minha contribuição mensal?');
        }
      } else if (goals.isEmpty) {
        response = 'Você ainda não definiu nenhuma meta financeira. Criar metas é essencial para uma vida financeira saudável e planejada.';
        
        // Sugestões de tipos de metas possíveis
        suggestions.add('Que tipos de metas financeiras devo criar?');
        suggestions.add('Como definir uma meta para reserva de emergência?');
        suggestions.add('Como planejar para aposentadoria?');
      } else {
        response = 'Você tem ${goals.length} meta(s) financeira(s): ';
        
        double totalProgress = 0;
        for (int i = 0; i < goals.length; i++) {
          final goal = goals[i];
          final progress = (goal.currentAmount / goal.targetAmount) * 100;
          totalProgress += progress;
          
          response += '${i+1}) "${goal.name}" (${progress.toStringAsFixed(1)}% concluída)';
          if (i < goals.length - 1) response += ', ';
        }
        response += '. ';
        
        // Média de progresso de todas as metas
        final avgProgress = totalProgress / goals.length;
        response += 'Em média, suas metas estão com ${avgProgress.toStringAsFixed(1)}% de progresso.';
        
        // Adicionar meta com maior e menor progresso
        if (goals.length > 1) {
          final mostProgressGoal = goals.reduce((a, b) => 
              (a.currentAmount / a.targetAmount) > (b.currentAmount / b.targetAmount) ? a : b);
          final leastProgressGoal = goals.reduce((a, b) => 
              (a.currentAmount / a.targetAmount) < (b.currentAmount / b.targetAmount) ? a : b);
          
          suggestions.add('Detalhes da meta "${mostProgressGoal.name}"');
          suggestions.add('Como acelerar o progresso da meta "${leastProgressGoal.name}"?');
        }
      }
    }
    // Mensagens sobre investimentos ou economia
    else if (lowerMsg.contains('investi') || 
             lowerMsg.contains('economi') ||
             lowerMsg.contains('poupa') ||
             lowerMsg.contains('guarda') ||
             lowerMsg.contains('reserva')) {
      
      // Determinar se o usuário está perguntando sobre um tipo específico de investimento
      bool isAboutEmergencyFund = lowerMsg.contains('emergência') || lowerMsg.contains('reserva');
      bool isAboutRetirement = lowerMsg.contains('aposentadoria') || lowerMsg.contains('futuro');
      bool isAboutRiskTolerance = lowerMsg.contains('risco');
      
      final balance = transactionModel.balance;
      final savingsRate = healthData['savingsRate'] as double;
      
      if (isAboutEmergencyFund) {
        response = 'Uma reserva de emergência é fundamental para sua segurança financeira. ';
        response += 'O ideal é ter entre 3 a 6 meses de despesas guardados em investimentos de alta liquidez. ';
        
        final monthlyExpenses = transactionModel.expenses.fold(0.0, (sum, item) => sum + item.amount) / 3; // Média mensal aproximada
        final targetEmergencyFund = monthlyExpenses * 6;
        
        if (monthlyExpenses > 0) {
          response += 'Com base nas suas despesas atuais, sua reserva ideal seria de aproximadamente R\$ ${targetEmergencyFund.toStringAsFixed(2)}. ';
        }
        
        if (balance <= 0) {
          response += 'No momento você não tem saldo disponível para iniciar sua reserva de emergência.';
          suggestions.add('Como começar minha reserva do zero?');
        } else if (balance < targetEmergencyFund * 0.3) {
          response += 'Sua reserva atual cobre menos de 30% do valor ideal.';
          suggestions.add('Onde guardar minha reserva de emergência?');
        } else if (balance < targetEmergencyFund) {
          response += 'Você já tem um bom começo, mas ainda não atingiu o valor ideal da reserva.';
        } else {
          response += 'Parabéns! Você já tem um valor superior ao recomendado para sua reserva de emergência.';
          suggestions.add('Como investir o excedente da minha reserva?');
        }
      } else if (isAboutRetirement) {
        response = 'Planejar a aposentadoria é essencial, mesmo que pareça distante. ';
        
        // Verificar se o usuário tem alguma meta relacionada à aposentadoria
        final retirementGoals = goalModel.goals.where((g) => 
            g.name.toLowerCase().contains('aposentadoria') || 
            g.name.toLowerCase().contains('futuro') ||
            g.name.toLowerCase().contains('longo prazo')).toList();
        
        if (retirementGoals.isNotEmpty) {
          response += 'Você já tem ${retirementGoals.length} meta(s) relacionada(s) à aposentadoria. ';
          
          if (retirementGoals.length == 1) {
            final goal = retirementGoals.first;
            final progress = (goal.currentAmount / goal.targetAmount) * 100;
            response += 'Sua meta "${goal.name}" está com ${progress.toStringAsFixed(1)}% de progresso.';
          }
        } else {
          response += 'Ainda não identifiquei metas específicas para aposentadoria em seu planejamento.';
          suggestions.add('Como criar um plano de aposentadoria?');
        }
        
        // Adicionar sugestões para todos os casos
        suggestions.add('Quais investimentos são melhores para aposentadoria?');
      } else if (isAboutRiskTolerance) {
        response = 'O perfil de risco ideal depende de vários fatores como sua idade, objetivos e estabilidade financeira atual. ';
        
        // Avaliar perfil de risco básico
        final score = healthData['score'] as int;
        final hasEmergencyFund = balance > 0;
        
        if (score < 50 || !hasEmergencyFund) {
          response += 'Com base na sua situação atual, recomendo um perfil conservador, focando primeiro em segurança.';
          suggestions.add('Quais são os investimentos de baixo risco?');
        } else if (score < 70) {
          response += 'Seu perfil parece moderado, podendo balancear segurança e rendimento.';
          suggestions.add('Como diversificar investimentos com risco moderado?');
        } else {
          response += 'Sua situação financeira parece sólida, o que permite considerar um perfil mais arrojado se for de seu interesse.';
          suggestions.add('Quais investimentos oferecem maior rendimento?');
        }
      } else {
        // Resposta geral sobre investimentos
        response = 'Com base no seu perfil financeiro atual, ';
        
        if (balance <= 0) {
          response += 'recomendo primeiro focar em equilibrar seu orçamento e criar uma reserva de emergência antes de investir.';
          suggestions.add('Como criar uma reserva de emergência?');
        } else if (balance > 0 && savingsRate < 0.1) {
          response += 'você tem um saldo positivo, mas sua taxa de poupança de ${(savingsRate * 100).toStringAsFixed(1)}% ainda é baixa. Ideal seria aumentar para pelo menos 10% antes de ampliar investimentos.';
          suggestions.add('Como aumentar minha taxa de poupança?');
        } else if (balance > 0 && balance < 5000) {
          response += 'você poderia começar com investimentos de baixo risco como Tesouro Direto ou CDBs de bancos grandes.';
          suggestions.add('Quais investimentos de renda fixa são recomendados para iniciantes?');
        } else {
          response += 'você já tem um bom valor para diversificar seus investimentos entre renda fixa e variável.';
          suggestions.add('Como dividir meus investimentos entre renda fixa e variável?');
        }
      }
    }
    // Mensagens sobre dicas e recomendações gerais
    else if (lowerMsg.contains('dica') ||
             lowerMsg.contains('conselho') ||
             lowerMsg.contains('sugestão') ||
             lowerMsg.contains('recomendação') ||
             lowerMsg.contains('como melhorar')) {
      
      final healthScore = healthData['score'] as int;
      final expenseToIncomeRatio = healthData['expenseToIncomeRatio'] as double;
      final savingsRate = healthData['savingsRate'] as double;
      
      response = 'Com base na análise das suas finanças, eis algumas recomendações personalizadas:\n\n';
      
      // Recomendações prioritárias
      List<String> tips = [];
      
      if (expenseToIncomeRatio >= 1) {
        tips.add('Prioridade: Reduza suas despesas, pois estão superando sua renda.');
      } else if (savingsRate <= 0) {
        tips.add('Comece a poupar: Tente guardar pelo menos 5-10% da sua renda todo mês.');
      }
      
      if (healthScore < 40) {
        tips.add('Crie um orçamento detalhado e monitore todos os seus gastos durante um mês.');
      }
      
      if (budgetData['concernCategories'].isNotEmpty) {
        final concerns = budgetData['concernCategories'] as List<String>;
        if (concerns.length <= 3) {
          tips.add('Revise seus gastos com ${concerns.join(", ")}, que estão acima do recomendado.');
        } else {
          tips.add('Reduza gastos nas ${concerns.length} categorias que estão consumindo muito do seu orçamento.');
        }
      }
      
      if (!healthData['hasGoals']) {
        tips.add('Defina metas financeiras claras para orientar seu planejamento futuro.');
      }
      
      if (transactionModel.balance <= 0) {
        tips.add('Estabeleça uma reserva de emergência equivalente a 3-6 meses de despesas.');
      }
      
      if (tips.isEmpty) {
        if (savingsRate < 0.2) {
          tips.add('Aumente sua taxa de poupança para pelo menos 20% da renda.');
        }
        tips.add('Diversifique suas fontes de renda para aumentar sua segurança financeira.');
        tips.add('Considere investimentos de longo prazo para fazer seu dinheiro trabalhar por você.');
      }
      
      // Adicionar as dicas à resposta
      for (int i = 0; i < tips.length; i++) {
        response += '${i+1}. ${tips[i]}\n';
      }
      
      // Adicionar sugestões baseadas nas dicas
      if (tips.isNotEmpty) {
        final firstTip = tips.first;
        if (firstTip.contains('Reduza suas despesas')) {
          suggestions.add('Onde posso cortar gastos?');
        } else if (firstTip.contains('Comece a poupar')) {
          suggestions.add('Métodos para começar a poupar?');
        } else if (firstTip.contains('Crie um orçamento')) {
          suggestions.add('Como criar um orçamento efetivo?');
        }
      }
    }
    // Respostas para comandos específicos
    else if (lowerMsg.contains('ajuda') || lowerMsg.contains('o que você pode')) {
      response = 'Posso ajudar você nas seguintes áreas:\n\n';
      response += '• Análise da sua saúde financeira geral\n';
      response += '• Informações sobre seu saldo e fluxo de caixa\n';
      response += '• Detalhamento de gastos e receitas\n';
      response += '• Acompanhamento de metas financeiras\n';
      response += '• Recomendações de investimentos e economia\n';
      response += '• Dicas personalizadas para melhorar suas finanças\n\n';
      response += 'Basta me perguntar sobre qualquer um desses temas!';
      
      suggestions.add('Como está minha saúde financeira?');
      suggestions.add('Quais são meus maiores gastos?');
      suggestions.add('Me dê dicas para melhorar minhas finanças');
    }
    // Resposta genérica
    else {
      response = 'Entendi sua mensagem, mas ainda estou aprendendo sobre este assunto específico. Posso ajudar com análises de saldo, despesas, receitas, metas financeiras e dicas de investimentos.';
      
      suggestions.add('Como está minha saúde financeira?');
      suggestions.add('Quais são meus maiores gastos?');
      suggestions.add('Como estão minhas metas financeiras?');
      suggestions.add('Me dê dicas financeiras');
    }
    
    setState(() {
      _messages.add({
        'isUser': false,
        'message': response,
        'suggestions': suggestions,
        'timestamp': DateTime.now(),
      });
      _isLoading = false;
    });
    
    // Scroll para o final após resposta
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // Verificar se a mensagem é uma saudação
  bool _isGreeting(String message) {
    final greetings = ['olá', 'oi', 'e aí', 'bom dia', 'boa tarde', 'boa noite', 'hey', 'hi', 'hello'];
    return greetings.any((greeting) => message.contains(greeting));
  }

  // Função para calcular a saúde financeira geral
  Map<String, dynamic> _calculateFinancialHealth() {
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
    
    final totalIncome = transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpenses = transactionModel.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final balance = transactionModel.balance;
    final savingsRate = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome : 0.0;
    
    // Calcular pontuação (0-100)
    int score = 50; // Pontuação inicial
    
    // Ajustar pontuação com base em diferentes métricas
    if (balance > 0) score += 10;
    if (balance < 0) score -= 15;
    
    if (savingsRate >= 0.2) score += 15;
    else if (savingsRate >= 0.1) score += 10;
    else if (savingsRate > 0) score += 5;
    else score -= 10;
    
    if (goalModel.goals.isNotEmpty) score += 5;
    
    // Verificar se tem alguma meta com bom progresso
    bool hasGoodProgressGoal = false;
    for (var goal in goalModel.goals) {
      if (goal.currentAmount / goal.targetAmount >= 0.5) {
        hasGoodProgressGoal = true;
        break;
      }
    }
    if (hasGoodProgressGoal) score += 5;
    
    // Limitar pontuação entre 0 e 100
    score = score.clamp(0, 100);
    
    // Determinar status com base na pontuação
    String status;
    if (score >= 80) {
      status = "Excelente";
    } else if (score >= 60) {
      status = "Boa";
    } else if (score >= 40) {
      status = "Regular";
    } else if (score >= 20) {
      status = "Preocupante";
    } else {
      status = "Crítica";
    }
    
    return {
      'score': score,
      'status': status,
      'balanceStatus': balance > 0 ? "positivo" : (balance < 0 ? "negativo" : "zerado"),
      'savingsRate': savingsRate,
      'hasGoals': goalModel.goals.isNotEmpty,
      'expenseToIncomeRatio': totalIncome > 0 ? totalExpenses / totalIncome : 0,
    };
  }

  // Função para analisar o orçamento do usuário
  Map<String, dynamic> _analyzeBudget() {
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    
    final totalIncome = transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount);
    final categories = <String, double>{};
    
    // Calcular total por categoria
    for (var expense in transactionModel.expenses) {
      categories[expense.category] = (categories[expense.category] ?? 0) + expense.amount;
    }
    
    // Calcular percentuais do orçamento
    final percentages = <String, double>{};
    categories.forEach((category, amount) {
      percentages[category] = totalIncome > 0 ? amount / totalIncome : 0;
    });
    
    // Identificar categorias com gastos acima do recomendado
    final concernCategories = <String>[];
    percentages.forEach((category, percentage) {
      final recommendedPercentage = _tipicalBudgetPercentages[category] ?? 0.05;
      if (percentage > recommendedPercentage * 1.2) { // 20% acima do recomendado
        concernCategories.add(category);
      }
    });
    
    // Identificar categoria com maior gasto
    String? topExpenseCategory;
    double maxExpense = 0;
    categories.forEach((category, amount) {
      if (amount > maxExpense) {
        maxExpense = amount;
        topExpenseCategory = category;
      }
    });
    
    return {
      'totalByCategory': categories,
      'percentageByCategory': percentages,
      'concernCategories': concernCategories,
      'topExpenseCategory': topExpenseCategory,
      'topExpenseAmount': maxExpense,
    };
  }

  void _startTypingAnimation() {
    // Animar indicadores de digitação
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          final first = _typingDotOpacities.removeAt(0);
          _typingDotOpacities.add(first);
        });
        _startTypingAnimation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.psychology_alt,
              color: isDarkMode ? Colors.blueAccent[100] : Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text(
              'Assistente Financeiro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['isUser'] as bool;
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? (isDarkMode ? Colors.blue[700] : Colors.blue[100]) 
                          : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'] as String,
                          style: TextStyle(
                            color: isUser 
                                ? (isDarkMode ? Colors.white : Colors.black87) 
                                : (isDarkMode ? Colors.white : Colors.black87),
                            fontSize: 15,
                          ),
                        ),
                        if (!isUser && message.containsKey('suggestions') && (message['suggestions'] as List).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (message['suggestions'] as List).map<Widget>((suggestion) {
                              return InkWell(
                                onTap: () {
                                  _messageController.text = suggestion;
                                  _sendMessage();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Indicador de digitação
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 3; i++) 
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedOpacity(
                            opacity: _typingDotOpacities[i],
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white : Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Campo de entrada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua pergunta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final void Function(Transaction)? onTap;

  const TransactionItem({Key? key, required this.transaction, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final iconData = isExpense ? Icons.arrow_upward : Icons.arrow_downward;
    final iconColor = isExpense ? Colors.red : Colors.green;
    final formattedDate = DateFormat.yMMMd('pt_BR').format(transaction.date);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mutedTextColor = isDarkMode ? Colors.white70 : Colors.grey[600];

    return InkWell(
      onTap: onTap != null ? () => onTap!(transaction) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${transaction.category} • $formattedDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedTextColor,
                    ),
                  ),
                  if (transaction.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 