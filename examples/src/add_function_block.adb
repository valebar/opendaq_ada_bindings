with Ada.Command_Line;
with Ada.Text_IO;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;
with Daq.Lists;
with Daq.Multi_Readers_F64;

with Example_Support; use Example_Support;

--  Connect the reference device, tune a channel (found by component path),
--  add the Statistics function block, wire the channel signal into its
--  input port, and multi-read the computed avg/rms signals in lockstep.
procedure Add_Function_Block is
   use Ada.Text_IO;

   package M64 renames Daq.Multi_Readers_F64;

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);

begin
   Put_Line ("discovering devices...");
   declare
      Dev : constant Device'Class := Connect_By_Prefix (Inst, "daqref");
   begin
      if Dev.Is_Null then
         Put_Line ("add_function_block: FAIL - no daqref device available");
         Ada.Command_Line.Set_Exit_Status (1);
         return;
      end if;

      declare
         --  Find the channel by component path, then cast.
         Chan : constant Channel'Class :=
           As_Channel (Dev.Find_Component ("IO/AI/RefCh0"));

         Sig : constant Signal'Class :=
           As_Signal (Chan.Get_Signals (No_Filter).Element (0));

         Stats : constant Function_Block'Class :=
           Dev.Add_Function_Block ("RefFBModuleStatistics", No_Config);
      begin
         Put_Line ("connected:  " & Dev.Get_Name);

         Chan.Set_Property_Value ("Amplitude", To_Daq (5.0));
         Chan.Set_Property_Value ("DC", To_Daq (1.0));
         Put_Line ("channel:    " & Chan.Get_Name
                   & "  signal: " & Sig.Get_Name);

         Stats.Set_Property_Value ("BlockSize", To_Daq (100));
         Put_Line ("fb:         " & Stats.Get_Name & "  (BlockSize"
                   & As_Integer (Stats.Get_Property_Value ("BlockSize"))'
                       Image & ")");

         --  Wire the channel signal into the FB's first input port.
         As_Input_Port (Stats.Get_Input_Ports (No_Filter).Element (0))
           .Connect (Sig);

         --  Fish avg / rms out of the FB's output signals.
         declare
            Avg, Rms : Daq.Object;
         begin
            for S of Stats.Get_Signals (No_Filter) loop
               declare
                  Name : constant String := As_Signal (S).Get_Name;
               begin
                  if Name = "avg" then
                     Avg := Daq.Object (S);
                  elsif Name = "rms" then
                     Rms := Daq.Object (S);
                  end if;
               end;
            end loop;

            if Avg.Is_Null or else Rms.Is_Null then
               Put_Line ("add_function_block: FAIL - avg/rms not found");
               Ada.Command_Line.Set_Exit_Status (1);
               return;
            end if;

            --  Multi-read avg and rms in lockstep via a MultiReader.
            declare
               Sigs : constant Daq.Lists.List := Daq.Lists.Create;
            begin
               Sigs.Append (Avg);
               Sigs.Append (Rms);
               declare
                  Reader : constant M64.Reader := M64.Create (Sigs);
                  Vals   : M64.Sample_Matrix (0 .. 1, 0 .. 15);
                  Ticks  : M64.Domain_Matrix (0 .. 1, 0 .. 15);
                  N      : Natural;
                  Total  : Natural := 0;
               begin
                  --  BlockSize 100 at the ref device's 1 kHz means ~10
                  --  statistics samples per second; poll for a few seconds.
                  for Try in 1 .. 50 loop
                     N := 16;
                     M64.Read_With_Domain (Reader, Vals, Ticks, N,
                                           Timeout_Ms => 200);
                     for I in 0 .. N - 1 loop
                        Put_Line ("  t=" & Ticks (0, I)'Image
                                  & "  avg=" & Vals (0, I)'Image
                                  & "  rms=" & Vals (1, I)'Image);
                     end loop;
                     Total := Total + N;
                     exit when Total > 0;
                  end loop;

                  if Total > 0 then
                     Put_Line ("add_function_block: OK (" & Total'Image
                               & " aligned avg/rms samples)");
                  else
                     Put_Line ("add_function_block: FAIL - no samples");
                     Ada.Command_Line.Set_Exit_Status (1);
                  end if;
               end;
            end;
         end;
      end;
   end;
end Add_Function_Block;
