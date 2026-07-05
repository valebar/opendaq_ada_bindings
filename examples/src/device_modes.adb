with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with Copendaq.Types; use Copendaq.Types;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;

with Example_Support; use Example_Support;

--  Device operation modes and device locking. Prefers the Simulator
--  device; falls back to the local reference device.
procedure Device_Modes is
   use Ada.Text_IO;

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);

   function Pick_Device return Device'Class is
      Sim : constant Device'Class :=
        Connect_By_Prefix (Inst, "daq.simulator");
   begin
      if not Sim.Is_Null then
         return Sim;
      end if;
      return Connect_By_Prefix (Inst, "daqref");
   end Pick_Device;

   Dev : constant Device'Class := Pick_Device;

   function Mode_Image (M : daqOperationModeType) return String is
     (case M is
         when daqOperationModeTypeUnknown       => "Unknown",
         when daqOperationModeTypeIdle          => "Idle",
         when daqOperationModeTypeOperation     => "Operation",
         when daqOperationModeTypeSafeOperation => "SafeOperation");
begin
   if Dev.Is_Null then
      Put_Line ("device_modes: FAIL - no device");
      Ada.Command_Line.Set_Exit_Status (1);
      return;
   end if;
   Put_Line ("connected: " & Dev.Get_Name);

   Put ("available operation modes: ");
   for M of Dev.Get_Available_Operation_Modes loop
      Put (Mode_Image
             (daqOperationModeType'Val (As_Integer (M)))
           & " ");
   end loop;
   New_Line;
   Put_Line ("current mode:  " & Mode_Image (Dev.Get_Operation_Mode));

   Dev.Set_Operation_Mode (daqOperationModeTypeOperation);
   Dev.Lock;
   Put_Line ("after set:     " & Mode_Image (Dev.Get_Operation_Mode));
   Put_Line ("locked:        " & Dev.Is_Locked'Image);

   Dev.Unlock;
   Dev.Set_Operation_Mode (daqOperationModeTypeSafeOperation);
   Put_Line ("locked:        " & Dev.Is_Locked'Image);
   Put_Line ("final mode:    " & Mode_Image (Dev.Get_Operation_Mode));

   Put_Line ("device_modes: OK");
exception
   when E : Opendaq_Error =>
      --  Some devices don't implement modes/locking; report, don't fail.
      Put_Line ("device_modes: SKIP - unsupported by this device ("
                & Ada.Exceptions.Exception_Message (E) & ")");
end Device_Modes;
