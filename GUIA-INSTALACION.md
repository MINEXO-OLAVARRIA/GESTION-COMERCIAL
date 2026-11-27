# MINEXO · Gestión comercial — Puesta en la web

Tiempo estimado: 30–40 minutos, una sola vez. No hace falta programar.

## 0. Antes de empezar: todo a nombre de Minexo
Usá **un email de Minexo** (ideal uno genérico como `sistemas@minexo.com.ar` o `admin@minexo.com.ar`, no uno personal) para crear las tres cuentas: **GitHub**, **Supabase** y **Netlify**. Guardá las contraseñas en un lugar de la empresa y activá la verificación en dos pasos. Así el sistema queda en manos de Minexo aunque cambie quien lo administra.

En cada servicio después podés **invitar a tu usuario personal** como colaboradora para trabajar sin usar la cuenta de la empresa.

**Qué se usa**
- **Supabase** (base de datos + usuarios + archivos). Plan gratuito: 500 MB de datos y 1 GB de archivos. Si van a subir muchas fotos o PDFs, el plan Pro cuesta US$ 25/mes (100 GB). En el plan gratuito, si nadie entra durante 7 días el proyecto se pausa y hay que reactivarlo desde el panel.
- **GitHub** (guarda el código y el historial de cambios). Gratis.
- **Netlify** (publica la página y se actualiza sola con cada cambio en GitHub). Gratis.

**Contenido de la carpeta**
| Archivo | Para qué |
|---|---|
| `index.html` | El sistema |
| `config.js` | Conexión con tu base (lo completás en el paso 6) |
| `geo/` | Capas del mapa |
| `supabase/schema.sql` | Crea tablas, permisos y almacenamiento de archivos |
| `supabase/functions/admin-usuarios/index.ts` | Permite crear usuarios desde el sistema |

---

## 1. Crear el proyecto en Supabase
1. Entrá a **supabase.com** → *Start your project* → registrate (podés usar la cuenta de Google de Minexo).
2. *New project*: nombre `minexo-gestion`, una contraseña de base de datos (guardala), región **South America (São Paulo)**.
3. Esperá 1–2 minutos a que termine de crearse.

## 2. Crear la base de datos
1. Menú izquierdo → **SQL Editor** → *New query*.
2. Abrí **`supabase/schema-CODIGO.txt`** con el Bloc de notas (es lo mismo que `schema.sql`), copiá todo, pegalo y tocá **Run**.
3. Tiene que decir *Success*. (Si lo corrés dos veces no pasa nada.)

## 3. Configurar el acceso
1. **Authentication → Sign In / Providers**: desactivá **Allow new users to sign up** (así solo entra quien vos crees).
2. **Authentication → URL Configuration**: en *Site URL* poné la dirección del sitio cuando la tengas (paso 7). Sirve para el mail de "Olvidé mi contraseña".

## 4. Crear tu usuario (administrador)
1. **Authentication → Users → Add user → Create new user**.
2. Tu email y una contraseña. Tildá **Auto Confirm User**.
3. El primer usuario que se crea queda automáticamente como **Administrador**. Tu nombre lo podés corregir después en Ajustes → Usuarios.

## 5. Instalar la función de usuarios
1. Menú izquierdo → **Edge Functions → Deploy a new function → Via Editor**.
2. Borrá el código de ejemplo y pegá el contenido de **`supabase/admin-usuarios-CODIGO.txt`** (se abre con el Bloc de notas; es el mismo código que `functions/admin-usuarios/index.ts`, que Windows a veces no deja abrir).
3. Nombre de la función: **admin-usuarios** (exactamente así). Tocá **Deploy**.
4. En la función → *Details* / *Settings*: desactivá **Verify JWT** y guardá. (La función ya verifica sola que quien la usa sea administrador.)

## 6. Conectar la página con la base
1. **Project Settings → API Keys** (o *Data API*): copiá la **Project URL** y la clave **publishable** (o *anon public*). Nunca uses la *secret / service_role*.
2. Abrí `config.js` con el Bloc de notas (antes de subirlo a GitHub) y reemplazá los dos valores:
   ```js
   window.MINEXO = {
     url: 'https://abcdxyz.supabase.co',
     key: 'sb_publishable_...'
   };
   ```

