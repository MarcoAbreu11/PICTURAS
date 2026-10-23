# Teste manual no navegador: conversão e partilha (CONV-039, RNG-09)

Objetivo: confirmar que um convidado continua a usar um projeto partilhado depois de o dono converter um
vídeo, e que só os vídeos convertidos (e os resultados da conversão) ficam visíveis apenas ao dono.

## Preparação

1. Arrancar a stack na raiz do repositório:
   ```bash
   docker compose up -d --build
   docker compose restart nginx users subscriptions
   ```
   Se o arranque falhar com "port 9090 already in use", a porta da interface do SeaweedFS está ocupada por
   outro programa; fecha-o ou muda temporariamente `9090:8888` para `19090:8888` no `docker-compose.yaml`
   (não faças commit dessa alteração).
2. Abrir https://localhost:8080 (aceitar o certificado autoassinado).
3. Criar **duas contas registadas**: **A** (dono) e **B** (convidado). Usar uma janela normal para A e uma
   janela privada (ou outro navegador) para B.
4. Ter um vídeo MP4 com vídeo H.264 e áudio AAC, com menos de 60 s e 100 MB (ex.: `aula.mp4`).

## Testes

Marca cada linha com ✅ ou ❌ e anota o que viste quando falhar.

| # | Quem | Passos | Resultado esperado | OK? |
|---|---|---|---|---|
| W1 | A | Criar o projeto "Teste partilha", carregar `aula.mp4`, abrir o vídeo, escolher **Converter / comprimir**, formato WebM, 360p, guardar e **Apply**. | No fim, a lista de itens do projeto tem `aula.mp4` **e** `aula_converted.webm`. Depois, remover a ferramenta de conversão da pipeline: o vídeo convertido fica na lista. | |
| W2 | A | **Partilhar projeto** com permissão **Editar** e copiar o link. | É gerado um link. | |
| W3 | B | Abrir o link de W2 (com sessão iniciada). | O projeto **abre sem erro**. Aparece `aula.mp4`; **não** aparece `aula_converted.webm`. Os resultados não mostram o vídeo convertido. | |
| W4 | B | Abrir `aula.mp4`, escolher **Cortar vídeo**, de 00:00 a 00:02, guardar e **Apply**. | Processa **só 1 vídeo** (`aula.mp4`); o resultado é um vídeo de ≈ 2 s. O vídeo convertido não é processado nem referido. | |
| W5 | B | Tentar adicionar **Converter / comprimir**. | É recusado: só o dono converte vídeos. | |
| W6 | A | Voltar a abrir o projeto. | Continua a ver `aula.mp4` e `aula_converted.webm`; vê também o resultado do corte feito por B. | |
| W7 | A | **Partilhar projeto** com permissão **Ver** e abrir o link na janela de B. | O projeto abre só para consulta, sem `aula_converted.webm` e sem poder adicionar ferramentas. | |
| W8 | A | Apagar `aula_converted.webm` da lista de itens. | É apagado (o dono pode). | |

## Regressão rápida (as outras ferramentas continuam a funcionar)

| # | Quem | Passos | Resultado esperado | OK? |
|---|---|---|---|---|
| R1 | A | Num projeto novo com `aula.mp4`: **Extrair frames** a cada 1 s, **Apply**. | Aparecem imagens nos resultados, uma por segundo. | |
| R2 | A | No mesmo projeto: trocar por **Desfocar caras** e **Apply**. | Vídeo gerado com a mesma duração; aviso se não houver caras. | |
| R3 | A | **Legendas automáticas**, idioma Original, **Apply** (vídeo com fala). | Fica uma faixa de legendas ativa no leitor. | |

## Se algo falhar

Anota o número do teste, o que aparece no ecrã e, se possível, a mensagem do separador Rede (F12) do pedido
que falhou. Os registos do serviço veem-se com `docker compose logs --tail 50 projects`.
