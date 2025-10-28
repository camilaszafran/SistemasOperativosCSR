#include <stdio.h>      // printf(), etc.
#include <stdlib.h>     // rand(), srand()
#include <pthread.h>    // manejo de hilos
#include <semaphore.h>  // manejo de semáforos
#include <unistd.h>     // sleep()
#include <time.h>       // time() para srand()

#define NUM_PASAJEROS 100
#define NUM_OFICINISTAS 5


sem_t mutex;     // Protege variables compartidas (num_lectores, esperando_escritor)
sem_t cartel;    // Controla acceso exclusivo al cartel
sem_t bloqueo;   // Evita que entren nuevos lectores cuando hay escritores esperando

int num_lectores = 0;        // Cantidad de lectores actualmente mirando
int esperando_escritor = 0;  // Cantidad de escritores esperando para modificar

void* pasajero(void* arg) {
    int id = *(int*)arg; // ID del pasajero

    while (1) {
        pthread_testcancel(); // permite terminar el hilo cuando se cancela

        // Esperar si hay escritores esperando
        sem_wait(&bloqueo);
        sem_post(&bloqueo);

        // Proteger acceso a num_lectores
        sem_wait(&mutex);
        num_lectores++;
        if (num_lectores == 1)
            sem_wait(&cartel); // primer lector bloquea el cartel
        sem_post(&mutex);

        // ---- LECTURA ----
        printf("Pasajero %d está mirando el cartel\n", id);
        sleep(rand() % 3 + 1); // entre 1 y 3 segundos
        // ---- FIN LECTURA ----

        // Salida del lector
        sem_wait(&mutex);
        num_lectores--;
        if (num_lectores == 0)
            sem_post(&cartel); // último lector libera el cartel
        sem_post(&mutex);

        sleep(rand() % 3 + 1); // espera antes de volver a mirar
    }

    return NULL;
}

void* oficinista(void* arg) {
    int id = *(int*)arg;
    int cambios = rand() % 8 + 3; // entre 3 y 10 modificaciones

    for (int i = 0; i < cambios; i++) {
        // Indicar que hay un escritor esperando
        sem_wait(&mutex);
        esperando_escritor++;
        if (esperando_escritor == 1)
            sem_wait(&bloqueo); // primer escritor bloquea nuevos lectores
        sem_post(&mutex);

        // Esperar acceso exclusivo al cartel
        sem_wait(&cartel);
        printf("Oficinista %d está modificando el cartel (cambio %d/%d)\n", id, i + 1, cambios);
        sleep(rand() % 5 + 1); // entre 1 y 5 segundos escribiendo
        sem_post(&cartel);

        // Indicar que ya no está esperando
        sem_wait(&mutex);
        esperando_escritor--;
        if (esperando_escritor == 0)
            sem_post(&bloqueo); // si ya no hay escritores esperando, reabre paso a lectores
        sem_post(&mutex);

        sleep(rand() % 5 + 1); // pausa antes del siguiente cambio
    }

    printf("Oficinista %d terminó sus %d cambios.\n", id, cambios);
    return NULL;
}

int main() {
    srand(time(NULL)); // semilla para números aleatorios

    pthread_t pasajeros[NUM_PASAJEROS];
    pthread_t oficinistas[NUM_OFICINISTAS];
    int ids_p[NUM_PASAJEROS];
    int ids_o[NUM_OFICINISTAS];

    // Inicializar semáforos
    sem_init(&mutex, 0, 1);
    sem_init(&cartel, 0, 1);
    sem_init(&bloqueo, 0, 1);

    // Crear hilos de pasajeros
    for (int i = 0; i < NUM_PASAJEROS; i++) {
        ids_p[i] = i + 1;
        pthread_create(&pasajeros[i], NULL, pasajero, &ids_p[i]);
    }

    // Crear hilos de oficinistas
    for (int i = 0; i < NUM_OFICINISTAS; i++) {
        ids_o[i] = i + 1;
        pthread_create(&oficinistas[i], NULL, oficinista, &ids_o[i]);
    }

    // Esperar a que terminen todos los oficinistas
    for (int i = 0; i < NUM_OFICINISTAS; i++)
        pthread_join(oficinistas[i], NULL);

    printf("\n Todos los oficinistas terminaron sus modificaciones.\n");

    // Cancelar todos los pasajeros
    for (int i = 0; i < NUM_PASAJEROS; i++)
        pthread_cancel(pasajeros[i]);

    printf("Todos los pasajeros se retiraron. Fin del programa.\n");

    // Destruir semáforos
    sem_destroy(&mutex);
    sem_destroy(&cartel);
    sem_destroy(&bloqueo);

    return 0;
}