## 7. Subir el código a GitHub
1. Entrá a **github.com** con la cuenta de Minexo.
2. Recomendado: creá una **organización** gratuita (`+` → *New organization* → plan Free), por ejemplo `minexo-sa`. Así el repositorio es de la empresa y no de una persona.
3. *New repository*: nombre `gestion-comercial`, **Private**, sin README. Crear.
4. En la página del repositorio vacío: *uploading an existing file* → arrastrá **el contenido** de la carpeta `minexo-web` (index.html, config.js, la carpeta geo, la carpeta supabase y esta guía) → *Commit changes*.
5. *Settings → Collaborators* (u *Organization → People*): invitá tu usuario personal de GitHub si vas a hacer cambios vos o con Claude.

`config.js` lleva solo la clave **publishable/anon**, que es pública por diseño: está bien que esté en GitHub. **Nunca** subas la clave *secret / service_role*.

## 8. Publicar en la web con Netlify (se actualiza solo)
1. Entrá a **app.netlify.com** → *Sign up* → **con GitHub**, usando la cuenta de Minexo.
2. *Add new project → Import an existing project → GitHub* → autorizá a Netlify a ver el repositorio `gestion-comercial`.
3. Configuración de build: dejá todo vacío (*Build command* vacío, *Publish directory* vacío o `.`). *Deploy*.
4. *Project configuration → Change project name* → `minexo-gestion` → queda `https://minexo-gestion.netlify.app`.
5. Volvé a Supabase (paso 3.2) y pegá esa dirección en *Site URL*.
6. **Opcional, dominio propio** (`gestion.minexo.com.ar`): Netlify → *Domain management → Add a domain*. Te indica un registro **CNAME** para cargar donde está administrado el dominio de Minexo.

A partir de acá, **cada cambio que se guarde en GitHub se publica solo en 1 minuto**. Si algo sale mal, en Netlify → *Deploys* se puede volver a cualquier versión anterior con un clic (*Publish deploy*).

## 9. Pasar los datos actuales
1. En la versión actual (la de Claude): **Ajustes → Copiar respaldo completo**.
2. En la versión nueva, entrá con tu usuario → **Ajustes → Respaldo** → pegá en el recuadro → **Importar texto pegado**.
3. Verificá en Clientes que estén los 199.

Hacelo justo antes de que el equipo empiece a usar la versión nueva, así no se pierde nada cargado en el medio.

## 10. Crear los usuarios del equipo
**Ajustes → Usuarios → Crear usuario**: nombre, email, contraseña inicial y rol. Pasale los datos a cada persona; después la cambia desde *Cambiar contraseña*.

| Rol | Puede |
|---|---|
| **Administrador** | Todo: usuarios, ajustes, eliminar clientes |
| **Vendedor** | Crear y editar clientes, visitas, viajes, relevamientos y subir archivos |
| **Solo lectura** | Ver todo, sin modificar |

Desactivar un usuario le corta el acceso al instante sin borrar lo que cargó.

---

## Archivos adjuntos
- En la ficha de cada cliente: pestaña **Archivos** (todo) y sección **Archivos del relevamiento** dentro de Relevamiento.
- Se puede arrastrar o elegir varios a la vez; desde el celular permite sacar fotos directo.
- Cada archivo queda con su sección (Relevamiento, Perforación, Trituración, Cotización, Fotos, Informe de visita…), quién lo subió y la fecha.
- Máximo 50 MB por archivo. Los archivos son privados: solo los ven usuarios activos.

## Respaldo
**Ajustes → Respaldo → Descargar respaldo** baja un archivo con todos los datos. Conviene hacerlo una vez por mes.

## Cómo se hacen cambios después
- **Con Claude:** si tu usuario de GitHub es colaborador del repositorio, Claude puede subir los cambios directamente y Netlify los publica solo.
- **A mano:** en GitHub, abrí el archivo → lápiz (*Edit*) → *Commit changes*. O *Add file → Upload files* para reemplazar archivos.
- Todo queda con historial: en GitHub se ve qué cambió, cuándo y quién.
