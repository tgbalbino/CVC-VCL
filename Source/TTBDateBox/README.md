# DateBox

## O que faz

`TDateBox` agrupa duas caixas `TJvDateEdit` para informar um período e uma
opção para ignorar a data. Também gera trechos SQL para Firebird, SQL Server e
Oracle conforme `DateField`, `GDB` e `QuotedDate`.

## Melhorias sugeridas sem quebra

- Retornar string vazia explicitamente quando `DateField` ou o período não
  estiverem configurados.
- Substituir a geração de SQL por parâmetros em uma API nova, mantendo os
  métodos atuais por compatibilidade.
- Corrigir o nome histórico `GetDateStarSql` com um novo alias
  `GetDateStartSql`, sem remover o método antigo.
- Publicar as caixas internas apenas se houver necessidade real de customização.
