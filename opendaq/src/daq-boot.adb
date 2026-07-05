with Ada.Environment_Variables;

package body Daq.Boot is

   function Create_Instance
     (Module_Path : String := "") return Daq.API.Instance'Class
   is
      package Env renames Ada.Environment_Variables;

      function Effective_Path return String is
      begin
         if Module_Path /= "" then
            return Module_Path;
         elsif Env.Exists ("OPENDAQ_MODULE_PATH") then
            return Env.Value ("OPENDAQ_MODULE_PATH");
         else
            return "";
         end if;
      end Effective_Path;

      Builder : constant Daq.API.Instance_Builder'Class :=
        Daq.API.Create_Instance_Builder;
   begin
      declare
         Path : constant String := Effective_Path;
      begin
         if Path /= "" then
            Builder.Set_Module_Path (Path);
         end if;
      end;
      return Builder.Build;
   end Create_Instance;

end Daq.Boot;
