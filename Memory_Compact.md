\# Memory Compact



Objective:

App Flutter para gestionar jornadas, pedidos y pagos con trazabilidad completa.



System:

Flutter + Riverpod + Supabase (Postgres + RLS).

Stock dinámico basado en stock\_reservations (NO cacheado).



Core Rules:

\- RLS obligatorio

\- 1 pedido por usuario/jornada

\- pedidos inmutables

\- jornadas: BORRADOR → ACTIVA → CERRADA (irreversible)

\- stock se calcula en tiempo real



Flow:

Seleccionar → reserva (10 min) → confirmar → crear order + liberar reservas



State:

Prototipo en desarrollo, arquitectura definida, validación pendiente



Next:

Implementar flujo completo de pedido y probar reservas/expiración

