# EditDialogFireDAC

## O que faz

É um conjunto de units de design-time para pesquisa e edição de campos ligados
a banco, com suporte a FireDAC. Inclui o diálogo de pesquisa, editores de
propriedades, internacionalização, templates e registro dos componentes na
paleta.

## Melhorias sugeridas sem quebra

- Separar futuramente units runtime e design-time em pacotes distintos.
- Remover dependências Zeos do pacote FireDAC quando elas não forem usadas no
  projeto consumidor.
- Centralizar textos e formatos em recursos localizáveis.
- Adicionar testes para consultas vazias, campos nulos e filtros com caracteres
  especiais antes de alterar o comportamento existente.
