# Tactical FPS for Android

Prototipo FPS táctico móvil creado con Godot Engine 4.7.2.

## Compilación Android automática

El código fuente está empaquetado en un ZIP codificado en Base64 y dividido en fragmentos dentro de `source/`. El workflow los reconstruye, extrae el proyecto, instala Godot 4.7.2 y sus export templates, importa los recursos, realiza comprobaciones headless y exporta un APK Android ARM64.

Cada ejecución correcta publica:
- Un artefacto descargable llamado `TacticalFPS-Android-ARM64`.
- Una GitHub Release con el APK.

## Firma

El APK usa una clave debug temporal generada durante cada ejecución. Es válida para instalar y probar el juego, pero no es una firma persistente para publicar en Google Play.

## Criterio de validación

El proyecto solo se considera compilado y probado cuando GitHub Actions termina correctamente, completa la comprobación headless y produce el APK. La existencia del workflow por sí sola no demuestra que el juego funcione.
