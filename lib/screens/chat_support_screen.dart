import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mensagem de boas-vindas
    _addBotMessage(
      'Olá! Bem-vindo ao suporte do Lumina Finances. 👋\n\n'
      'Como posso ajudá-lo hoje?\n\n'
      'Perguntas comuns:\n'
      '• Como adicionar uma transação?\n'
      '• Como criar uma meta financeira?\n'
      '• Como funciona o portfólio de investimentos?\n'
      '• Como exportar meus dados?'
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _messageController.clear();

    // Simular resposta do bot
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
      });
      _addBotMessage(_generateBotResponse(text));
    });
  }

  String _generateBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('transação') || lowerMessage.contains('adicionar')) {
      return 'Para adicionar uma transação:\n\n'
          '1. Na tela principal, toque no botão "+" no canto inferior direito\n'
          '2. Preencha os detalhes da transação:\n'
          '   • Título\n'
          '   • Valor\n'
          '   • Categoria\n'
          '   • Data\n'
          '   • Tipo (Receita ou Despesa)\n'
          '3. Toque em "Salvar"\n\n'
          'A transação será adicionada ao seu histórico e refletida no seu saldo.';
    }

    if (lowerMessage.contains('meta') || lowerMessage.contains('objetivo')) {
      return 'Para criar uma meta financeira:\n\n'
          '1. Acesse a seção "Objetivos Financeiros"\n'
          '2. Toque no botão "+"\n'
          '3. Preencha:\n'
          '   • Nome da meta\n'
          '   • Valor alvo\n'
          '   • Prazo\n'
          '   • Descrição (opcional)\n'
          '4. Toque em "Criar Meta"\n\n'
          'Você pode acompanhar o progresso e fazer contribuições regularmente!';
    }

    if (lowerMessage.contains('investimento') || lowerMessage.contains('portfólio')) {
      return 'Sobre o Portfólio de Investimentos:\n\n'
          '1. Acesse "Sugestões de Investimentos"\n'
          '2. Escolha entre perfis: Conservador, Moderado ou Arrojado\n'
          '3. Selecione um investimento da lista\n'
          '4. Digite o valor a investir\n'
          '5. Confirme o investimento\n\n'
          'Para visualizar seu portfólio, toque no ícone da carteira no topo da tela de investimentos.\n\n'
          'O sistema calcula automaticamente o rendimento baseado no tempo investido!';
    }

    if (lowerMessage.contains('exportar') || lowerMessage.contains('dados')) {
      return 'Para exportar seus dados:\n\n'
          '1. Acesse "Configurações"\n'
          '2. Toque em "Exportar Dados"\n'
          '3. Escolha o formato:\n'
          '   • CSV - para análise em planilhas\n'
          '   • PDF - relatório formatado\n\n'
          'Os arquivos serão salvos e você poderá compartilhá-los ou salvá-los em outro local.';
    }

    if (lowerMessage.contains('biometria') || lowerMessage.contains('pin') || lowerMessage.contains('segurança')) {
      return 'Sobre Segurança:\n\n'
          '• Autenticação Biométrica: Use sua impressão digital ou Face ID para acessar o app\n'
          '• PIN de 4 dígitos: Configure um código de segurança\n\n'
          'Para ativar, vá em Configurações > Segurança e escolha sua opção preferida.\n\n'
          'Seus dados são criptografados e armazenados com segurança no dispositivo.';
    }

    if (lowerMessage.contains('saldo') || lowerMessage.contains('balanço')) {
      return 'O saldo é calculado automaticamente:\n\n'
          '• Receitas somam ao saldo\n'
          '• Despesas subtraem do saldo\n'
          '• O Dashboard mostra um resumo visual\n\n'
          'Você pode ver o histórico detalhado na tela de Transações.';
    }

    if (lowerMessage.contains('categoria')) {
      return 'Categorias disponíveis:\n\n'
          'Despesas: Alimentação, Transporte, Moradia, Saúde, Educação, Lazer, Vestuário, Outros\n\n'
          'Receitas: Salário, Freelance, Investimentos, Outros\n\n'
          'As categorias ajudam a organizar e analisar seus gastos.';
    }

    if (lowerMessage.contains('gráfico') || lowerMessage.contains('dashboard')) {
      return 'O Dashboard oferece:\n\n'
          '• Gráfico de pizza de despesas por categoria\n'
          '• Evolução mensal de receitas e despesas\n'
          '• Resumo do saldo atual\n'
          '• Progresso das metas financeiras\n\n'
          'É a visão geral completa da sua saúde financeira!';
    }

    if (lowerMessage.contains('ajuda') || lowerMessage.contains('help') || lowerMessage.contains('suporte')) {
      return 'Estou aqui para ajudar! 😊\n\n'
          'Você pode me perguntar sobre:\n'
          '• Como usar funcionalidades do app\n'
          '• Dúvidas sobre transações e categorias\n'
          '• Metas financeiras\n'
          '• Investimentos e portfólio\n'
          '• Exportação de dados\n'
          '• Segurança e privacidade\n\n'
          'Para suporte técnico mais específico, você também pode nos contatar por email: suporte@luminafinances.com';
    }

    // Resposta padrão
    return 'Obrigado pela sua mensagem!\n\n'
        'Sua pergunta foi registrada. Se precisar de ajuda imediata, tente reformular sua pergunta ou escolha uma das opções:\n\n'
        '• Como adicionar uma transação?\n'
        '• Como criar uma meta financeira?\n'
        '• Como funciona o portfólio?\n'
        '• Como exportar dados?\n'
        '• Ajuda com segurança\n\n'
        'Você também pode nos contatar por email: suporte@luminafinances.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat com Suporte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sobre o Chat'),
                  content: const Text(
                    'Este é um assistente virtual que pode ajudá-lo com dúvidas comuns sobre o app.\n\n'
                    'Para suporte técnico especializado, entre em contato por email: suporte@luminafinances.com'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Indicador de digitação
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.support_agent, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildDot(),
                        const SizedBox(width: 4),
                        _buildDot(),
                        const SizedBox(width: 4),
                        _buildDot(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Campo de entrada
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
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
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final timeFormat = DateFormat('HH:mm');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: Icon(Icons.support_agent, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
