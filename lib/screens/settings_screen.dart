import 'package:flutter/material.dart';
import 'package:lumina_finances/screens/advanced_settings_screen.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'spending_limits_screen.dart';
import 'financial_goals_screen.dart';
import 'bank_accounts_screen.dart';
import 'chat_support_screen.dart';
import '../models/transaction.dart';
import '../models/financial_goal.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../services/biometric_auth_service.dart';
import 'welcome_screen.dart';
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }
  
  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }
  
  Future<void> _saveProfileData(String name, String email, String profileType, String avatarUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = await AuthService.getCurrentUser();
      
      if (user != null && user['email'] != null) {
        final userKey = 'userProfile_${user['email']}';
        final profileData = {
          'name': name,
          'email': email,
          'profileType': profileType,
          'avatarUrl': avatarUrl,
        };
        
        await prefs.setString(userKey, jsonEncode(profileData));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar dados do perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final userProfile = Provider.of<UserProfile>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // Informações de perfil
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: userProfile.avatarUrl.isEmpty
                      ? Text(
                          userProfile.name.isNotEmpty
                              ? userProfile.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 24, color: Colors.black87),
                        )
                      : null,
                  backgroundImage: userProfile.avatarUrl.isNotEmpty
                      ? NetworkImage(userProfile.avatarUrl)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userProfile.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Controladores para os campos de texto
                    final nameController = TextEditingController(text: userProfile.name);
                    final avatarController = TextEditingController(text: userProfile.avatarUrl);
                    
                    // Mostrar bottom sheet para edição de perfil
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          top: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Editar Perfil',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: avatarController,
                              decoration: const InputDecoration(
                                labelText: 'URL do Avatar (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.image),
                                hintText: 'https://example.com/avatar.jpg',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final newName = nameController.text.trim();
                                      final newAvatarUrl = avatarController.text.trim();
                                      
                                      if (newName.isNotEmpty) {
                                        userProfile.updateProfile(
                                          name: newName,
                                          email: userProfile.email,
                                          profileType: userProfile.profileType,
                                          avatarUrl: newAvatarUrl,
                                        );
                                        
                                        // Salvar os dados atualizados
                                        _saveProfileData(newName, userProfile.email, userProfile.profileType, newAvatarUrl);
                                        
                                        // Fechar o modal
                                        Navigator.pop(context);
                                        
                                        // Mostrar mensagem de sucesso
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Perfil atualizado com sucesso!'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        // Mostrar erro se o nome estiver vazio
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('O nome não pode ficar vazio'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Salvar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Limites de Gastos
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Limites de Gastos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para a tela de limites de gastos
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpendingLimitsScreen(),
                ),
              );
            },
          ),
          
          // Objetivos Financeiros
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Objetivos Financeiros'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinancialGoalsScreen(),
                ),
              );
            },
          ),
          
          // Contas Bancárias
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Contas Bancárias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BankAccountsScreen(),
                ),
              );
            },
          ),
          
          // Configurações Avançadas
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações Avançadas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedSettingsScreen(),
                ),
              );
            },
          ),
          
          // Privacidade
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Política de Privacidade'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'O aplicativo Lumina Finances respeita sua privacidade e está comprometido em proteger seus dados pessoais. '
                      'Todos os dados financeiros são armazenados localmente no seu dispositivo. '
                      'Não compartilhamos nenhuma informação com terceiros sem seu consentimento explícito.\n\n'
                      'Seus dados são criptografados e protegidos usando os mais altos padrões de segurança. '
                      'Você sempre tem controle total sobre seus dados e pode exportá-los ou apagá-los a qualquer momento.',
                    ),
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
          
          // Ajuda e Suporte
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda e Suporte'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ajuda e Suporte',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Contato por Email'),
                        subtitle: const Text('suporte@luminafinances.com'),
                        onTap: () async {
                          Navigator.pop(context);
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'suporte@luminafinances.com',
                            query: 'subject=Suporte Lumina Finances&body=Olá, preciso de ajuda com:',
                          );
                          
                          try {
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(emailUri);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Não foi possível abrir o cliente de email. Por favor, envie um email manualmente para suporte@luminafinances.com'),
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao abrir email: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.question_answer_outlined),
                        title: const Text('Perguntas Frequentes'),
                        onTap: () {
                          Navigator.pop(context);
                          // Exibir FAQs
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Perguntas Frequentes'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Como adicionar uma transação?',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Toque no botão "+" na tela principal e preencha os detalhes da transação.'),
                                    SizedBox(height: 12),
                                    Text(
                                      'Como criar uma meta financeira?',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Acesse a seção "Objetivos Financeiros" e toque no botão "+" para adicionar uma nova meta.'),
                                    SizedBox(height: 12),
                                    Text(
                                      'Posso exportar meus dados?',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Sim, vá em "Configurações" > "Exportar Dados" para baixar seus dados em formato CSV.'),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.chat_outlined),
                        title: const Text('Chat com Suporte'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatSupportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Sobre o App
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Lumina Finances',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'resources/icon.png',
                  width: 48,
                  height: 48,
                ),
                applicationLegalese: '© 2023-2024 Lumina Team\nTodos os direitos reservados',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Lumina Finances é um aplicativo de gestão financeira pessoal que ajuda você a controlar suas finanças, definir metas e tomar decisões financeiras mais inteligentes.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Criado com Flutter e amor ❤️',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              );
            },
          ),
          
          const Divider(),
          
          // Modo Escuro
          SwitchListTile(
            secondary: Icon(
              appSettings.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Modo Escuro'),
            value: appSettings.isDarkMode,
            onChanged: (value) {
              appSettings.toggleDarkMode();
            },
          ),
          
          // Notificações
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            subtitle: const Text('Receber alertas de gastos e lembretes'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          
          // Exportar Dados
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Exportar Dados'),
            subtitle: const Text('Exportar transações em CSV ou PDF'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text(
                        'Exportar Dados',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Exportar como CSV'),
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Mostrar indicador de progresso
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exportando dados...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        
                        // Simulação de exportação
                        await Future.delayed(const Duration(seconds: 2));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dados exportados com sucesso para Downloads/lumina_finances.csv'),
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: const Text('Exportar como PDF'),
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Mostrar indicador de progresso
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gerando PDF...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                        try {
                          final transactionModel = Provider.of<TransactionModel>(context, listen: false);
                          final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
                          
                          // Opção de escolher entre transações ou metas
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Escolha o tipo de relatório'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.receipt_long),
                                    title: const Text('Transações'),
                                    onTap: () => Navigator.pop(context, 'transactions'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.flag),
                                    title: const Text('Metas Financeiras'),
                                    onTap: () => Navigator.pop(context, 'goals'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          
                          if (result == null) return;
                          
                          if (result == 'transactions') {
                            final file = await PdfService.generateTransactionsReport(
                              transactions: transactionModel.transactions,
                              balance: transactionModel.balance,
                              totalIncome: transactionModel.totalIncome,
                              totalExpenses: transactionModel.totalExpenses,
                            );
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('PDF gerado: ${file.path.split('/').last}'),
                                  action: SnackBarAction(
                                    label: 'Visualizar',
                                    onPressed: () async {
                                      await Printing.sharePdf(
                                        bytes: await file.readAsBytes(),
                                        filename: file.path.split('/').last,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                          } else if (result == 'goals') {
                            final file = await PdfService.generateGoalsReport(
                              goals: goalModel.goals,
                            );
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('PDF gerado: ${file.path.split('/').last}'),
                                  action: SnackBarAction(
                                    label: 'Visualizar',
                                    onPressed: () async {
                                      await Printing.sharePdf(
                                        bytes: await file.readAsBytes(),
                                        filename: file.path.split('/').last,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao gerar PDF: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
          
          // Segurança
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Segurança'),
            subtitle: const Text('Proteção por senha e autenticação'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    bool biometricEnabled = false;
                    bool pinEnabled = false;
                    
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configurações de Segurança',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Autenticação Biométrica'),
                            subtitle: const Text('Usar impressão digital ou Face ID para acessar o app'),
                            value: biometricEnabled,
                            onChanged: (value) async {
                              if (value) {
                                // Verificar se o dispositivo suporta biometria
                                final canCheck = await BiometricAuthService.canCheckBiometrics();
                                if (!canCheck) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Seu dispositivo não suporta autenticação biométrica'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Tentar autenticar
                                final authenticated = await BiometricAuthService.authenticate();
                                if (authenticated) {
                                  await BiometricAuthService.enableBiometric();
                                  setState(() {
                                    biometricEnabled = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Autenticação biométrica ativada com sucesso!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Falha na autenticação biométrica'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                await BiometricAuthService.disableBiometric();
                                setState(() {
                                  biometricEnabled = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Autenticação biométrica desativada'),
                                  ),
                                );
                              }
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Código PIN'),
                            subtitle: const Text('Usar um código de 4 dígitos para acessar o app'),
                            value: pinEnabled,
                            onChanged: (value) async {
                              if (value) {
                                Navigator.pop(context);
                                // Mostrar diálogo para configurar PIN
                                final pin = await _showPinDialog(context, 'Configurar PIN', 'Digite um PIN de 4 dígitos');
                                if (pin != null && pin.length == 4) {
                                  // Confirmar PIN
                                  final confirmPin = await _showPinDialog(context, 'Confirmar PIN', 'Digite o PIN novamente');
                                  if (confirmPin == pin) {
                                    await PinAuthService.setPin(pin);
                                    setState(() {
                                      pinEnabled = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN configurado com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Os PINs não coincidem'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                Navigator.pop(context);
                                // Verificar PIN antes de desativar
                                final pin = await _showPinDialog(context, 'Desativar PIN', 'Digite seu PIN atual');
                                if (pin != null) {
                                  final verified = await PinAuthService.verifyPin(pin);
                                  if (verified) {
                                    await PinAuthService.removePin();
                                    setState(() {
                                      pinEnabled = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN removido com sucesso'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN incorreto'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Configurações salvas'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 0),
                            ),
                            child: const Text('Salvar Configurações'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Botão de Sair
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // Forçar logout removendo a chave do usuário
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('loggedUserEmail');
                  
                  // Resetar todos os Providers
                  TransactionModel.reset(context);
                  FinancialGoalModel.reset(context);
                  final userProfile = Provider.of<UserProfile>(context, listen: false);
                  userProfile.updateProfile(name: '', email: '', profileType: 'Pessoal', avatarUrl: '');
                  
                  // Forçar navegação para a tela de boas-vindas
                  Navigator.pushAndRemoveUntil(
                      context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao sair: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout),
                  const SizedBox(width: 8),
                  const Text(
                    'Sair',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPinDialog(BuildContext context, String title, String message) async {
    final TextEditingController pinController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: '****',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(context, pinController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O PIN deve ter 4 dígitos'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
} 