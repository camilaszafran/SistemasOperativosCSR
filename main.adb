with Ada.Text_IO;
with Ada.Numerics.Float_Random;
use Ada.Text_IO;
use Ada.Numerics.Float_Random;

procedure Main is

   -- Acá definimos los límites del problema (cuántas vacas y capacidades)
   NUM_VACAS : constant Integer := 100;
   CAPACIDAD_ORDEÑE : constant Integer := 15;
   CAPACIDAD_VACUNAS : constant Integer := 5;
   CAPACIDAD_CAMION : constant Integer := 50;

   -- Generador de números aleatorios (para simular los tiempos variables)
   Gen : Generator;

  -- Recurso compartido sala_ordeñe
   protected Sala_Ordeñe is
      entry Entrar(Id : Integer);
      procedure Salir(Id : Integer);
   private
      En_Sala : Integer := 0;      -- Contador de vacas actualmente ordeñándose
   end Sala_Ordeñe;

   protected body Sala_Ordeñe is
      entry Entrar(Id : Integer) when En_Sala < CAPACIDAD_ORDEÑE is
      begin
         En_Sala := En_Sala + 1;
         Put_Line("La vaca " & Integer'Image(Id) & " esta entrando al area de ordenie");
      end Entrar;

      procedure Salir(Id : Integer) is
      begin
         En_Sala := En_Sala - 1;
         Put_Line("La vaca " & Integer'Image(Id) & " esta saliendo del area de ordenie");
      end Salir;
   end Sala_Ordeñe;


  -- Recurso compartido Pasillo
   protected Pasillo is
      entry Entrar(Id : Integer);
      procedure Salir(Id : Integer);
   private
      Ocupado : Boolean := False;
   end Pasillo;

   protected body Pasillo is
      entry Entrar(Id : Integer) when not Ocupado is
      begin
         Ocupado := True;
         Put_Line("La vaca " & Integer'Image(Id) & " esta entrando al pasillo de vacunacion");
      end Entrar;

      procedure Salir(Id : Integer) is
      begin
         Ocupado := False;
         Put_Line("La vaca " & Integer'Image(Id) & " salio del pasillo de vacunacion");
      end Salir;
   end Pasillo;


   -- Recurso compartido Area_Vacunacion
   protected Area_Vacunacion is
      entry Entrar(Id : Integer);
      procedure Salir(Id : Integer);
   private
      En_Area : Integer := 0;
   end Area_Vacunacion;

   protected body Area_Vacunacion is
      entry Entrar(Id : Integer) when En_Area < CAPACIDAD_VACUNAS is
      begin
         En_Area := En_Area + 1;
         Put_Line("La vaca " & Integer'Image(Id) & " esta entrando al area de vacunacion");
      end Entrar;

      procedure Salir(Id : Integer) is
      begin
         En_Area := En_Area - 1;
         Put_Line("La vaca " & Integer'Image(Id) & " esta saliendo del area de vacunacion");
      end Salir;
   end Area_Vacunacion;


   -- Recurso compartido Camiones
   protected Camiones is
      procedure Subir(Id : Integer);
   private
      Cant1, Cant2 : Integer := 0;
   end Camiones;

   protected body Camiones is
      procedure Subir(Id : Integer) is
      begin
         if Cant1 < CAPACIDAD_CAMION then
            Cant1 := Cant1 + 1;
            Put_Line("La vaca " & Integer'Image(Id) & " esta entrando al Camion 1");
         elsif Cant2 < CAPACIDAD_CAMION then
            Cant2 := Cant2 + 1;
            Put_Line("La vaca " & Integer'Image(Id) & " esta entrando al Camion 2");
         end if;

         if Cant1 = CAPACIDAD_CAMION and Cant2 = CAPACIDAD_CAMION then
            Put_Line("Ambos camiones están llenos. Fin de la jornada.");
         end if;
      end Subir;
   end Camiones;


  -- La vaca en si con su Id
   task type Vaca(Id : Integer);

   task body Vaca is
      Tiempo : Duration;
   begin
      -- ORDEÑE
      Sala_Ordeñe.Entrar(Id);
      Tiempo := Duration(Random(Gen) * 3.0); -- demora aleatoria (0 a 3 seg)
      delay Tiempo;
      Sala_Ordeñe.Salir(Id);

      -- VACUNACIÓN
      Pasillo.Entrar(Id);
      Area_Vacunacion.Entrar(Id);
      Tiempo := Duration(Random(Gen) * 2.0); -- demora aleatoria (0 a 2 seg)
      delay Tiempo;
      Area_Vacunacion.Salir(Id);
      Pasillo.Salir(Id);

      -- SUBIR AL CAMIÓN
      Camiones.Subir(Id);
   end Vaca;


begin
   Reset(Gen);
   Put_Line("Iniciando simulacion del tambo...");

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
