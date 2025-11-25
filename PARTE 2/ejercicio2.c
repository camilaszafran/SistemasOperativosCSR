#include <stdio.h>      
#include <stdlib.h>     
#include <pthread.h>    
#include <semaphore.h>  
#include <unistd.h>     
#include <time.h>       

#define NUM_PASAJEROS 100
#define NUM_OFICINISTAS 5


sem_t mutex;     // Protege variables compartidas 
sem_t cartel;    // Controla acceso exclusivo al cartel
sem_t bloqueo;   // Evita que entren nuevos lectores cuando hay escritores esperando

int num_lectores = 0;        
int esperando_escritor = 0;  

void* pasajero(void* arg) {
    int id = *(int*)arg;

    while (1) {
        pthread_testcancel();

        sem_wait(&bloqueo);
        sem_post(&bloqueo);

        sem_wait(&mutex);
        num_lectores++;
        if (num_lectores == 1)
            sem_wait(&cartel);
        sem_post(&mutex);

        printf("Pasajero %d está mirando el cartel\n", id);
        sleep(rand() % 3 + 1);

        sem_wait(&mutex);
        num_lectores--;
        if (num_lectores == 0)
            sem_post(&cartel);
        sem_post(&mutex);

        sleep(rand() % 3 + 1);
    }

    return NULL;
}

void* oficinista(void* arg) {
    int id = *(int*)arg;
    int cambios = rand() % 8 + 3; 

    for (int i = 0; i < cambios; i++) {
        sem_wait(&mutex);
        esperando_escritor++;
        if (esperando_escritor == 1)
            sem_wait(&bloqueo);
        sem_post(&mutex);

        sem_wait(&cartel);
        printf("Oficinista %d está modificando el cartel (cambio %d/%d)\n", id, i + 1, cambios);
        sleep(rand() % 5 + 1); 
        sem_post(&cartel);

        sem_wait(&mutex);
        esperando_escritor--;
        if (esperando_escritor == 0)
            sem_post(&bloqueo); 
        sem_post(&mutex);

        sleep(rand() % 5 + 1); 
    }

    printf("Oficinista %d terminó sus %d cambios.\n", id, cambios);
    return NULL;
}

int main() {
    srand(time(NULL));

    pthread_t pasajeros[NUM_PASAJEROS];
    pthread_t oficinistas[NUM_OFICINISTAS];
    int ids_p[NUM_PASAJEROS];
    int ids_o[NUM_OFICINISTAS];

    sem_init(&mutex, 0, 1);
    sem_init(&cartel, 0, 1);
    sem_init(&bloqueo, 0, 1);

    for (int i = 0; i < NUM_PASAJEROS; i++) {
        ids_p[i] = i + 1;
        pthread_create(&pasajeros[i], NULL, pasajero, &ids_p[i]);
    }

    for (int i = 0; i < NUM_OFICINISTAS; i++) {
        ids_o[i] = i + 1;
        pthread_create(&oficinistas[i], NULL, oficinista, &ids_o[i]);
    }

    for (int i = 0; i < NUM_OFICINISTAS; i++)
        pthread_join(oficinistas[i], NULL);

    printf("\n Todos los oficinistas terminaron sus modificaciones.\n");

    for (int i = 0; i < NUM_PASAJEROS; i++)
        pthread_cancel(pasajeros[i]);

    printf("Todos los pasajeros se retiraron. Fin del programa.\n");

    sem_destroy(&mutex);
    sem_destroy(&cartel);
    sem_destroy(&bloqueo);

    return 0;
}