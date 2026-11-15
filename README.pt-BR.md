# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | **Português (Brasil)**

Servidor MCP para gerenciar extensões na Chrome Web Store. Envie, publique e gerencie extensões do Chrome diretamente do Claude Code ou de qualquer cliente MCP.

> Fork de [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp), atualizado para a **API V2** da Chrome Web Store: autenticação por conta de serviço, um fluxo OAuth funcional (o Google removeu o antigo fluxo `oob`) e o SDK MCP mais recente.

## Quando usar

Use este MCP quando precisar:

- **"Enviar uma nova versão da minha extensão do Chrome"** — gere seu ZIP e use a ferramenta `upload` para enviá-lo como rascunho
- **"Publicar minha extensão na Chrome Web Store"** — use `publish` para enviar para revisão e publicar
- **"Verificar o status de revisão da minha extensão"** — use `status` para ver o estado da revisão, a versão e a porcentagem de implantação
- **"Enviar e publicar em uma única etapa"** — use `submit` para executar envio → publicação → status em uma única chamada
- **"Cancelar um envio pendente"** — use `cancel` para retirar um envio que está em revisão
- **"Configurar uma implantação gradual para minha extensão"** — use `publish` com `deployPercentage` e depois `deploy-percentage` para ampliar aos poucos
- **"A nova versão está com problemas, reverta"** — use `rollback` (valide antes com `validateOnly=true`)
- **"Mostrar minhas avaliações mais recentes / nota"** — use `reviews` e `rating-summary`
- **"Quantas instalações e usuários ativos tive no mês passado?"** — use `metrics`

## Ferramentas

| Ferramenta | Descrição |
|---|---|
| `upload` | Envia um arquivo ZIP para a Chrome Web Store (atualiza o rascunho de um item existente) |
| `publish` | Publica uma extensão com implantação gradual, tipo de publicação e omissão de revisão opcionais |
| `status` | Obtém o status atual, incluindo estado da revisão, porcentagem de implantação e versão |
| `cancel` | Cancela um envio pendente |
| `deploy-percentage` | Define a porcentagem da implantação gradual (0-100, deve ser maior que o alvo atual) |
| `get`, `update-metadata` | Ferramentas legadas de metadados; bloqueadas pelo servidor após a data de corte da v1 (veja abaixo) |
| `submit` | Tudo em um: executa envio → publicação → status em uma única chamada (com verificação prévia de existência e erros legíveis) |
| `rollback` | Republica uma versão publicada anteriormente com um novo número de versão maior (sem revisão; suporta simulação com `validateOnly`) |
| `reviews` | Obtém avaliações de usuários com paginação, ordenação (`rating`, `create_time desc`) e filtro por nota |
| `rating-summary` | Obtém a nota média, o número de avaliações e a contagem por estrela |
| `metrics` | Consulta instalações, desinstalações, usuários diários/de 7 dias, impressões e visualizações de página em um intervalo de datas, opcionalmente dividido por uma dimensão |

`reviews`, `rating-summary` e `metrics` são somente leitura; também aceitam credenciais limitadas ao escopo `https://www.googleapis.com/auth/chromewebstore.readonly`, mas o servidor solicita o escopo completo `chromewebstore` para contas de serviço.

> A API da Chrome Web Store não pode criar itens. Crie um novo item manualmente no Chrome Web Store Developer Dashboard e depois use `upload` / `publish` (ou `submit`) com o ID desse item.

## Metadados da listagem

O servidor bloqueia `get` e `update-metadata` quando seu relógio indica uma data posterior a **2026-10-15 00:00 UTC**, antes de fazer qualquer requisição à API. Essas ferramentas legadas continuam visíveis na descoberta, mas não podem ser usadas após essa data de corte. Edite o texto da listagem e outros metadados manualmente no Chrome Web Store Developer Dashboard; este servidor não tem substituto v2 para metadados nem automação de navegador.

Use `status` para o estado da revisão, a versão e as informações de implantação. Os prompts direcionam o trabalho com metadados da listagem ao Developer Dashboard. O recurso `cws://extensions/{extensionId}` continua retornando o status v2 após a data de corte, ignora a requisição v1 e informa `metadata.unavailable`.

## Configuração

Instale o Node.js **20 ou mais recente** para usar os exemplos com `npx` abaixo, ou instale o Bun e substitua `"command": "npx"` e `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` por `"command": "bunx"` e `"args": ["--bun", "@kagayoi/cws-mcp@latest"]` (equivale a executar `bunx --bun @kagayoi/cws-mcp@latest`) para executar sem Node.js. Nenhuma das opções exige instalação global do pacote. Com `@latest`, cada inicialização executa a versão mais recente do npm.

