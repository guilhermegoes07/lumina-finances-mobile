# Funcionalidade de Exportar/Importar Extrato

## 📋 Descrição

Foi implementada uma funcionalidade completa para exportar e importar extratos de transações (entradas e saídas) do aplicativo Lumina Finances em formato JSON.

## ✨ Funcionalidades

### 1. Exportar Extrato
- **Formato**: JSON
- **Local de salvamento**: 
  - Android: Pasta **Downloads** (`/storage/emulated/0/Download`)
  - iOS: Pasta de Documentos do aplicativo
- **Nome do arquivo**: `extrato_lumina_YYYYMMDD_HHMMSS.json`
- **Conteúdo exportado**:
  - Todas as transações (entradas e saídas)
  - Informações: título, valor, data, categoria, tipo, recorrência, descrição
  - Metadados: versão do app, data de exportação, total de transações

### 2. Importar Extrato
- **Formato aceito**: JSON (arquivos do Lumina Finances)
- **Validação**: Verifica se o arquivo é válido antes de importar
- **Preview**: Mostra estatísticas do arquivo antes de confirmar:
  - Total de transações
  - Quantidade e valor total de entradas
  - Quantidade e valor total de saídas
- **Confirmação**: Dialog de confirmação antes de importar

## 📂 Arquivos Criados/Modificados

### Novos Arquivos
1. **`lib/services/export_import_service.dart`**
   - Serviço principal para gerenciar exportação e importação
   - Métodos:
     - `exportTransactions()`: Exporta transações para JSON
     - `importTransactions()`: Importa transações de JSON
     - `validateImportFile()`: Valida se um arquivo é compatível
     - `getImportStatistics()`: Obtém estatísticas de um arquivo

### Arquivos Modificados
1. **`pubspec.yaml`**
   - Adicionadas dependências:
     - `file_picker: ^6.1.1` - Para selecionar arquivos
     - `permission_handler: ^11.0.1` - Para gerenciar permissões

2. **`lib/screens/reports_screen.dart`**
   - Adicionada seção "Gerenciar Extrato" com botões:
     - Botão "Exportar" (azul) com ícone de download
     - Botão "Importar" (verde) com ícone de upload
   - Implementados métodos:
     - `_exportTransactions()`: Exporta com solicitação de permissão
     - `_importTransactions()`: Importa com validação e confirmação

3. **`android/app/src/main/AndroidManifest.xml`**
   - Adicionadas permissões necessárias:
     - `READ_EXTERNAL_STORAGE`
     - `WRITE_EXTERNAL_STORAGE` (até Android 12)
     - `READ_MEDIA_*` (para Android 13+)

## 🎯 Como Usar

### Exportar Extrato
1. Acesse a tela de **Relatórios**
2. Role até a seção "Gerenciar Extrato"
3. Clique no botão **"Exportar"**
4. Conceda permissão de armazenamento (primeira vez)
5. O arquivo será salvo na pasta Downloads
6. Uma mensagem confirmará o local e nome do arquivo

### Importar Extrato
1. Acesse a tela de **Relatórios**
2. Role até a seção "Gerenciar Extrato"
3. Clique no botão **"Importar"**
4. Selecione um arquivo JSON do Lumina Finances
5. Revise as estatísticas apresentadas
6. Confirme a importação
7. As transações serão adicionadas ao seu extrato atual

## 📱 Formato do Arquivo JSON

```json
{
  "app": "Lumina Finances",
  "version": "1.0.0",
  "export_date": "2025-10-08T15:30:00.000Z",
  "total_transactions": 10,
  "transactions": [
    {
      "id": 1,
      "title": "Salário",
      "amount": 5000.00,
      "date": "2025-10-01",
      "category": "Salário",
      "type": "income",
      "is_recurring": true,
      "recurrence_frequency": "monthly",
      "description": "Salário mensal"
    },
    {
      "id": 2,
      "title": "Aluguel",
      "amount": 1500.00,
      "date": "2025-10-05",
      "category": "Moradia",
      "type": "expense",
      "is_recurring": true,
      "recurrence_frequency": "monthly",
      "description": "Pagamento de aluguel"
    }
  ]
}
```

## ⚠️ Observações Importantes

1. **Permissões**: O aplicativo solicita permissão de armazenamento apenas quando necessário
2. **Duplicação**: Ao importar, as transações são ADICIONADAS (não substituem as existentes)
3. **Validação**: Apenas arquivos válidos do Lumina Finances são aceitos
4. **IDs**: Os IDs das transações importadas são gerados automaticamente
5. **Backup**: Use a exportação para fazer backup regular dos seus dados
6. **Migração**: Ideal para transferir dados entre contas ou dispositivos

## 🔒 Segurança

- Os arquivos são salvos localmente no dispositivo
- Não há sincronização em nuvem automática
- O usuário tem controle total sobre os arquivos exportados
- Recomenda-se armazenar os arquivos em local seguro

## 🚀 Casos de Uso

1. **Backup Regular**: Exportar periodicamente para segurança
2. **Migração de Conta**: Transferir dados entre contas diferentes
3. **Migração de Dispositivo**: Mover dados para um novo celular
4. **Compartilhamento**: Compartilhar transações com contador/consultor
5. **Análise Externa**: Processar dados em outras ferramentas

## 📝 Exemplo de Fluxo Completo

```
1. Usuário exporta extrato no Dispositivo A
   └─> Arquivo salvo em Downloads: extrato_lumina_20251008_153000.json

2. Usuário compartilha arquivo (via email, WhatsApp, etc.)

3. Usuário abre arquivo no Dispositivo B

4. Usuário importa arquivo no Lumina Finances
   └─> Preview: "10 transações, 5 entradas (R$ 10.000), 5 saídas (R$ 3.000)"
   └─> Confirma importação
   └─> Transações adicionadas com sucesso!
```

## 🔧 Manutenção Futura

Possíveis melhorias:
- [ ] Filtrar período de exportação
- [ ] Exportar categorias específicas
- [ ] Opção de substituir vs adicionar na importação
- [ ] Exportar em outros formatos (CSV, Excel)
- [ ] Sincronização em nuvem automática
- [ ] Criptografia dos arquivos exportados
- [ ] Histórico de importações/exportações
