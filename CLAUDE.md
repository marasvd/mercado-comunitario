# GEMINI.md — Sistema de Gestión de Mercados Comunitarios

> Este archivo es el briefing técnico oficial del proyecto. Toda decisión de arquitectura,
> estructura, seguridad y convención está definida aquí. No improvises fuera de este documento.
> Si encuentras ambigüedad, detente y pregunta antes de generar código.

---

## 1. Contexto del Proyecto

**Nombre**: Sistema de Gestión de Mercados Comunitarios
**Tipo**: Aplicación móvil Android (prototipo con arquitectura production-ready)
**Propósito**: Digitalizar la gestión de jornadas de mercado de una fundación que atiende
población vulnerable, eliminando la coordinación por WhatsApp.

**Problema que resuelve**: pedidos cambiantes, falta de trazabilidad, carga operativa total
sobre la administradora.

**Fase actual**: Prototipo. Android únicamente. iOS fuera del alcance pero la arquitectura
debe soportarlo sin reescribir el sistema desde cero.

**Contexto legal**: Los beneficiarios deben ser informados del uso de sus datos antes del
lanzamiento (Ley 1581 de Colombia). Esto no bloquea el desarrollo pero sí el despliegue.

---

## 2. Stack Tecnológico — Inamovible

| Capa | Tecnología | Notas |
|---|---|---|
| Mobile | Flutter (Dart) | Android 8.0+ / minSdkVersion 26 |
| Estado | Riverpod (última versión estable) | AsyncNotifier + StateNotifier |
| Base de datos | Supabase (PostgreSQL) | Plan gratuito en prototipo |
| Autenticación | Supabase Auth (JWT) | Email ficticio interno, sin correo real |
| Storage | Supabase Storage | Comprobantes de pago, bucket `vouchers` |
| Notificaciones push | Firebase Cloud Messaging (FCM) | Solo para push, no para lógica |
| Router | go_router | Redirección por rol desde el router |
| Pagos | Manual con registro digital | Sin pasarela externa en prototipo |
| Arquitectura Flutter | Feature-first + Riverpod | Ver sección 4 |

**No agregues dependencias fuera de este stack sin justificación explícita.**

---

## 3. Usuarios del Sistema

| Rol | Cantidad | Descripción |
|---|---|---|
| ADMINISTRADOR | 1 por organización | Control total. Único con constraint en DB. |
| ASISTENTE | 1 o más por organización | Panel reducido. No cierra jornadas ni aprueba pagos. |
| BENEFICIARIO | Ilimitado | Solo ve y gestiona su propio pedido en jornadas activas. |

---

## 4. Arquitectura Flutter — Feature-First con Riverpod

### Estructura de carpetas obligatoria

```
lib/
├── main.dart
├── app.dart                            # MaterialApp + GoRouter setup
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── supabase_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart          # Excepción base del proyecto
│   │   └── error_handler.dart
│   ├── extensions/                     # Extensions de Dart/Flutter
│   ├── providers/
│   │   └── supabase_provider.dart      # SupabaseClient como provider global
│   ├── router/
│   │   └── app_router.dart             # GoRouter con guards por rol
│   ├── security/
│   │   └── role_guard.dart             # Helpers de validación de rol desde JWT
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/                        # Widgets globales reutilizables
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── auth_models.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       └── screens/
│   │           └── login_screen.dart
│   ├── beneficiarios/
│   │   ├── data/
│   │   │   └── beneficiarios_repository.dart
│   │   ├── domain/
│   │   │   └── beneficiario_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── beneficiarios_provider.dart
│   │       └── screens/
│   ├── jornadas/
│   │   ├── data/
│   │   │   └── jornadas_repository.dart
│   │   ├── domain/
│   │   │   └── jornada_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── jornadas_provider.dart
│   │       └── screens/
│   ├── pedidos/
│   │   ├── data/
│   │   │   └── pedidos_repository.dart
│   │   ├── domain/
│   │   │   └── pedido_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── pedidos_provider.dart
│   │       └── screens/
│   ├── pagos/
│   │   ├── data/
│   │   │   └── pagos_repository.dart
│   │   ├── domain/
│   │   │   └── pago_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── pagos_provider.dart
│   │       └── screens/
│   ├── productos/
│   │   ├── data/
│   │   │   └── productos_repository.dart
│   │   ├── domain/
│   │   │   └── producto_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── productos_provider.dart
│   │       └── screens/
│   └── consolidados/
│       ├── data/
│       │   └── consolidados_repository.dart
│       ├── domain/
│       │   └── consolidado_model.dart
│       └── presentation/
│           ├── providers/
│           │   └── consolidados_provider.dart
│           └── screens/
└── shared/
    ├── models/                         # Modelos compartidos entre features
    └── widgets/                        # Widgets compartidos entre features
```

