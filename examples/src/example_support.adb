with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;

with Daq; use Daq;

package body Example_Support is

   use Daq.API;

   function Default_Module_Path return String is
      use Ada.Directories;
   begin
      if Ada.Environment_Variables.Exists ("OPENDAQ_MODULE_PATH") then
         return "";
      end if;
      declare
         Exe  : constant String :=
           Full_Name (Ada.Command_Line.Command_Name);
         Root : constant String :=            --  <root>/examples/bin/<exe>
           Containing_Directory
             (Containing_Directory (Containing_Directory (Exe)));
         Cand : constant String := Root & "/vendor/copendaq/lib";
      begin
         return (if Exists (Cand) then Cand else "");
      end;
   end Default_Module_Path;

   function No_Filter return Daq.API.Search_Filter'Class is
     (Search_Filter'(No_Object));

   function No_Config return Daq.API.Property_Object'Class is
     (Property_Object'(No_Object));

   function Connect_By_Prefix
     (Inst   : Daq.API.Instance'Class;
      Prefix : String) return Daq.API.Device'Class
   is
      use Ada.Text_IO;
   begin
      for DI of Inst.Get_Available_Devices loop
         declare
            Info : constant Device_Info'Class := As_Device_Info (DI);
            CS   : constant String := Info.Get_Connection_String;
         begin
            Put_Line ("  available: " & Info.Get_Name & "  (" & CS & ")");
            if CS'Length >= Prefix'Length
              and then CS (CS'First .. CS'First + Prefix'Length - 1) =
                       Prefix
            then
               return Inst.Add_Device (CS, No_Config);
            end if;
         end;
      end loop;
      return Device'(No_Object);
   end Connect_By_Prefix;

end Example_Support;
