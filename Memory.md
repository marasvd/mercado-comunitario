\# Project Memory — Sistema de Gestión de Mercados Comunitarios



\## Objective

Aplicación móvil para digitalizar la gestión de jornadas de mercado de una fundación,

eliminando coordinación manual (WhatsApp) y asegurando trazabilidad de pedidos, pagos y stock.



\---



\## Core System



\### Arquitectura

\- Frontend: Flutter (Feature-first + Riverpod)

\- Backend: Supabase (PostgreSQL + Auth + Storage + RLS)

\- Notificaciones: FCM (solo transporte)



\### Entidades críticas

\- users (roles: ADMINISTRADOR, ASISTENTE, BENEFICIARIO)

\- jornadas (BORRADOR → ACTIVA → CERRADA)

\- orders (inmutables para beneficiario)

\- order\_items (precio congelado)

\- additional\_products (stock\_total)

\- stock\_reservations (FUENTE DE VERDAD de stock dinámico)



\### Flujo clave

Pedido:

1\. Selección → crea stock\_reservations (10 min)

2\. Confirmación:

&#x20;  - INSERT orders

&#x20;  - INSERT order\_items

&#x20;  - liberar reservas

3\. Expiración:

&#x20;  - pg\_cron libera reservas



\---



\## Key Decisions (NO romper)



\- RLS activo en TODAS las tablas

\- ENUMs obligatorios (no strings libres)

\- stock se calcula SIEMPRE desde stock\_reservations

\- orders.total\_amount es cache, NO se recalcula

\- order\_items.unit\_price es histórico e inmutable

\- jornadas no se pueden reabrir (flujo unidireccional)

\- 1 ADMIN por organización (constraint DB)

\- soft delete en users (is\_active)



\---



\## Security Model



\- Rol siempre desde JWT (no estado local)

\- Validación doble:

&#x20; - UI (UX)

&#x20; - RLS (verdad)

\- anon key es público → DB protegida por RLS, no por cliente



\---



\## Current State



\- Fase: prototipo

\- Plataforma: Android only

\- Backend listo a nivel diseño (no necesariamente implementado completo)

\- Sin pasarela de pagos (manual/híbrido)

\- Arquitectura preparada para escalar (pero aún no validada en producción)



\---



\## Constraints



\- Stack cerrado (no agregar dependencias)

\- Flutter + Supabase obligatorio

\- JWT-based auth (email ficticio)

\- Ley 1581 bloquea despliegue, no desarrollo

\- No iOS por ahora, pero arquitectura debe soportarlo



\---



\## Critical Risks (esto es lo que estás ignorando)



\- Complejidad alta para un prototipo

\- Dependencia fuerte en correcta implementación de RLS

\- Riesgo de bugs en stock (concurrencia)

\- Flujo de reservas (10 min) puede romper UX si no está bien manejado

\- Sobrecarga mental al mantener tantas reglas estrictas



\---



\## Next Actions (orden real)



1\. Implementar flujo completo de pedido end-to-end (sin optimizar)

2\. Validar:

&#x20;  - creación de reserva

&#x20;  - expiración

&#x20;  - confirmación

3\. Implementar autenticación básica con roles

4\. Probar RLS en entorno real (no asumir que funciona)

5\. Implementar UI mínima funcional (no diseño final)

6\. Solo después:

&#x20;  - optimizar

&#x20;  - añadir notificaciones

