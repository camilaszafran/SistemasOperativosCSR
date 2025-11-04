with Ada.Text_IO;                 -- Librería para imprimir texto en pantalla
with Ada.Numerics.Float_Random;  -- Librería para generar números aleatorios
use Ada.Text_IO;
use Ada.Numerics.Float_Random;

procedure Main is

   --------------------------------------------------------------------
   -- CONSTANTES Y VARIABLES GLOBALES
   --------------------------------------------------------------------
   -- Acá definimos los límites del problema (cuántas vacas y capacidades)
   NUM_VACAS : constant Integer := 100;
   CAPACIDAD_ORDEÑE : constant Integer := 15;
   CAPACIDAD_VACUNAS : constant Integer := 5;
   CAPACIDAD_CAMION : constant Integer := 50;

   -- Generador de números aleatorios (para simular los tiempos variables)
   Gen : Generator;

   --------------------------------------------------------------------
   -- SALA DE ORDEÑE (máximo 15 vacas a la vez)
   --------------------------------------------------------------------
   -- Un "protected object" en Ada es como un recurso compartido protegido,
   -- parecido a un semáforo o monitor. Sirve para controlar el acceso
   -- concurrente de varias tareas (vacas en este caso).
   protected Sala_Ordeñe is
      entry Entrar(Id : Integer);  -- Entrada al área de ordeñe
      procedure Salir(Id : Integer); -- Salida del área de ordeñe
   private
      En_Sala : Integer := 0;      -- Contador de vacas actualmente ordeñándose
   end Sala_Ordeñe;

   protected body Sala_Ordeñe is
      entry Entrar(Id : Integer) when En_Sala < CAPACIDAD_ORDEÑE is
      begin
         En_Sala := En_Sala + 1;
         Put_Line("La vaca " & Integer'Image(Id) & " está entrando al área de ordeñe");
      end Entrar;

      procedure Salir(Id : Integer) is
      begin
         En_Sala := En_Sala - 1;
         Put_Line("La vaca " & Integer'Image(Id) & " está saliendo del área de ordeñe");
      end Salir;
   end Sala_Ordeñe;


   --------------------------------------------------------------------
   -- PASILLO DE VACUNACIÓN (solo una vaca a la vez)
   --------------------------------------------------------------------
   -- El pasillo sirve tanto para entrar como para salir de las mangas.
   -- Por eso sólo puede haber una vaca a la vez usándolo.
   protected Pasillo is
      entry Entrar(Id : Integer);
      procedure Salir(Id : Integer);
   private
      Ocupado : Boolean := False;  -- Indica si el pasillo está siendo usado
   end Pasillo;

   protected body Pasillo is
      entry Entrar(Id : Integer) when not Ocupado is
      begin
         Ocupado := True;
         Put_Line("La vaca " & Integer'Image(Id) & " está entrando al pasillo de vacunación");
      end Entrar;

      procedure Salir(Id : Integer) is
      begin
         Ocupado := False;
         Put_Line("La vaca " & Integer'Image(Id) & " salió del pasillo de vacunación");
      end Salir;
   end Pasillo;


   --------------------------------------------------------------------
   -- ÁREA DE VACUNACIÓN (máximo 5 vacas a la vez)
   --------------------------------------------------------------------
   -- Controla que solo 5 vacas estén siendo vacunadas al mismo tiempo.
   protected Area_Vacunacion is
      entry Entrar(Id : Integer);
      procedure Salir(Id : Integer);
   private
      En_Area : Integer := 0;  -- Cuántas vacas hay vacunándose ahora
   end Area_Vacunacion;

   protected body Area_Vacunacion is
      entry Entrar(Id : Integer) when En_Area < CAPACIDAD_VACUNAS is
      begin
         En_Area := En_Area + 1;
         Put_Line("La vaca " & Integer'Image(Id) & " está entrando al área de vacunación");
      end Entrar;

      procedure Salir(Id : Integer) is
      begin
         En_Area := En_Area - 1;
         Put_Line("La vaca " & Integer'Image(Id) & " está saliendo del área de vacunación");
      end Salir;
   end Area_Vacunacion;


   --------------------------------------------------------------------
   -- CAMIONES (2 camiones de 50 vacas cada uno)
   --------------------------------------------------------------------
   -- Las vacas suben a cualquiera de los dos camiones hasta llenarlos.
   protected Camiones is
      procedure Subir(Id : Integer);
   private
      Cant1, Cant2 : Integer := 0;  -- Cantidad de vacas en cada camión
   end Camiones;

   protected body Camiones is
      procedure Subir(Id : Integer) is
      begin
         if Cant1 < CAPACIDAD_CAMION then
            Cant1 := Cant1 + 1;
            Put_Line("La vaca " & Integer'Image(Id) & " está entrando al Camión 1");
         elsif Cant2 < CAPACIDAD_CAMION then
            Cant2 := Cant2 + 1;
            Put_Line("La vaca " & Integer'Image(Id) & " está entrando al Camión 2");
         end if;

         if Cant1 = CAPACIDAD_CAMION and Cant2 = CAPACIDAD_CAMION then
            Put_Line("Ambos camiones están llenos. Fin de la jornada.");
         end if;
      end Subir;
   end Camiones;


   --------------------------------------------------------------------
   -- DEFINICIÓN DE LA TAREA DE CADA VACA
   --------------------------------------------------------------------
   -- Cada vaca se comporta como una tarea concurrente (thread).
   -- Todas ejecutan el mismo código, pero con distinto Id.
   task type Vaca(Id : Integer);

   task body Vaca is
      Tiempo : Duration;
   begin
      -- 1) ORDEÑE
      Sala_Ordeñe.Entrar(Id);
      Tiempo := Duration(Random(Gen) * 3.0); -- demora aleatoria (0 a 3 seg)
      delay Tiempo;
      Sala_Ordeñe.Salir(Id);

      -- 2) VACUNACIÓN
      Pasillo.Entrar(Id);
      Area_Vacunacion.Entrar(Id);
      Tiempo := Duration(Random(Gen) * 2.0); -- demora aleatoria (0 a 2 seg)
      delay Tiempo;
      Area_Vacunacion.Salir(Id);
      Pasillo.Salir(Id);

      -- 3) SUBIR AL CAMIÓN
      Camiones.Subir(Id);
   end Vaca;


   --------------------------------------------------------------------
   -- CREACIÓN DE TODAS LAS VACAS (100 tareas)
   --------------------------------------------------------------------
begin
   Reset(Gen);
   Put_Line("Iniciando simulación del tambo...");

   -- Creamos las vacas una por una en un bucle
   declare
      -- Creamos un tipo de acceso (puntero) a tareas Vaca
      type Acceso_Vaca is access Vaca;
      Vacas : array (1 .. NUM_VACAS) of Acceso_Vaca;
   begin
      for I in 1 .. NUM_VACAS loop
         -- Por cada número creamos una nueva tarea vaca con su Id
         Vacas(I) := new Vaca(I);
      end loop;

      -- Este bloque mantiene las tareas vivas hasta que terminen
      null;
   end;

end Main;
