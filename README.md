# CVC-VCL

Suite de componentes VCL reutilizáveis para aplicações Delphi, com foco em
componentes de edição ligados a banco de dados e padronização visual.

## Componentes

- `TDBLookupEdit`: lookup com código, descrição e pesquisa integrada.
- `TCVCDBEdit`: `TDBEdit` com aparência consistente para campos desabilitados.
- `TCVCDateEdit`: `TJvDateEdit` com o mesmo padrão visual de desabilitado.
- `TCVCValidateEdit`: `TJvValidateEdit` com o mesmo padrão visual de desabilitado.
- `TCpfCnpjDBEdit`: máscara e validação de CPF/CNPJ em campo ligado a dataset.
- `TCustomBtn`: botão customizado com texto e imagem PNG opcional.
- `TDBValueComboBox`: combo ligado a dataset com valores persistidos separados.
- `TDBPersonComboBox`: combo ligado a dataset para textos e valores de pessoas.
- `TDateBox`: grupo de período com filtros de data e geração de SQL.

## Cor global de componentes desabilitados

Defina a cor uma única vez, por exemplo na inicialização do projeto ou no
`DataModule` principal:

```delphi
uses
  CVCVisualSettings;

begin
  SetCVCDisabledColor($00E6E6E6);
end;
```

Essa configuração atualiza os componentes CVC já criados e também passa a ser
o padrão dos próximos componentes. Para uma exceção individual, defina a
propriedade `DisabledColor` do componente no Object Inspector ou em código.

## Compatibilidade

O pacote é preparado inicialmente para Delphi 10.3 Rio Win32 e utiliza JVCL
para o componente de data. Outras versões poderão ser adicionadas conforme os
testes de compilação.

## Instalação

1. Feche o Delphi.
2. Execute `Scripts\Install-CVCVcl.ps1`.
3. Reabra o Delphi.
4. Procure os componentes na aba `CVC-VCL`.

O instalador compila e instala os pacotes runtime `CVCVcl` e `CVCExtras`, além
dos pacotes de design-time correspondentes. O `EditDialogFireDAC` permanece
organizado em sua pasta própria por possuir dependências e units de design-time
específicas; ele não é misturado ao pacote base automaticamente.

Para remover o pacote:

```powershell
.\Scripts\Install-CVCVcl.ps1 -Uninstall
```

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para os termos
completos. Os componentes incorporados preservam os créditos de seus autores.
