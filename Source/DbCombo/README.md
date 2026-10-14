# DBValueComboBox

## O que faz

`TDBValueComboBox` é um `TCustomComboBox` ligado a um `TDataSource`. Ele exibe
os itens da propriedade `Items` e grava no campo o valor correspondente na
mesma posição da lista `Values`.

## Melhorias sugeridas sem quebra

- Validar se `Items.Count` e `Values.Count` estão alinhados antes de gravar.
- Atualizar o `ItemIndex` quando `Values` for alterado em tempo de design.
- Expor `TabOrder`, `TabStop`, `Visible` e `Enabled` com os defaults usuais.
- Evitar chamar `UpdateRecord` em toda mudança se a aplicação preferir salvar
  somente no post do dataset; isso deve ser uma opção nova, não uma mudança do
  comportamento atual.
