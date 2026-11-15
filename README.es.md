# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [한국어](README.ko.md) | **Español** | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

Servidor MCP para la gestión de extensiones de Chrome Web Store. Sube, publica y administra extensiones de Chrome directamente desde Claude Code o cualquier cliente MCP.

> Fork de [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp), actualizado para la **API V2** de Chrome Web Store: autenticación con cuenta de servicio, un flujo OAuth funcional (Google eliminó el antiguo flujo `oob`) y el SDK de MCP más reciente.

## Cuándo usarlo

Usa este MCP cuando necesites:

- **"Subir una nueva versión de mi extensión de Chrome"** — compila tu ZIP y usa la herramienta `upload` para enviarlo como borrador
- **"Publicar mi extensión en Chrome Web Store"** — usa `publish` para enviarla a revisión y publicarla
- **"Comprobar el estado de revisión de mi extensión"** — usa `status` para ver el estado de la revisión, la versión y el porcentaje de despliegue
- **"Subir y publicar en un solo paso"** — usa `submit` para ejecutar upload → publish → status en una sola llamada
- **"Cancelar un envío pendiente"** — usa `cancel` para retirar un envío que está en revisión
- **"Configurar un despliegue escalonado de mi extensión"** — usa `publish` con `deployPercentage` y luego `deploy-percentage` para ir aumentándolo
- **"La nueva versión falla, quiero revertirla"** — usa `rollback` (valida antes con `validateOnly=true`)
- **"Mostrar mis últimas reseñas / valoración"** — usa `reviews` y `rating-summary`
- **"¿Cuántas instalaciones y usuarios activos tuve el mes pasado?"** — usa `metrics`

## Herramientas

| Herramienta | Descripción |
|---|---|
| `upload` | Sube un archivo ZIP a Chrome Web Store (actualiza el borrador de un elemento existente) |
| `publish` | Publica una extensión con despliegue escalonado opcional, tipo de publicación y omisión de revisión |
| `status` | Obtiene el estado actual, incluidos el estado de revisión, el porcentaje de despliegue y la versión |
| `cancel` | Cancela un envío pendiente |
| `deploy-percentage` | Establece el porcentaje de despliegue escalonado (0-100, debe superar el objetivo actual) |
| `get`, `update-metadata` | Herramientas heredadas de metadatos; el servidor las bloquea tras su fecha límite de v1 (ver más abajo) |
| `submit` | Todo en uno: ejecuta upload → publish → status en una sola llamada (con comprobación previa de existencia y errores legibles) |
| `rollback` | Vuelve a publicar una versión publicada anteriormente con un número de versión nuevo y superior (sin revisión; admite simulación con `validateOnly`) |
| `reviews` | Obtiene las reseñas de usuarios con paginación, ordenación (`rating`, `create_time desc`) y filtro por valoración |
| `rating-summary` | Obtiene la valoración media, el número de valoraciones y el recuento por estrellas |
| `metrics` | Consulta instalaciones, desinstalaciones, usuarios diarios/de 7 días, impresiones y visitas a la página en un rango de fechas, con la opción de segmentar por una dimensión |

`reviews`, `rating-summary` y `metrics` son de solo lectura; también aceptan credenciales limitadas al ámbito `https://www.googleapis.com/auth/chromewebstore.readonly`, pero el servidor solicita el ámbito completo `chromewebstore` para las cuentas de servicio.

> La API de Chrome Web Store no puede crear elementos. Crea un elemento nuevo manualmente en el Developer Dashboard de Chrome Web Store y luego usa `upload` / `publish` (o `submit`) con su ID de elemento.

## Metadatos del listado

El servidor bloquea `get` y `update-metadata` cuando su reloj supera las **2026-10-15 00:00 UTC**, antes de realizar cualquier solicitud a la API. Estas herramientas heredadas siguen apareciendo en el descubrimiento, pero no se pueden usar después de esa fecha límite. Edita el texto del listado y otros metadatos manualmente en el Developer Dashboard de Chrome Web Store; este servidor no tiene un reemplazo de metadatos para v2 ni automatización del navegador.

Usa `status` para consultar el estado de la revisión, la versión y la información de despliegue. Los prompts dirigen el trabajo con los metadatos del listado al Developer Dashboard. El recurso `cws://extensions/{extensionId}` sigue devolviendo el estado v2 después de la fecha límite, omite la solicitud v1 e informa `metadata.unavailable`.

