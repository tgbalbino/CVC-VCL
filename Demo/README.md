# DBLookupEdit Demo

Demo manual e isolada para testar `TDBLookupEdit` sem abrir o Controle de Vendas.

## Testes disponíveis

- digitação por descrição (`Transferencia`);
- digitação por código (`4`);
- Enter, Tab e saída do campo;
- pesquisa pela lupa;
- `LoadByID(4)`;
- limpeza do valor;
- atualização do `DataLink` e do `TFDMemTable`;
- mudança da cor global de campo desabilitado.
- alternância de `SearchOnExit` para reproduzir campos críticos sem pesquisa
  automática ao perder o foco;
- captura de falhas por `OnLookupError` sem encerrar a aplicação.

## Matriz de regressão do componente

Antes de publicar uma alteração, executar estes cenários na ordem abaixo:

| Cenário | Resultado esperado |
|---|---|
| conexão inválida ou fechada | erro em `OnLookupError`, sem encerrar a demo |
| descrição vazia + Enter/Tab | limpa o ID e não abre pesquisa |
| descrição parcial + Enter | resolve uma ocorrência ou abre a grade |
| código válido e inválido | resolve o válido; mantém o texto e sinaliza o inválido |
| botão de pesquisa com callback | fecha cursores internos antes do modal e não bloqueia a UI |
| botão de pesquisa sem callback | abre a pesquisa padrão do componente |
| `SearchOnExit` ligado/desligado | saída não reentra nem dispara consulta indevida |
| `LoadByID`, `Clear` e mudança de registro | texto, ID e `DataLink` permanecem sincronizados |
| destruir o formulário durante/apos pesquisa | nenhuma exceção ou consulta fica aberta |

O cenário de callback também é exercitado pelo ERP na pesquisa de filial da
transferência. No Notebook 19, o clique repetido na lupa foi validado após a
correção do fechamento dos cursores e não reproduziu mais o travamento.

## Execução

Abra `DBLookupEditDemo.dproj` no Delphi e compile Win32. Informe servidor,
banco Firebird, usuário e senha. A demo executa somente consultas `SELECT`
na tabela `TIPO_SAIDA`; o registro editado fica apenas no `TFDMemTable` em memória.

Para definir a senha inicial sem gravá-la no fonte, use a variável:

```text
CVC_LOOKUP_DB_PASSWORD
```