### Convenciones de nomenclatura

- Archivos: `snake_case.dart`
- Clases: `PascalCase`
- Variables y métodos: `camelCase`
- Providers: sufijo `Provider` → `authProvider`, `jornadasProvider`
- Repositories: sufijo `Repository` → `AuthRepository`
- Screens: sufijo `Screen` → `LoginScreen`
- Models: sufijo `Model` → `JornadaModel`

### Patrón interno de cada feature

```
feature/
├── data/
│   └── {feature}_repository.dart    # Toda la comunicación con Supabase
├── domain/
│   └── {feature}_model.dart         # Clases Dart puras, sin dependencias externas
└── presentation/
    ├── providers/
    │   └── {feature}_provider.dart  # AsyncNotifier o StateNotifier
    └── screens/
        └── {feature}_screen.dart
```

### Manejo de estado con Riverpod

- `AsyncNotifier` para operaciones asíncronas con Supabase
- `StateNotifier` para estado local de UI complejo
- `FutureProvider` para datos de solo lectura puntuales
- `StreamProvider` para suscripciones Realtime de Supabase (stock en tiempo real)
- **Nunca** manejar estado de negocio en widgets `StatefulWidget`. Solo UI pura
  (animaciones, scroll).

### Router — Guards por rol

GoRouter verifica el rol del JWT antes de permitir navegación a rutas protegidas.

```
/login                  → pública
/beneficiario/*         → solo BENEFICIARIO activo
/admin/*                → solo ADMINISTRADOR
/asistente/*            → ADMINISTRADOR y ASISTENTE
```

El rol se extrae del JWT en cada guard. Nunca se almacena en estado local como
fuente de verdad.

---

## 5. Base de Datos — Supabase / PostgreSQL

### ENUMs — Crear primero, antes de cualquier tabla

```sql
CREATE TYPE user_role     AS ENUM ('ADMINISTRADOR', 'ASISTENTE', 'BENEFICIARIO');
CREATE TYPE jornada_status AS ENUM ('BORRADOR', 'ACTIVA', 'CERRADA');
CREATE TYPE payment_status AS ENUM ('PENDIENTE', 'PAGADO');
CREATE TYPE payment_method AS ENUM ('efectivo', 'nequi');
CREATE TYPE payment_mode   AS ENUM ('efectivo', 'hibrido', 'nequi_api');
```

Los ENUMs garantizan que la base de datos rechace cualquier valor no definido sin
que el código tenga que validarlo. Usar ENUMs en todos los campos de estado y tipo.

### Trigger `updated_at` — Crear antes de las tablas