## Configuración

Instala Node.js **20 o superior** para usar los ejemplos con `npx` que aparecen más abajo, o instala Bun y sustituye `"command": "npx"` y `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` por `"command": "bunx"` y `"args": ["--bun", "@kagayoi/cws-mcp@latest"]` (equivale a ejecutar `bunx --bun @kagayoi/cws-mcp@latest`) para ejecutarlo sin Node.js. Ninguna de las dos opciones requiere una instalación global del paquete. Con `@latest`, cada inicio ejecuta la última versión publicada en npm.

Si ya registraste el servidor con una versión fijada (por ejemplo `@kagayoi/cws-mcp@2.0.10`) o sin versión (`@kagayoi/cws-mcp`), cambia el argumento del paquete en ese registro a `@kagayoi/cws-mcp@latest`; actualizar este README no modifica los registros existentes, pero tras esa edición cada inicio usará automáticamente la última versión.

Autentícate **ya sea** con una cuenta de servicio (recomendado, ideal para CI/CD) **o** con un token de actualización de OAuth2.

### Opción A — Cuenta de servicio (recomendado)

1. En la [Google Cloud Console](https://console.cloud.google.com/), crea o selecciona un proyecto y habilita la **Chrome Web Store API**.
2. Crea una **cuenta de servicio** y luego añade una **clave JSON** (Keys → Add key → Create new key → JSON).
3. En el [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **Account**, añade el correo electrónico de la cuenta de servicio para concederle acceso a la API de tu cuenta de editor.
4. Establece `CWS_SERVICE_ACCOUNT_KEY` con la **ruta del archivo de clave JSON** (o con su contenido JSON sin procesar).

Consulta [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts) para más detalles.

### Opción B — Token de actualización de OAuth2

1. En la [Google Cloud Console](https://console.cloud.google.com/), crea o selecciona un proyecto y habilita la **Chrome Web Store API**.
2. Crea **credenciales de OAuth2** de tipo **Desktop app**. Anota el **Client ID** y el **Client Secret**.
3. Obtén un token de actualización mediante una **redirección de loopback**. (Google eliminó en 2022 el antiguo flujo `urn:ietf:wg:oauth:2.0:oob` y ya no funciona; ahora los clientes de escritorio usan `http://localhost`.)

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

   La respuesta contiene tu `refresh_token`. Para los clientes de tipo Desktop app se acepta cualquier redirección `http://localhost[:PORT]` o `http://127.0.0.1[:PORT]`.

### Configurar MCP

Añade la siguiente definición de servidor a la configuración de tu cliente MCP. El ejemplo usa el formato `mcpServers`; utiliza la ubicación de configuración o el comando para añadir servidores que documente tu cliente.

**Mediante npm con una cuenta de servicio (recomendado):**

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

**Mediante npm con un token de actualización de OAuth:**

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

## Variables de entorno

Proporciona **o bien** una clave de cuenta de servicio (Auth A) **o bien** el trío de token de actualización de OAuth2 (Auth B).

| Variable | Obligatoria | Descripción |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | Auth A | Ruta de un archivo de clave JSON de cuenta de servicio, o la cadena JSON sin procesar. Tiene prioridad sobre OAuth cuando está definida. |
| `CWS_CLIENT_ID` | Auth B | Client ID de Google OAuth2 |
| `CWS_CLIENT_SECRET` | Auth B | Client Secret de Google OAuth2 |
| `CWS_REFRESH_TOKEN` | Auth B | Token de actualización de OAuth2 |
| `CWS_PUBLISHER_ID` | No | ID del editor (por defecto: `me`) |
| `CWS_ITEM_ID` | No | ID de elemento de extensión predeterminado |

## Ejemplos de uso

### Comprobar el estado de la extensión
```
Use the cws-mcp status tool
```

La respuesta incluye el estado sin procesar de la API y un resumen de mejor esfuerzo. Cuando existen, las revisiones publicadas y enviadas se muestran por separado, con la versión y el porcentaje de despliegue de cada canal de lanzamiento. También se muestran los indicadores de retirada y de advertencia, así como el último estado de subida asíncrona, cuando se proporcionan. Un resumen sin problemas extraídos no confirma la aprobación; inspecciona la respuesta sin procesar para ver los detalles. Si hay retiradas o advertencias activas, es necesario revisar el Developer Dashboard.

### Subir y publicar
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### Publicar con un porcentaje de despliegue inicial
```
Use cws-mcp publish with:
- deployPercentage=10
```

En cambio, `publishType="STAGED_PUBLISH"` deja la versión aprobada preparada para su publicación manual; por sí solo no establece el porcentaje de despliegue. El tipo de publicación predeterminado publica tras la aprobación. `skipReview=true` solo intenta omitir la revisión cuando se cumplen los requisitos.

### Publicar omitiendo la revisión
```
Use cws-mcp publish with skipReview=true
```

### Despliegue escalonado
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

Nota: `deploy-percentage` solo está disponible para extensiones con 10 000 o más usuarios activos en siete días. El nuevo porcentaje siempre debe ser superior al objetivo actual.

### Revertir una versión defectuosa
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

Una reversión se aplica a todos los usuarios en aproximadamente un minuto y sin revisión. Descarta los envíos pendientes y preparados y, durante un despliegue por porcentaje, vuelve a la última versión desplegada al 100 %. `newVersion` debe ser superior a la versión publicada actual. Las reversiones repetidas alternan entre las mismas dos versiones, así que asegúrate de que la versión anterior pueda manejar los datos escritos por la más reciente.

### Reseñas, valoraciones y métricas
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` acepta como máximo una dimensión. Los resultados están paginados; pasa el `nextPageToken` devuelto como `pageToken` con el resto de parámetros idénticos.

## Solución de problemas

- **Credenciales ausentes / 401 / 403:** revisa el entorno del proceso del servidor y el acceso al elemento y al editor. Una clave de cuenta de servicio configurada tiene prioridad; las credenciales de cuenta de servicio no válidas no recurren a OAuth.
- **Elemento inexistente / 404:** crea primero el elemento en el Developer Dashboard y luego pasa `itemId` o define `CWS_ITEM_ID`. No existe una herramienta para listar todos los elementos.
- **ZIP ilegible:** `zipPath` debe apuntar a un archivo accesible en la máquina que ejecuta el servidor MCP, incluido el interior de su contenedor si corresponde. Compila el ZIP antes de llamar a `upload` o `submit`.
- **Subida aún en proceso o finalización desconocida:** `upload` y `submit` solo informan éxito cuando la subida se ha confirmado como correcta. En caso contrario, `submit` se detiene antes de publicar; ninguna de las dos herramientas hace sondeo automático. Evita subir de nuevo o repetir `submit` mientras el procesamiento pueda continuar. Usa `status` para comprobar `lastAsyncUploadState` y usa `publish` por separado solo después de confirmar que el ZIP previsto se procesó correctamente. Este estado cubre la última subida asíncrona de las últimas 24 horas; por tanto, si hubo otra subida o el estado falta o es ambiguo, verifica primero el borrador en el Developer Dashboard.
- **Ya en revisión / versión duplicada:** espera a la revisión o usa `cancel` antes de subir; si la versión está duplicada, aumenta la versión en el `manifest.json` de la extensión y vuelve a compilar su ZIP.
- **Estado de subida `NOT_FOUND`:** se trata como una subida fallida; no se intenta publicar. Vuelve a comprobar el ID del elemento y sube de nuevo.
- **La subida tuvo éxito pero la publicación falló:** si fue un error HTTP, reintenta solo `publish`. Si la solicitud de publicación agotó el tiempo de espera o falló la conexión, comprueba primero `status`, porque el resultado de la publicación es desconocido. Volver a ejecutar `submit` sube el ZIP de nuevo. `submit` conserva los pasos completados ante errores de comunicación y devuelve una instantánea inmediata del estado; no espera a que termine la revisión. Vuelve a comprobar `status` si falló el paso final de estado e inspecciona la respuesta sin procesar cuando un resumen no tenga problemas extraídos.
- **Error de metadatos heredados:** usa el Developer Dashboard como se describe en [Metadatos del listado](#metadatos-del-listado).

## Desarrollo

Para los comandos de compilación locales y la verificación, consulta [AGENTS.md](AGENTS.md). Para los límites de los componentes, la correspondencia con la API y el comportamiento ante fallos de envío, consulta [DESIGN.md](DESIGN.md).

## Licencia

MIT
