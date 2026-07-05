with Ada.Command_Line;
with Ada.Text_IO;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;
with Daq.Functions;
with Daq.Lists;

with Example_Support; use Example_Support;

--  Call an IFunction-valued property. Uses the Simulator device's
--  "Protected.Sum" (a Dewesoft-specific property); when no simulator is
--  reachable the example reports a skip and exits cleanly.
procedure Call_Function is
   use Ada.Text_IO;

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);
   Dev  : constant Device'Class :=
     Connect_By_Prefix (Inst, "daq.simulator");
begin
   if Dev.Is_Null then
      Put_Line ("call_function: SKIP - no simulator device available");
      return;
   end if;
   Put_Line ("connected: " & Dev.Get_Name);

   if not Dev.Has_Property ("Protected.Sum") then
      Put_Line ("call_function: SKIP - device has no Protected.Sum");
      return;
   end if;

   declare
      Sum  : constant Daq.Object := Dev.Get_Property_Value ("Protected.Sum");
      Args : constant Daq.Lists.List := Daq.Lists.Create;
   begin
      Args.Append (To_Daq (1));
      Args.Append (To_Daq (2));
      declare
         Result : constant Daq.Object'Class :=
           Daq.Functions.Call_List (Sum, Args);
         Value  : constant Long_Long_Integer := As_Integer (Result);
      begin
         Put_Line ("Protected.Sum (1, 2) =" & Value'Image);
         if Value = 3 then
            Put_Line ("call_function: OK");
         else
            Put_Line ("call_function: FAIL - expected 3");
            Ada.Command_Line.Set_Exit_Status (1);
         end if;
      end;
   end;
end Call_Function;