```sql
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Aplicar a toda tabla con datos mutables (ver cada tabla).

---

### Esquema de tablas

#### `organizations`
```sql
CREATE TABLE organizations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  payment_mode payment_mode NOT NULL DEFAULT 'efectivo',
  created_at   TIMESTAMPTZ DEFAULT now()
);
-- Sin updated_at: cambios infrecuentes, auditables por otros medios.
```

#### `users`
```sql
CREATE TABLE users (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     UUID NOT NULL REFERENCES organizations(id),
  cedula     TEXT NOT NULL UNIQUE,
  full_name  TEXT NOT NULL,
  phone      TEXT,
  role       user_role NOT NULL,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Exactamente 1 ADMINISTRADOR por organización, garantizado a nivel de base de datos.
-- Ninguna lógica de aplicación puede violar esta constraint.
CREATE UNIQUE INDEX one_admin_per_org
  ON users (org_id)
  WHERE role = 'ADMINISTRADOR';

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**Nota sobre autenticación**: Los usuarios se registran en Supabase Auth con email
ficticio `{cedula}@mercados.app`. El usuario nunca lo ve. Supabase gestiona JWT,
refresh tokens y bcrypt. La contraseña inicial de beneficiarios es los últimos 4
dígitos de la cédula. Esta lógica vive exclusivamente en `AuthRepository`.

#### `jornadas`
```sql
CREATE TABLE jornadas (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     UUID NOT NULL REFERENCES organizations(id),
  name       TEXT NOT NULL,
  status     jornada_status NOT NULL DEFAULT 'BORRADOR',
  opens_at   TIMESTAMPTZ,
  closes_at  TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_id, name, opens_at)
);

CREATE TRIGGER jornadas_updated_at
  BEFORE UPDATE ON jornadas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

Transición de estados: BORRADOR → ACTIVA → CERRADA. Unidireccional e irreversible.
Una jornada CERRADA no puede reabrirse bajo ninguna circunstancia. Validar en
repository antes de cualquier UPDATE de estado.

#### `jornada_beneficiarios`
```sql
-- Tabla pivot para asignación selectiva.
-- Permite implementar "seleccionar todos y excluir manualmente".
CREATE TABLE jornada_beneficiarios (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jornada_id UUID NOT NULL REFERENCES jornadas(id),
  user_id    UUID NOT NULL REFERENCES users(id),
  UNIQUE (jornada_id, user_id)
);
-- Sin updated_at: solo inserción y eliminación, nunca actualización.
```

#### `kits`
```sql
CREATE TABLE kits (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jornada_id       UUID NOT NULL REFERENCES jornadas(id),
  name             TEXT NOT NULL,
  price            NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  has_complement   BOOLEAN NOT NULL DEFAULT false,
  complement_name  TEXT,
  complement_price NUMERIC(10,2) CHECK (complement_price >= 0),
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER kits_updated_at
  BEFORE UPDATE ON kits
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

#### `additional_products`
```sql
-- stock_reserved fue eliminado intencionalmente.
-- Razón: tener stock_reserved aquí Y una tabla stock_reservations son dos fuentes
-- de verdad para el mismo dato. Dos fuentes garantizan inconsistencias eventualmente.
-- El stock disponible se calcula siempre en tiempo real desde stock_reservations.
CREATE TABLE additional_products (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jornada_id       UUID NOT NULL REFERENCES jornadas(id),
  name             TEXT NOT NULL,
  image_url        TEXT,
  price            NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  stock_total      INT NOT NULL CHECK (stock_total >= 0),
  max_per_user     INT NOT NULL DEFAULT 1 CHECK (max_per_user >= 1),
  is_flash         BOOLEAN NOT NULL DEFAULT false,
  flash_expires_at TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER additional_products_updated_at
  BEFORE UPDATE ON additional_products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

#### `orders`
```sql
-- Pedidos confirmados son inmutables para el beneficiario.
-- Solo el ADMINISTRADOR puede cambiar payment_status.
-- is_flash_order = true para ofertas relámpago: son pedidos separados,
-- no modifican el pedido original (RN-25).
CREATE TABLE orders (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jornada_id          UUID NOT NULL REFERENCES jornadas(id),
  user_id             UUID NOT NULL REFERENCES users(id),
  kit_id              UUID NOT NULL REFERENCES kits(id),
  includes_complement BOOLEAN NOT NULL DEFAULT false,
  total_amount        NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
  payment_status      payment_status NOT NULL DEFAULT 'PENDIENTE',
  payment_method      payment_method,
  voucher_url         TEXT,
  is_flash_order      BOOLEAN NOT NULL DEFAULT false,
  confirmed_at        TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now(),
  -- Máximo 1 pedido normal y 1 pedido relámpago por beneficiario por jornada
  UNIQUE (jornada_id, user_id, is_flash_order)
);

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**Regla crítica sobre `total_amount`**: se calcula y congela una sola vez al confirmar.
Nunca se recalcula después de `confirmed_at`. La fuente de verdad del desglose es
`order_items`. `total_amount` es un caché de solo lectura para reportes rápidos.

#### `order_items`
```sql
-- unit_price guarda el precio histórico congelado al momento de confirmar.
-- Si el precio de un producto cambia en el futuro, los pedidos históricos no se ven afectados.
-- Razón de negocio: kits.price y additional_products.price pueden cambiar entre jornadas.
CREATE TABLE order_items (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id   UUID NOT NULL REFERENCES orders(id),
  product_id UUID NOT NULL REFERENCES additional_products(id),
  quantity   INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);
-- Sin updated_at: order_items son inmutables una vez creados.
```

#### `stock_reservations`
```sql
-- Controla la sesión de compra de 10 minutos.
-- Al seleccionar un adicional: INSERT con expires_at = now() + interval '10 minutes'.
-- Al confirmar pedido: UPDATE released = true para liberar la reserva.
-- Si no confirma: pg_cron libera la reserva automáticamente cada minuto.
CREATE TABLE stock_reservations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES additional_products(id),
  user_id    UUID NOT NULL REFERENCES users(id),
  quantity   INT NOT NULL CHECK (quantity > 0),
  expires_at TIMESTAMPTZ NOT NULL,
  released   BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER stock_reservations_updated_at
  BEFORE UPDATE ON stock_reservations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

#### `fcm_tokens`
```sql
-- Un token FCM activo por usuario. Se sobreescribe al cambiar de dispositivo.
CREATE TABLE fcm_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  token      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id)
);

