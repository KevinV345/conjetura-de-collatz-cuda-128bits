# Collatz128-GPU

Búsqueda masivamente paralela de posibles contraejemplos para la Conjetura de Collatz utilizando CUDA y enteros de 128 bits.

El programa analiza números impares de forma continua, registrando aquellos que presentan comportamientos inusuales, como secuencias extremadamente largas o valores cercanos al límite de representación de 128 bits.

## Características

* CUDA para procesamiento paralelo.
* Implementación propia de enteros de 128 bits.
* Reanudación automática mediante archivo de estado.
* Registro de casos potencialmente interesantes.
* Exploración continua del espacio numérico de 128 bits.

## Escala del problema

Tiempo estimado para recorrer todo el espacio de búsqueda:

* RTX 3050 Laptop: ~10.680.176.281.371.302.195.613 años.
* El Capitan: ~1.946.720.650.933.117.444 años.

En otras palabras: probablemente terminará después que el universo.

## Archivos

* `estado.txt` → último número procesado.
* `interesantes.txt` → números que merecen análisis adicional.

## Nota

No pretende demostrar la conjetura. Solo explorar cantidades absurdamente grandes de números porque, técnicamente, alguien tiene que hacerlo.
