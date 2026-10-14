# CustomBtn

## O que faz

`TCustomBtn` é um controle desenhado manualmente que mostra texto e uma imagem
PNG opcional, recebida pelo método `LoadPngFromFile`, e dispara `OnClick`.

## Melhorias sugeridas sem quebra

- Publicar a imagem como uma propriedade `TPngImage` com `SetPng` funcional.
- Respeitar `Enabled` no desenho e bloquear o clique quando desabilitado.
- Usar `Caption` e `OnClick` herdados de `TControl` quando possível.
- Tratar teclado, foco e estados pressionado/hover para acessibilidade.