CREATE TRIGGER fcm_tokens_updated_at
  BEFORE UPDATE ON fcm_tokens
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

---

### Cálculo de stock disponible — Única fuente de verdad

```sql
-- Usar siempre esta query. Nunca confiar en campos cacheados.
SELECT
  ap.stock_total - COALESCE((
    SELECT SUM(sr.quantity)
    FROM stock_reservations sr
    WHERE sr.product_id = ap.id
      AND sr.released = false
      AND sr.expires_at > now()
  ), 0) AS stock_disponible
FROM additional_products ap
WHERE ap.id = $1;
```

### Liberación automática de reservas — pg_cron

Habilitar en: Supabase Dashboard → Database → Extensions → pg_cron

```sql
SELECT cron.schedule(
  'liberar-reservas-vencidas',
  '* * * * *',
  $$
    UPDATE stock_reservations
    SET released = true, updated_at = now()
    WHERE released = false
      AND expires_at < now();
  $$
);
```

---

## 6. Seguridad

### Principio base

El `anon key` de Supabase está expuesto en el cliente Flutter y es extraíble.
Sin RLS, cualquiera puede leer y escribir en toda la base de datos con ese key.
**RLS debe estar activo en todas las tablas desde la primera migración.**

La validación de permisos ocurre en dos capas:
1. UI: feedback inmediato al usuario
2. RLS en Supabase: integridad real, no bypasseable desde el cliente

### Helper functions — Extraer datos del JWT

```sql
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS user_role AS $$
  SELECT (auth.jwt() -> 'user_metadata' ->> 'role')::user_role;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION auth.user_cedula()
RETURNS TEXT AS $$
  SELECT (auth.jwt() -> 'user_metadata' ->> 'cedula')::TEXT;
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

El rol siempre se lee desde el JWT del servidor. Nunca desde un parámetro
enviado por el cliente.

### Políticas RLS por tabla

#### `users`
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select" ON users FOR SELECT USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
  OR cedula = auth.user_cedula()
);

CREATE POLICY "users_insert" ON users FOR INSERT WITH CHECK (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
);

-- Solo el admin puede modificar usuarios (incluyendo is_active).
-- El asistente puede editar full_name y phone, validar en repository layer.
CREATE POLICY "users_update" ON users FOR UPDATE USING (
  auth.user_role() = 'ADMINISTRADOR'
);

-- Sin DELETE: soft delete con is_active = false. Nunca DELETE físico.
```

