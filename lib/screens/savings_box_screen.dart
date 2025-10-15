import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/savings_box.dart';

class SavingsBoxScreen extends StatefulWidget {
  const SavingsBoxScreen({super.key});

  @override
  State<SavingsBoxScreen> createState() => _SavingsBoxScreenState();
}

class _SavingsBoxScreenState extends State<SavingsBoxScreen> {
  final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final model = Provider.of<SavingsBoxModel>(context, listen: false);
    await model.loadSavingsBoxes();
  }

  void _addOrEditSavingsBox([SavingsBox? savingsBox]) async {
    final nameController = TextEditingController(text: savingsBox?.name);
    final amountController = TextEditingController(
      text: savingsBox?.initialAmount.toString() ?? '',
    );
    final descriptionController = TextEditingController(text: savingsBox?.description);
    DateTime entryDate = savingsBox?.entryDate ?? DateTime.now();
    DateTime? exitDate = savingsBox?.exitDate;
    double cdiRate = savingsBox?.cdiRate ?? 100.0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              title: Text(savingsBox == null ? 'Nova Caixinha' : 'Editar Caixinha'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor Inicial',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data de Entrada'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(entryDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: entryDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setDialogState(() {
                            entryDate = date;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data de Saída (Opcional)'),
                      subtitle: Text(
                        exitDate != null
                            ? DateFormat('dd/MM/yyyy').format(exitDate!)
                            : 'Não definida',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (exitDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setDialogState(() {
                                  exitDate = null;
                                });
                              },
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: exitDate ?? DateTime.now(),
                          firstDate: entryDate,
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setDialogState(() {
                            exitDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Taxa CDI: ${cdiRate.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: cdiRate,
                      min: 50,
                      max: 120,
                      divisions: 14,
                      label: '${cdiRate.toStringAsFixed(0)}%',
                      onChanged: (value) {
                        setDialogState(() {
                          cdiRate = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha os campos obrigatórios')),
                      );
                      return;
                    }

                    final amount = double.tryParse(
                      amountController.text.replaceAll(',', '.'),
                    );
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Valor inválido')),
                      );
                      return;
                    }

                    final newSavingsBox = SavingsBox(
                      id: savingsBox?.id,
                      name: nameController.text,
                      initialAmount: amount,
                      entryDate: entryDate,
                      exitDate: exitDate,
                      cdiRate: cdiRate,
                      description: descriptionController.text,
                    );

                    final model = Provider.of<SavingsBoxModel>(context, listen: false);
                    if (savingsBox == null) {
                      await model.addSavingsBox(newSavingsBox);
                    } else {
                      await model.updateSavingsBox(newSavingsBox);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(savingsBox == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSavingsBox(SavingsBox savingsBox) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir "${savingsBox.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final model = Provider.of<SavingsBoxModel>(context, listen: false);
      await model.deleteSavingsBox(savingsBox.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<SavingsBoxModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixinhas de Investimento'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditSavingsBox(),
        child: const Icon(Icons.add),
      ),
      body: model.savingsBoxes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings,
                    size: 64,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma caixinha cadastrada',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no botão + para adicionar',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Resumo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo dos Investimentos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Total Investido',
                          model.totalInvested,
                          Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Valor Atual',
                          model.totalCurrentValue,
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Lucro Líquido',
                          model.totalProfit,
                          model.totalProfit >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de caixinhas
                ...model.savingsBoxes.map((box) => _buildSavingsBoxCard(box, isDarkMode)),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          _moneyFormat.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsBoxCard(SavingsBox box, bool isDarkMode) {
    final currentValue = box.getCurrentValue();
    final netProfit = box.getNetProfit();
    final grossProfit = box.getGrossProfit();
    final incomeTax = box.getIncomeTax();
    final iof = box.getIOF();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showDetailsDialog(box),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      box.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _addOrEditSavingsBox(box);
                      } else if (value == 'delete') {
                        _deleteSavingsBox(box);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Entrada: ${DateFormat('dd/MM/yyyy').format(box.entryDate)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (box.exitDate != null)
                Text(
                  'Saída: ${DateFormat('dd/MM/yyyy').format(box.exitDate!)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor Inicial',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _moneyFormat.format(box.initialAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Valor Atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _moneyFormat.format(currentValue),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: netProfit >= 0
                      ? (isDarkMode ? Colors.green[900] : Colors.green[50])
                      : (isDarkMode ? Colors.red[900] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lucro Líquido',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      _moneyFormat.format(netProfit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(SavingsBox box) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final grossProfit = box.getGrossProfit();
    final incomeTax = box.getIncomeTax();
    final iof = box.getIOF();
    final netProfit = box.getNetProfit();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(box.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (box.description.isNotEmpty) ...[
                Text(box.description),
                const Divider(height: 24),
              ],
              _buildDetailRow('Taxa CDI', '${box.cdiRate.toStringAsFixed(0)}%'),
              const SizedBox(height: 8),
              _buildDetailRow('Valor Inicial', _moneyFormat.format(box.initialAmount)),
              _buildDetailRow('Valor Atual', _moneyFormat.format(box.getCurrentValue())),
              const Divider(height: 24),
              _buildDetailRow('Rendimento Bruto', _moneyFormat.format(grossProfit)),
              _buildDetailRow('Imposto de Renda', '- ${_moneyFormat.format(incomeTax)}'),
              if (iof > 0) _buildDetailRow('IOF', '- ${_moneyFormat.format(iof)}'),
              const Divider(height: 24),
              _buildDetailRow(
                'Lucro Líquido',
                _moneyFormat.format(netProfit),
                isHighlight: true,
              ),
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
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
