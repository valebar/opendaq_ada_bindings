with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;
with Daq.Lists;
with Daq.Stream_Readers_F64;

--  High-level end-to-end example: create an instance, connect the reference
--  device, pick a value signal, and stream Float64 samples out of it.
--
--  Module discovery: $OPENDAQ_MODULE_PATH when set (./daq run sets it),
--  otherwise the repo's vendor/copendaq/lib located relative to this
--  executable — so running examples/bin/quick_start directly also works.
procedure Quick_Start is
   use Ada.Text_IO;

   package F64 renames Daq.Stream_Readers_F64;

   function Default_Module_Path return String is
      use Ada.Directories;
   begin
      if Ada.Environment_Variables.Exists ("OPENDAQ_MODULE_PATH") then
         return "";  --  Daq.Boot picks the env var up itself
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

   --  "Null" arguments: every generated type inherits No_Object from
   --  Daq.Object, so a qualified expression names a typed null.
   No_Filter : constant Search_Filter'Class := Search_Filter'(No_Object);
   No_Config : constant Property_Object'Class := Property_Object'(No_Object);

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);
   Dev  : constant Device'Class :=
     Inst.Add_Device ("daqref://device0", No_Config);

   Value_Signal : Daq.Object;  --  first signal that has a domain signal
begin
   Put_Line ("connected: " & Dev.Get_Name);

   declare
      Signals : constant Daq.Lists.List :=
        Dev.Get_Signals_Recursive (No_Filter);
   begin
      Put_Line ("signals:" & Signals.Count'Image);
      for S of Signals loop
         declare
            Sig : constant Signal'Class := As_Signal (S);
         begin
            Put_Line ("  - " & Sig.Get_Name
                      & (if Sig.Get_Domain_Signal.Is_Null
                         then "  (domain)" else ""));
            if Value_Signal.Is_Null
              and then not Sig.Get_Domain_Signal.Is_Null
            then
               Value_Signal := Daq.Object (S);
            end if;
         end;
      end loop;
   end;

   if Value_Signal.Is_Null then
      Put_Line ("quick_start: FAIL - no value signal found");
      Ada.Command_Line.Set_Exit_Status (1);
      return;
   end if;

   declare
      Sig   : constant Signal'Class := As_Signal (Value_Signal);
      R     : constant F64.Reader := F64.Create (Sig);
      Buf   : F64.Sample_Array (0 .. 255);
      N     : Natural;
      Total : Natural := 0;
      Tries : Natural := 0;
      Last  : Long_Float := 0.0;
   begin
      Put_Line ("reading from: " & Sig.Get_Name);
      while Total = 0 and then Tries < 50 loop
         N := Buf'Length;
         F64.Read (R, Buf, N, Timeout_Ms => 200);
         if N > 0 then
            Last := Buf (N - 1);
         end if;
         Total := Total + N;
         Tries := Tries + 1;
      end loop;

      Put_Line ("read" & Total'Image & " samples in" & Tries'Image
                & " read(s); last value: " & Last'Image);

      if Total > 0 then
         Put_Line ("quick_start: OK");
      else
         Put_Line ("quick_start: FAIL - no samples");
         Ada.Command_Line.Set_Exit_Status (1);
      end if;
   end;
end Quick_Start;