#### `jornadas`
```sql
ALTER TABLE jornadas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "jornadas_admin_asistente" ON jornadas FOR ALL USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
);

CREATE POLICY "jornadas_beneficiario_select" ON jornadas FOR SELECT USING (
  auth.user_role() = 'BENEFICIARIO'
  AND status = 'ACTIVA'
  AND id IN (
    SELECT jornada_id FROM jornada_beneficiarios
    WHERE user_id = auth.uid()
  )
);
```

#### `orders`
```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "orders_select" ON orders FOR SELECT USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
  OR user_id = auth.uid()
);

CREATE POLICY "orders_insert" ON orders FOR INSERT WITH CHECK (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
  OR user_id = auth.uid()
);

-- Solo el admin cambia payment_status. Pedidos inmutables para beneficiarios.
CREATE POLICY "orders_update" ON orders FOR UPDATE USING (
  auth.user_role() = 'ADMINISTRADOR'
);

-- Sin DELETE: los pedidos nunca se eliminan.
```

#### `stock_reservations`
```sql
ALTER TABLE stock_reservations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reservations_owner" ON stock_reservations FOR ALL USING (
  user_id = auth.uid()
);
```

#### `additional_products`
```sql
ALTER TABLE additional_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "products_admin_asistente" ON additional_products FOR ALL USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
);

CREATE POLICY "products_beneficiario_select" ON additional_products FOR SELECT USING (
  auth.user_role() = 'BENEFICIARIO'
  AND jornada_id IN (
    SELECT jb.jornada_id FROM jornada_beneficiarios jb
    JOIN jornadas j ON j.id = jb.jornada_id
    WHERE jb.user_id = auth.uid() AND j.status = 'ACTIVA'
  )
);
```

#### `kits`
```sql
ALTER TABLE kits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kits_admin_asistente" ON kits FOR ALL USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
);

CREATE POLICY "kits_beneficiario_select" ON kits FOR SELECT USING (
  auth.user_role() = 'BENEFICIARIO'
  AND jornada_id IN (
    SELECT jb.jornada_id FROM jornada_beneficiarios jb
    JOIN jornadas j ON j.id = jb.jornada_id
    WHERE jb.user_id = auth.uid() AND j.status = 'ACTIVA'
  )
);
```

#### `order_items`
```sql
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "order_items_select" ON order_items FOR SELECT USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
  OR order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
);

CREATE POLICY "order_items_insert" ON order_items FOR INSERT WITH CHECK (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
  OR order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
);
-- Sin UPDATE ni DELETE: order_items son inmutables.
```

#### `jornada_beneficiarios`
```sql
ALTER TABLE jornada_beneficiarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "jornada_beneficiarios_admin" ON jornada_beneficiarios FOR ALL USING (
  auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
);
```

#### `fcm_tokens`
```sql
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fcm_tokens_owner" ON fcm_tokens FOR ALL USING (
  user_id = auth.uid()
);
```

### Supabase Storage — Bucket `vouchers`

```sql
-- Bucket privado (public = false)
INSERT INTO storage.buckets (id, name, public)
VALUES ('vouchers', 'vouchers', false);

-- Solo admin y asistente leen comprobantes
CREATE POLICY "vouchers_read" ON storage.objects FOR SELECT USING (
  bucket_id = 'vouchers'
  AND auth.user_role() IN ('ADMINISTRADOR', 'ASISTENTE')
);

-- El beneficiario sube solo en su propia carpeta: vouchers/{user_id}/
CREATE POLICY "vouchers_insert" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'vouchers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Compresión de imágenes — Obligatoria antes de cualquier upload

```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';