Se você já registrou o servidor com uma versão fixa (por exemplo `@kagayoi/cws-mcp@2.0.10`) ou sem versão (`@kagayoi/cws-mcp`), altere o argumento do pacote nesse registro para `@kagayoi/cws-mcp@latest`; atualizar este README não altera registros existentes, mas depois dessa edição cada inicialização usará automaticamente a versão mais recente.

Autentique-se com **uma** conta de serviço (recomendado, ideal para CI/CD) **ou** com um refresh token OAuth2.

### Opção A — Conta de serviço (recomendado)

1. No [Google Cloud Console](https://console.cloud.google.com/), crie/selecione um projeto e ative a **Chrome Web Store API**.
2. Crie uma **conta de serviço** e adicione uma **chave JSON** (Chaves → Adicionar chave → Criar nova chave → JSON).
3. No [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **Conta**, adicione o e-mail da conta de serviço para conceder a ela acesso à API da sua conta de publicador.
4. Defina `CWS_SERVICE_ACCOUNT_KEY` como o **caminho do arquivo de chave JSON** (ou seu conteúdo JSON bruto).

Veja mais detalhes em [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts).

### Opção B — Refresh token OAuth2

1. No [Google Cloud Console](https://console.cloud.google.com/), crie/selecione um projeto e ative a **Chrome Web Store API**.
2. Crie **credenciais OAuth2** do tipo **App para computador**. Anote o **Client ID** e o **Client Secret**.
3. Obtenha um refresh token usando um **redirecionamento loopback**. (O antigo fluxo `urn:ietf:wg:oauth:2.0:oob` foi removido pelo Google em 2022 e não funciona mais — os clientes desktop agora usam `http://localhost`.)

   ```bash
   # 1. Open this URL in a browser and grant access:
   #    https://accounts.google.com/o/oauth2/v2/auth?response_type=code&access_type=offline&prompt=consent&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fchromewebstore&client_id=YOUR_CLIENT_ID&redirect_uri=http://localhost:8080
   #
   # 2. The browser is redirected to http://localhost:8080/?code=AUTH_CODE&...
   #    (no server needed — just copy the `code` value from the address bar).
   #
   # 3. Exchange the code for a refresh token:
   curl -X POST https://oauth2.googleapis.com/token \
     -d "client_id=YOUR_CLIENT_ID" \
     -d "client_secret=YOUR_CLIENT_SECRET" \
     -d "code=YOUR_AUTH_CODE" \
     -d "grant_type=authorization_code" \
     -d "redirect_uri=http://localhost:8080"
   ```

   A resposta contém seu `refresh_token`. Qualquer redirecionamento `http://localhost[:PORT]` ou `http://127.0.0.1[:PORT]` é aceito para clientes do tipo App para computador.

### Configurar o MCP

Adicione a seguinte definição de servidor à configuração do seu cliente MCP. O exemplo usa o formato `mcpServers`; use o local de configuração ou o comando de adição de servidor documentado pelo seu cliente.

**Via npm com uma conta de serviço (recomendado):**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["--yes", "@kagayoi/cws-mcp@latest"],
      "env": {
        "CWS_SERVICE_ACCOUNT_KEY": "/path/to/service-account.json",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

**Via npm com um refresh token OAuth:**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["--yes", "@kagayoi/cws-mcp@latest"],
      "env": {
        "CWS_CLIENT_ID": "xxxxx.apps.googleusercontent.com",
        "CWS_CLIENT_SECRET": "GOCSPX-xxxxx",
        "CWS_REFRESH_TOKEN": "1//xxxxx",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

## Variáveis de ambiente

Forneça **ou** uma chave de conta de serviço (Auth A) **ou** o trio de refresh token OAuth2 (Auth B).

| Variável | Obrigatória | Descrição |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | Auth A | Caminho de um arquivo de chave JSON da conta de serviço, ou a string JSON bruta. Tem precedência sobre o OAuth quando definida. |
| `CWS_CLIENT_ID` | Auth B | Client ID do Google OAuth2 |
| `CWS_CLIENT_SECRET` | Auth B | Client Secret do Google OAuth2 |
| `CWS_REFRESH_TOKEN` | Auth B | Refresh token OAuth2 |
| `CWS_PUBLISHER_ID` | Não | ID do publicador (padrão: `me`) |
| `CWS_ITEM_ID` | Não | ID do item de extensão padrão |

## Exemplos de uso

### Verificar o status da extensão
```
Use the cws-mcp status tool
```

A resposta inclui o status bruto da API e um resumo feito com o melhor esforço. Quando presentes, as revisões publicada e enviada são mostradas separadamente, com a versão e a porcentagem de implantação de cada canal de lançamento. Os indicadores de remoção e de aviso e o último estado de envio assíncrono também são mostrados quando fornecidos. Um resumo sem problemas extraídos não confirma aprovação; inspecione a resposta bruta para ver os detalhes. Remoções ou avisos ativos exigem a verificação no Developer Dashboard.

### Enviar e publicar
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### Publicar com uma porcentagem inicial de implantação
```
Use cws-mcp publish with:
- deployPercentage=10
```

Em vez disso, `publishType="STAGED_PUBLISH"` deixa a versão aprovada preparada para publicação manual; ele não define por si só a porcentagem de implantação. O tipo de publicação padrão publica após a aprovação. `skipReview=true` apenas tenta pular a revisão quando elegível.

### Publicar com omissão de revisão
```
Use cws-mcp publish with skipReview=true
```

### Implantação gradual
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

Observação: `deploy-percentage` só está disponível para extensões com 10.000 ou mais usuários ativos em sete dias. A nova porcentagem deve ser sempre maior que o alvo atual.

### Reverter uma versão com problemas
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

Uma reversão entra no ar para todos os usuários em cerca de um minuto, sem revisão. Ela descarta envios pendentes e em etapas e, durante uma implantação percentual, volta para a última versão implantada a 100%. `newVersion` deve ser maior que a versão publicada atual. Reversões repetidas alternam entre as mesmas duas versões, portanto certifique-se de que a versão mais antiga consiga lidar com os dados gravados pela mais nova.

### Avaliações, notas e métricas
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` aceita no máximo uma dimensão. Os resultados são paginados; passe o `nextPageToken` retornado como `pageToken`, mantendo os demais parâmetros idênticos.

## Solução de problemas

- **Credenciais ausentes / 401 / 403:** verifique o ambiente do processo do servidor e o acesso ao item/publicador. Uma chave de conta de serviço configurada tem precedência; credenciais de conta de serviço inválidas não recorrem ao OAuth.
- **Item ausente / 404:** crie o item primeiro no Developer Dashboard e depois informe `itemId` ou defina `CWS_ITEM_ID`. Não existe uma ferramenta para listar todos os itens.
- **ZIP ilegível:** `zipPath` deve apontar para um arquivo acessível na máquina que executa o servidor MCP, inclusive dentro do contêiner, se aplicável. Gere o ZIP antes de chamar `upload` ou `submit`.
- **Envio ainda em processamento ou conclusão desconhecida:** `upload` e `submit` só informam sucesso quando o envio foi confirmado como bem-sucedido. Caso contrário, `submit` para antes de publicar; nenhuma das ferramentas faz polling automaticamente. Evite outro envio ou repetir `submit` enquanto o processamento ainda puder continuar. Use `status` para verificar `lastAsyncUploadState` e só então use `publish` isoladamente, depois de confirmar que o ZIP pretendido foi bem-sucedido. Esse status cobre o último envio assíncrono nas últimas 24 horas; portanto, se houve outro envio ou se o estado está ausente ou ambíguo, verifique primeiro o rascunho no Developer Dashboard.
- **Já em revisão / versão duplicada:** aguarde a revisão ou use `cancel` antes de enviar; para uma versão duplicada, aumente a versão no `manifest.json` da extensão e gere o ZIP novamente.
- **Estado de envio `NOT_FOUND`:** tratado como envio com falha; a publicação não é tentada. Verifique novamente o ID do item e envie de novo.
- **Envio bem-sucedido, mas publicação com falha:** em caso de erro HTTP, repita apenas `publish`. Se a requisição de publicação expirou ou a conexão falhou, verifique `status` primeiro, pois o resultado da publicação é desconhecido. Executar `submit` novamente envia o ZIP outra vez. `submit` mantém as etapas concluídas em caso de erros de comunicação e retorna um instantâneo imediato do status; ele não aguarda a conclusão da revisão. Verifique `status` novamente se a última etapa de status falhou e inspecione a resposta bruta quando um resumo não tiver problemas extraídos.
- **Erro de metadados legados:** use o Developer Dashboard conforme descrito em [Metadados da listagem](#metadados-da-listagem).

## Desenvolvimento

Para comandos de build locais e verificação, veja [AGENTS.md](AGENTS.md). Para os limites dos componentes, o mapeamento da API e o comportamento em caso de falha de envio, veja [DESIGN.md](DESIGN.md).

## Licença

MIT
