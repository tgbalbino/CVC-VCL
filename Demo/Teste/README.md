# Bateria automatica do DBLookupEdit (Enter, grade e DataLink)

Base propria (nao usa o banco do ERP): `criar-base-demo.sql` cria
`C:\Bancos\DBLOOKUPDEMO\DEMO.FDB` com as tabelas `PESSOA` e `PRODUTO`.

1. Criar a base (uma vez): `isql -i criar-base-demo.sql` (SYSDBA/masterkey; a
   senha pode vir de `CVC_LOOKUP_DB_PASSWORD`).
2. Rodar: `powershell -File run.ps1` (compila em Debug, executa com `/auto` e
   mostra o resultado; o codigo de saida e o numero de falhas).

Precisa rodar numa sessao com area de trabalho (PowerShell/terminal normal; o
Git Bash da ferramenta nao tem desktop e a janela trava).

Cenarios: selecao na grade (T01), Enter sem alteracao (T02), edicao/reversao
(T03-T04), vazio, unico, codigo, invalido, cancelar grade, pesquisa explicita,
navegacao no dataset, registro novo, LoadByID/Clear, referencia prioritaria,
vendedor inativo, saida do campo e segunda tabela.