// En PagosRepository, antes de subir a Storage:
final compressed = await FlutterImageCompress.compressWithFile(
  file.path,
  quality: 75,
  minWidth: 1024,
  minHeight: 1024,
);
// Objetivo: < 200 KB por comprobante de pago
```

### JWT y sesiones

- Expiración JWT: 3600 segundos (1 hora)
- Refresh token: habilitado en Supabase Auth
- Email de auth: `{cedula}@mercados.app` — interno, nunca visible al usuario
- Contraseña inicial beneficiario: últimos 4 dígitos de cédula — lógica en `AuthRepository`
- Reset de contraseña: solo invocable por ADMINISTRADOR o ASISTENTE, validar rol antes

---

## 7. Roles y Permisos — Matriz Completa

| Acción | ADMINISTRADOR | ASISTENTE | BENEFICIARIO |
|---|---|---|---|
| Crear beneficiarios | ✅ | ✅ | ❌ |
| Editar nombre / teléfono | ✅ | ✅ | ❌ |
| Desactivar beneficiarios | ✅ | ❌ | ❌ |
| Crear / editar jornadas | ✅ | ❌ | ❌ |
| Publicar jornada (BORRADOR → ACTIVA) | ✅ | ❌ | ❌ |
| Cerrar jornadas | ✅ | ❌ | ❌ |
| Ver jornadas activas asignadas | ✅ | ✅ | ✅ solo las suyas |
| Registrar pedido propio | ✅ | ✅ | ✅ |
| Registrar pedido en nombre de otro | ✅ | ✅ | ❌ |
| Ver pedidos de todos | ✅ | ✅ | ❌ |
| Aprobar pago Nequi | ✅ | ❌ | ❌ |
| Marcar pago efectivo | ✅ | ✅ | ❌ |
| Ver consolidados | ✅ | ✅ | ❌ |
| Exportar consolidados | ✅ | ✅ | ❌ |
| Publicar oferta relámpago | ✅ | ❌ | ❌ |
| Resetear contraseña de otro | ✅ | ✅ | ❌ |
| Cambiar contraseña propia | ✅ | ✅ | ✅ |
| Configurar modalidad de pago | ✅ | ❌ | ❌ |
| Configurar kits y adicionales | ✅ | ❌ | ❌ |

---

## 8. Reglas de Negocio — Implementación Técnica

Cada regla se refuerza en dos capas: UI (feedback inmediato) y base de datos
(integridad real). Nunca solo en la UI.

| ID | Regla | Enforcement |
|---|---|---|
| RN-01 | Solo admin desactiva beneficiarios | RLS UPDATE policy en `users` |
| RN-02 | Cédula no editable tras creación | Sin UPDATE policy sobre `cedula` para ningún rol |
| RN-03 | Historial persiste al desactivar | Soft delete `is_active = false`, nunca DELETE físico |
| RN-04 | Pedido de desactivado permanece en consolidado | `orders` no se toca al cambiar `is_active` |
| RN-05 | 1 solo ADMINISTRADOR por organización | UNIQUE INDEX parcial en `users` |
| RN-07 | Beneficiario desactivado no puede autenticarse | Verificar `is_active` en `AuthRepository` al login |
| RN-09 | Kit obligatorio en pedido | NOT NULL en `orders.kit_id` + validación UI |
| RN-10 | Máximo 1 kit por beneficiario por jornada | UNIQUE `(jornada_id, user_id, is_flash_order)` en `orders` |
| RN-14 | Límite de unidades por adicional | Validar contra `additional_products.max_per_user` antes de reservar |
| RN-15 | Precio fijo por jornada una vez publicado | `order_items.unit_price` congela el precio al confirmar |
| RN-16 | Reserva de stock al seleccionar, no al confirmar | INSERT en `stock_reservations` en el momento de selección |
| RN-17 | Sesión de 10 minutos también en ofertas relámpago | `expires_at = now() + interval '10 minutes'` siempre |
| RN-19 | Jornada CERRADA no puede reabrirse | Validar transición en `JornadasRepository` antes de UPDATE |
| RN-21 | Transición unidireccional BORRADOR → ACTIVA → CERRADA | Validar en repository, rechazar cualquier otra transición |
| RN-22 | Beneficiario con pedido no puede generar otro | UNIQUE `(jornada_id, user_id, is_flash_order)` en `orders` |
| RN-23 | Sin cancelación ni edición por beneficiario | Sin UPDATE policy para BENEFICIARIO en `orders` |
| RN-25 | Oferta relámpago es pedido separado | `is_flash_order = true` crea fila nueva, no modifica la existente |
| RN-26 | No entregar a beneficiario con pago PENDIENTE | Validar `payment_status` en pantalla de listado de entrega |

---

## 9. Flujo de Pedido — Paso a Paso

```
1. Beneficiario abre la jornada activa que tiene asignada.

