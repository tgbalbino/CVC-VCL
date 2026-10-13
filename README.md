# CVC-VCL

Suite de componentes VCL reutilizáveis para aplicações Delphi, com foco em
componentes de edição ligados a banco de dados e padronização visual.

## Componentes

- `TDBLookupEdit`: lookup com código, descrição e pesquisa integrada.
- `TCVCDBEdit`: `TDBEdit` com aparência consistente para campos desabilitados.
- `TCVCDateEdit`: `TJvDateEdit` com o mesmo padrão visual de desabilitado.
- `TCpfCnpjDBEdit`: máscara e validação de CPF/CNPJ em campo ligado a dataset.

## Compatibilidade

O pacote é preparado inicialmente para Delphi 10.3 Rio Win32 e utiliza JVCL
para o componente de data. Outras versões poderão ser adicionadas conforme os
testes de compilação.

## Instalação

1. Feche o Delphi.
2. Execute `Scripts\Install-CVCVcl.ps1`.
3. Reabra o Delphi.
4. Procure os componentes na aba `CVC-VCL`.

O instalador compila e instala separadamente o pacote runtime `CVCVcl` e o
pacote de design-time `dclCVCVcl`. Assim, aplicações podem usar os componentes
sem depender diretamente dos fontes da suíte.

Para remover o pacote:

```powershell
.\Scripts\Install-CVCVcl.ps1 -Uninstall
```

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para os termos
completos. Os componentes incorporados preservam os créditos de seus autores.
