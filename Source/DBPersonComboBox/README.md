# DBPersonComboBox

## O que faz

`TDBPersonComboBox` associa textos exibidos (`DisplayItems`) a valores
persistidos (`Values`) usando `TFieldDataLink`. O campo recebe o valor da
posição escolhida e o controle acompanha o registro atual.

## Melhorias sugeridas sem quebra

- Corrigir a grafia histórica `PesonDbCombobox` somente em pastas e documentação;
  manter a unit e a classe atuais para preservar DFM e código existente.
- Validar a quantidade de itens antes de acessar `FValues[ItemIndex]`.
- Atualizar a tela quando `Values` mudar, preservando `ItemIndex` por valor.
- Publicar as propriedades usuais de navegação e alinhamento com defaults VCL.