2. Selecciona un kit (obligatorio para continuar).

3. Decide si agrega el complemento opcional (si el kit lo tiene disponible).

4. Explora adicionales disponibles:
   → Al seleccionar cada uno:
       INSERT en stock_reservations con expires_at = now() + interval '10 minutes'
   → Timer visible en UI con cuenta regresiva desde el primer adicional seleccionado.

5. Confirma el pedido:
   → Calcular total_amount:
       kit.price
       + complement_price (si includes_complement = true)
       + SUM(order_items.quantity * unit_price)
   → INSERT en orders (total_amount congelado)
   → INSERT en order_items (unit_price congelado desde additional_products.price actual)
   → UPDATE stock_reservations SET released = true (liberar reservas del usuario)
   → Notificar al ADMINISTRADOR vía FCM

6. Si el timer de 10 minutos vence sin confirmar:
   → pg_cron libera reservas automáticamente (released = true)
   → Stock vuelve a estar disponible para otros usuarios
   → UI muestra mensaje de sesión expirada
   → Usuario puede iniciar una nueva sesión de selección
```

---

## 10. Flujo de Pagos

### Modalidad 1 — Solo efectivo
```
Día de entrega:
  Admin o asistente verifica pago presencialmente
  → UPDATE orders SET payment_status = 'PAGADO', payment_method = 'efectivo'
```

### Modalidad 2 — Híbrido (efectivo + Nequi manual)
```
Al confirmar pedido, beneficiario elige:

  Si elige 'nequi':
    → Sube foto del comprobante
    → Comprimir en cliente a < 200 KB (flutter_image_compress)
    → Upload a: storage/vouchers/{user_id}/{order_id}.jpg
    → UPDATE orders SET voucher_url = '{url}', payment_method = 'nequi'
    → Notificación FCM al ADMINISTRADOR
    → Admin aprueba: UPDATE orders SET payment_status = 'PAGADO'
    → Notificación FCM al beneficiario confirmando pago

  Si elige 'efectivo':
    → Se valida presencialmente el día de entrega
    → Mismo flujo que Modalidad 1
```

### Modalidad 3 — Nequi API (arquitectura preparada, no activa)
```
Condición: la organización debe tener NIT y cuenta bancaria formal.
Costo por transacción: 2.65% + IVA.
No implementar en el prototipo. Solo dejar la arquitectura preparada.
```

---

## 11. Notificaciones Push — FCM

FCM es solo transporte. Nunca lógica de negocio. La lógica de negocio
vive en Supabase, no en los mensajes push.

| Evento | Receptor | Payload |
|---|---|---|
| Beneficiario confirma pedido | ADMINISTRADOR | Nombre del beneficiario + jornada + total |
| Admin publica oferta relámpago | Todos los beneficiarios de la jornada | Nombre del producto + precio + tiempo disponible |
| Admin aprueba pago Nequi | Beneficiario dueño del pedido | "Tu pago fue confirmado" |
| Admin rechaza pago Nequi | Beneficiario dueño del pedido | Motivo del rechazo |

Los tokens FCM se almacenan en la tabla `fcm_tokens`. Al cambiar de dispositivo,
el token se sobreescribe (UNIQUE por user_id).

---

## 12. Consolidados

### Para el Banco de Alimentos (exportable)
- Solo cantidades totales por producto, sin nombres de beneficiarios
- Ofertas relámpago en sección separada
- Exportable como PDF o texto plano

### Listado interno de entrega (solo en sistema, no se exporta)
- Nombre del beneficiario + kit + adicionales + estado de pago
- Visible para ADMINISTRADOR y ASISTENTE
- Es el documento operativo principal el día de la jornada

---

## 13. Convenciones de Código

### Clase base de errores

```dart
// core/errors/app_exception.dart
class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class StockException extends AppException {
  const StockException(super.message, {super.code});
}

