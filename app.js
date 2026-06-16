const { Worker, isMainThread, parentPort } = require('worker_threads');
const fs = require('fs');
const os = require('os');

const CONFIG = {
    archivoProgreso: './progreso_collatz.json',
    inicioPorDefecto: 2n ** 71n,
    tamanoLotePorWorker: 1000000n,
    guardarCadaXNumeros: 50000000n,
    maxIteraciones: 500000
};

if (isMainThread) {    
    let inicio = CONFIG.inicioPorDefecto;
    if (fs.existsSync(CONFIG.archivoProgreso)) {
        try {
            const data = JSON.parse(fs.readFileSync(CONFIG.archivoProgreso, 'utf-8'));
            inicio = BigInt(data.ultimo_verificado);
            console.log(`Resumiendo búsqueda desde el último punto guardado: ${inicio}`);
        } catch (err) {
            console.error("Error al leer el JSON de progreso. Se usará el valor por defecto.");
        }
    } else {
        console.log(`No se detectó progreso previo. Iniciando desde: ${inicio}`);
    }

    let fronteraContigua = inicio <= 4n ? 5n : inicio;
    let proximoNumeroAsignar = fronteraContigua;
    
    let bloquesCompletados = [];
    let procesadosDesdeUltimoGuardado = 0n;
    let detenerTodo = false;

    const numCPUs = os.cpus().length;
    console.log(`⚙️ Detectados ${numCPUs} hilos de procesamiento. Inicializando entorno distribuido...\n`);
    function guardarProgreso(numeroFrontera) {
        const payload = {
            ultimo_verificado: numeroFrontera.toString(),
            actualizado_en: new Date().toISOString()
        };
        console.log(payload.ultimo_verificado)
        fs.writeFileSync(CONFIG.archivoProgreso, JSON.stringify(payload, null, 4));
    }

    function asignarTrabajo(worker) {
        if (detenerTodo) return;
        const start = proximoNumeroAsignar;
        const end = start + CONFIG.tamanoLotePorWorker;
        proximoNumeroAsignar = end;

        worker.postMessage({ command: 'PROCESAR', start, end });
    }
    for (let i = 0; i < numCPUs; i++) {
        const worker = new Worker(__filename);

        worker.on('message', (msg) => {
            if (detenerTodo) return;

            if (msg.status === 'OK') {
                const { start, end } = msg;
                bloquesCompletados.push({ start, end });
                bloquesCompletados.sort((a, b) => (a.start < b.start ? -1 : 1));
                while (bloquesCompletados.length > 0 && bloquesCompletados[0].start === fronteraContigua) {
                    const bloque = bloquesCompletados.shift();
                    procesadosDesdeUltimoGuardado += (bloque.end - bloque.start);
                    fronteraContigua = bloque.end;
                }

                if (procesadosDesdeUltimoGuardado >= CONFIG.guardarCadaXNumeros) {
                    guardarProgreso(fronteraContigua);
                    procesadosDesdeUltimoGuardado = 0n;
                } else {
                    // console.log(`✓ Frontera verificada continuamente hasta: ${fronteraContigua}`);
                }

                asignarTrabajo(worker);

            } else if (msg.status === 'CONTRAEJEMPLO') {
                detenerTodo = true;
                console.error(`\n¡CONTRAEJEMPLO ENCONTRADO POR UN WORKER`);
                console.error(`Detalles del hallazgo:`, msg.detalles);
                guardarProgreso(fronteraContigua);
                process.exit(1);
            }
        });

        worker.on('error', (err) => {
            console.error(`Error crítico en Worker Hilo:`, err);
        });

        worker.on('exit', (code) => {
            if (code !== 0 && !detenerTodo) {
                console.error(`Un Worker finalizó de forma inesperada (Código ${code})`);
            }
        });

        // Lanzar el lote inicial de este Worker
        asignarTrabajo(worker);
    }

} else {
    parentPort.on('message', (msg) => {
        if (msg.command === 'PROCESAR') {
            const start = BigInt(msg.start);
            const end = BigInt(msg.end);

            const resultado = verificarRango(start, end);

            if (resultado.status === 'OK') {
                parentPort.postMessage({ status: 'OK', start, end });
            } else {
                parentPort.postMessage({ status: 'CONTRAEJEMPLO', detalles: resultado });
            }
        }
    });

    function verificarRango(start, end) {
        for (let i = start; i < end; i++) {
            let actual = i;
            const caminoActual = new Set();
            let iteraciones = 0;

            while (true) {
                if (actual < i) {
                    break;
                }
                if (caminoActual.has(actual)) {
                    return {
                        tipo: 'NUEVO_CICLO_DETECTADO',
                        numeroInicial: i.toString(),
                        puntoColision: actual.toString(),
                        cicloCompleto: mapearCiclo(actual)
                    };
                }

                caminoActual.add(actual);
                if (actual % 2n === 0n) {
                    actual /= 2n;
                } else {
                    actual = 3n * actual + 1n;
                }

                iteraciones++;
                if (iteraciones > CONFIG.maxIteraciones) {
                    return {
                        tipo: 'ESCAPE_AL_INFINITO_POTENCIAL',
                        numeroInicial: i.toString(),
                        iteracionesAlcanzadas: iteraciones
                    };
                }
            }
        }
        return { status: 'OK' };
    }

    function mapearCiclo(nodoInicio) {
        const ciclo = [];
        let actual = nodoInicio;
        do {
            ciclo.push(actual.toString());
            if (actual % 2n === 0n) {
                actual /= 2n;
            } else {
                actual = 3n * actual + 1n;
            }
        } while (actual !== nodoInicio);
        return ciclo;
    }
}