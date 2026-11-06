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

## Execução

Abra `DBLookupEditDemo.dproj` no Delphi e compile Win32. Informe servidor,
banco Firebird, usuário e senha. A demo executa somente consultas `SELECT`
na tabela `TIPO_SAIDA`; o registro editado fica apenas no `TFDMemTable` em memória.

Para definir a senha inicial sem gravá-la no fonte, use a variável:

```text
CVC_LOOKUP_DB_PASSWORD
```