class JornadaException extends AppException {
  const JornadaException(super.message, {super.code});
}
```

### Patrón de repository

```dart
class PedidosRepository {
  final SupabaseClient _client;
  PedidosRepository(this._client);

  Future<Order> confirmarPedido({
    required String jornadaId,
    required String kitId,
    required bool includesComplement,
    required List<OrderItemInput> items,
  }) async {
    try {
      // 1. Calcular total_amount
      // 2. INSERT en orders
      // 3. INSERT en order_items con unit_price congelado
      // 4. UPDATE stock_reservations SET released = true
      // 5. Retornar Order
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      throw AppException('Error inesperado al confirmar pedido');
    }
  }
}
```

### Reglas generales de código

- Nunca llamar a Supabase desde widgets o providers. Solo desde repositories.
- Nunca almacenar el rol del usuario en SharedPreferences como fuente de verdad.
  Siempre leerlo desde el JWT.
- Nunca hardcodear IDs de organizaciones, jornadas ni usuarios.
- Toda pantalla con datos remotos muestra tres estados: carga, error, y datos vacíos.
- El timer de 10 minutos se muestra visualmente desde la primera selección de adicional.
- Los errores de Supabase/PostgreSQL nunca se exponen crudos a la UI. Siempre
  pasar por `AppException` con mensaje legible para el usuario.

---

## 14. Dependencias Flutter — Lista Aprobada

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.x.x
  flutter_riverpod: ^2.x.x
  riverpod_annotation: ^2.x.x
  go_router: ^14.x.x
  firebase_core: ^3.x.x
  firebase_messaging: ^15.x.x
  flutter_image_compress: ^2.x.x
  intl: ^0.19.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.x.x
  build_runner: ^2.x.x
  flutter_lints: ^4.x.x
```

No agregar dependencias fuera de esta lista sin verificar primero si alguna
existente ya resuelve el problema.

---

## 15. Preguntas Abiertas — Pendientes antes del despliegue

| ID | Pregunta | Impacto |
|---|---|---|
| PA-01 | Presupuesto para desarrollo | Define alcance real y tiempos |
| PA-02 | ¿Quién mantiene el sistema en producción? | Define responsabilidades post-lanzamiento |
| PA-03 | Cuenta de desarrollador Google Play ($25 USD) | Bloquea publicación en Play Store |
| PA-04 | Consentimiento de beneficiarios (Ley 1581 Colombia) | Bloquea el despliegue, no el desarrollo |

---

## 16. Lo que NO hacer — Lista Explícita para el Agente

- No crear tablas sin RLS activo desde la primera migración
- No usar strings libres donde hay ENUMs definidos
- No hacer DELETE físico de usuarios, pedidos ni organizaciones
- No calcular stock disponible con campos cacheados — siempre desde `stock_reservations`
- No almacenar el rol del usuario en estado local como fuente de verdad
- No exponer errores crudos de PostgreSQL o Supabase a la UI
- No subir imágenes a Storage sin comprimir primero con `flutter_image_compress`
- No permitir transiciones de estado de jornada distintas a BORRADOR → ACTIVA → CERRADA
- No modificar `orders.total_amount` después de `confirmed_at`
- No modificar `order_items.unit_price` después de la inserción inicial
- No agregar dependencias fuera de la lista aprobada sin justificación explícita
- No hacer llamadas a Supabase desde widgets o providers — exclusivamente desde repositories
- No intentar crear más de un ADMINISTRADOR por organización
- No usar `stock_reserved` como fuente de verdad para disponibilidad de stock
