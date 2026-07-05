with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;

package body Codegen is

   function Detect_Root return String is
      package Env renames Ada.Environment_Variables;
   begin
      if Env.Exists ("OPENDAQ_ADA_ROOT") then
         return Env.Value ("OPENDAQ_ADA_ROOT");
      end if;
      declare
         use Ada.Directories;
         Exe : constant String := Full_Name (Ada.Command_Line.Command_Name);
      begin
         --  <root>/tools/opendaq_codegen/bin/opendaq_codegen
         return Containing_Directory
                  (Containing_Directory
                     (Containing_Directory (Containing_Directory (Exe))));
      end;
   end Detect_Root;

   function Defaults return Options is
      Root : constant String := Detect_Root;
   begin
      return
        (Root        => +Root,
         Headers_Dir => +(Root & "/vendor/copendaq/include"),
         Model_Dir   => +(Root & "/model"),
         Symbols     => +(Root & "/vendor/copendaq/symbols.txt"),
         Low_Out     => +(Root & "/opendaq_bindings/src/gen"),
         High_Out    => +(Root & "/opendaq/src/gen"),
         Check       => False,
         Verbose     => False);
   end Defaults;

end Codegen;
