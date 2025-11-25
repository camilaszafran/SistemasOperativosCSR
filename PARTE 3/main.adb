with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;

procedure Main is

   NUM_VACAS      : constant Integer := 100;
   CAP_ORDENIE    : constant Integer := 15;
   CAP_VACUNACION : constant Integer := 5;
   CAP_CAMION     : constant Integer := 50;

   Gen : Generator;

   task Sala_Ordenie is
      entry Entrar(Id : Integer);
      entry Salir(Id : Integer);
   end Sala_Ordenie;

   task body Sala_Ordenie is
      Cant : Integer := 0;
   begin
      loop
         select
            when Cant < CAP_ORDENIE =>
               accept Entrar(Id : Integer) do
                  Cant := Cant + 1;
                  Put_Line("La vaca" & Integer'Image(Id) &
                           " esta entrando al area de ordenie");
               end Entrar;
               delay Duration(Random(Gen) * 3.0);
         or
            accept Salir(Id : Integer) do
               Cant := Cant - 1;
               Put_Line("La vaca" & Integer'Image(Id) &
                        " esta saliendo del area de ordenie");
            end Salir;
         end select;
      end loop;
   end Sala_Ordenie;


   task Sala_Vacunacion is
      entry Entrar(Id : Integer);
      entry Salir(Id : Integer);
   end Sala_Vacunacion;

   task body Sala_Vacunacion is
      Cant : Integer := 0;
   begin
      loop
         select
            when Cant < CAP_VACUNACION =>
               accept Entrar(Id : Integer) do
                  Cant := Cant + 1;
                  Put_Line("La vaca" & Integer'Image(Id) &
                           " esta entrando al area de vacunacion");
               end Entrar;
               delay Duration(Random(Gen) * 2.0);
         or
            accept Salir(Id : Integer) do
               Cant := Cant - 1;
               Put_Line("La vaca" & Integer'Image(Id) &
                        " esta saliendo del area de vacunacion");
            end Salir;
         end select;
      end loop;
   end Sala_Vacunacion;


   task Pasillo is
      entry Entrar_Entrada(Id : Integer); -- hacia vacunacion
      entry Entrar_Salida(Id : Integer);  -- desde vacunacion
      entry Salir(Id : Integer);
   end Pasillo;

   task body Pasillo is
      Ocupado        : Boolean := False;
      En_Vacunacion : Integer := 0;
   begin
      loop
         select
            -- entrada hacia vacunacion (requiere lugar)
            when (not Ocupado) and (En_Vacunacion < CAP_VACUNACION) =>
               accept Entrar_Entrada(Id : Integer) do
                  Ocupado := True;
                  En_Vacunacion := En_Vacunacion + 1;
                  Put_Line("La vaca" & Integer'Image(Id) &
                           " esta entrando al pasillo de vacunacion");
               end Entrar_Entrada;

         or
            -- entrada desde vacunacion (requiere que haya alguien vacunandose)
            when (not Ocupado) and (En_Vacunacion > 0) =>
               accept Entrar_Salida(Id : Integer) do
                  Ocupado := True;
                  En_Vacunacion := En_Vacunacion - 1;
                  Put_Line("La vaca" & Integer'Image(Id) &
                           " esta entrando al pasillo de salida");
               end Entrar_Salida;

         or
            when Ocupado =>
               accept Salir(Id : Integer) do
                  Ocupado := False;
                  Put_Line("La vaca" & Integer'Image(Id) &
                           " salio del pasillo");
               end Salir;

         end select;
      end loop;
   end Pasillo;

   task Camiones is
      entry Subir(Id : Integer);
   end Camiones;

   task body Camiones is
      C1 : Integer := 0;
      C2 : Integer := 0;
   begin
      loop
         accept Subir(Id : Integer) do
            if C1 < CAP_CAMION then
               C1 := C1 + 1;
               Put_Line("La vaca" & Integer'Image(Id) &
                        " esta entrando al Camion 1");
            elsif C2 < CAP_CAMION then
               C2 := C2 + 1;
               Put_Line("La vaca" & Integer'Image(Id) &
                        " esta entrando al Camion 2");
            end if;

            if C1 = CAP_CAMION and C2 = CAP_CAMION then
               Put_Line("Ambos camiones estan llenos. Fin de la jornada.");
            end if;
         end Subir;
      end loop;
   end Camiones;

   task type Vaca(Id : Integer);

   task body Vaca is
   begin
      -- Ordenie
      Sala_Ordenie.Entrar(Id);
      Sala_Ordenie.Salir(Id);

      -- Pasillo
      Pasillo.Entrar_Entrada(Id);
      Pasillo.Salir(Id);

      -- Vacunacion
      Sala_Vacunacion.Entrar(Id);
      Sala_Vacunacion.Salir(Id);

      -- Pasillo
      Pasillo.Entrar_Salida(Id);
      Pasillo.Salir(Id);

      -- Camion
      Camiones.Subir(Id);
   end Vaca;


begin
   Reset(Gen);
   Put_Line("Iniciando simulacion del tambo...");

   declare
      type Ptr is access Vaca;
      Vacas : array (1 .. NUM_VACAS) of Ptr;
   begin
      for I in Vacas'Range loop
         Vacas(I) := new Vaca(I);
      end loop;
   end;

end Main;
