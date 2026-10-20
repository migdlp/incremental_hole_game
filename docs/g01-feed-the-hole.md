# G01 — Feed the Hole

Estado: cambio de marca implementado y publicado en `fd3d8f2`. Build `0.6.0+14`.
La aceptación de actualización sobre la APK anterior está **bloqueada por firma**.

## Cambios de marca

- Android: etiqueta de aplicación Feed the Hole.
- Flutter: título, bienvenida y mensaje de error de inicio con el nombre nuevo.
- Web: título, manifiesto instalable y descripción actualizados.
- README, PRD y documentación vigente actualizados. Nueva entrada de changelog;
  entradas anteriores y documentos históricos intactos.
- APK/artefacto futuros: `feed-the-hole-debug.apk` / `feed-the-hole-debug-apk`.

El repositorio sigue siendo `migdlp/incremental_hole_game`; el paquete Android,
`com.migdlp.incremental_hole_game`. No cambian clases internas, paquete Dart,
iconos, gráficos, mecánicas, balance, rutas/archivos de guardado, compras ni
migraciones. Se incrementa solo el build de 13 a 14.

## Comprobaciones y bloqueo de actualización

[Pipeline 39516579282](https://github.com/migdlp/incremental_hole_game/actions/runs/39516579282),
commit `fd3d8f2`: formato, análisis, suite completa y compilación APK correctos.
`aapt` confirma el nombre Feed the Hole y el paquete original en el binario.
`apksigner` confirma una firma válida del APK nuevo, pero su certificado difiere
al compararlo con la última entrega `39458229638` (`4d815d9`, `0.6.0+13`).
Por ello, el workflow no publica el nuevo APK como descarga.

Error confirmado:

```text
La firma difiere de la APK anterior. Se necesita su keystore para actualizar conservando los datos.
```

Conservar el identificador y el almacenamiento es necesario, pero Android también
exige la misma clave de firma para aceptar la actualización. La pipeline anterior
usaba la configuración debug de Gradle y no restauraba un keystore persistente.
Cambiar el nombre no cambia las claves de guardado ni causa esa diferencia de
certificados. Una clave nueva tampoco permite actualizar la aplicación existente.

## Siguiente paso necesario

Localizar el keystore original de la APK instalada, conservarlo en una configuración
persistente de firma y reutilizarlo en CI. Repetir la comparación con la entrega
anterior y después probar la actualización en un teléfono con progreso existente.
No resolver este bloqueo desinstalando la aplicación ni borrando datos. La clave
privada no puede reconstruirse a partir del certificado público de la APK.
