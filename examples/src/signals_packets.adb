with Ada.Command_Line;
with Ada.Text_IO;

with Copendaq.Types;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;
with Daq.Packet_Buffers_F64;
with Daq.Stream_Readers_F64;

with Example_Support; use Example_Support;

--  Build data descriptors, create signals programmatically, write samples
--  into packets, send them, and read them back through a stream reader.
procedure Signals_Packets is
   use Ada.Text_IO;

   package F64 renames Daq.Stream_Readers_F64;
   package PB64 renames Daq.Packet_Buffers_F64;

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);
   Ctx  : constant Context'Class := Inst.Get_Context;

   function Make_Domain_Descriptor return Data_Descriptor'Class is
      B : constant Data_Descriptor_Builder'Class :=
        Create_Data_Descriptor_Builder;
   begin
      B.Set_Name ("time");
      B.Set_Sample_Type (Copendaq.Types.daqSampleTypeInt64);
      B.Set_Rule (Create_Linear_Data_Rule (To_Daq (1), To_Daq (0)));
      return B.Build;
   end Make_Domain_Descriptor;

   function Make_Value_Descriptor return Data_Descriptor'Class is
      B : constant Data_Descriptor_Builder'Class :=
        Create_Data_Descriptor_Builder;
   begin
      B.Set_Name ("values");
      B.Set_Sample_Type (Copendaq.Types.daqSampleTypeFloat64);
      return B.Build;
   end Make_Value_Descriptor;

   Domain_Desc : constant Data_Descriptor'Class := Make_Domain_Descriptor;
   Value_Desc  : constant Data_Descriptor'Class := Make_Value_Descriptor;

   Domain_Sig : constant Signal_Config'Class :=
     Create_Signal_With_Descriptor
       (Ctx, Domain_Desc, Component'(No_Object), "time", "");
   Sig : constant Signal_Config'Class :=
     Create_Signal_With_Descriptor
       (Ctx, Value_Desc, Component'(No_Object), "values", "");

   procedure Send_Chunk (Offset : Natural; Samples : PB64.Sample_Array) is
      Domain_Packet : constant Data_Packet'Class :=
        Create_Data_Packet
          (Domain_Desc, Samples'Length,
           To_Daq (Long_Long_Integer (Offset)));
      Packet : constant Data_Packet'Class :=
        Create_Data_Packet_With_Domain
          (Domain_Packet, Value_Desc, Samples'Length,
           To_Daq (Long_Long_Integer (Offset)));
   begin
      PB64.Write (Packet, Samples);
      Sig.Send_Packet (Packet);
   end Send_Chunk;

   Total : Natural := 0;
begin
   Sig.Set_Domain_Signal (Domain_Sig);

   declare
      Reader : constant F64.Reader := F64.Create (Sig);
      Vals   : F64.Sample_Array (0 .. 99);
      Ticks  : F64.Domain_Array (0 .. 99);
      N      : Natural;
   begin
      Send_Chunk (0, (1.1, 2.2, 3.3, 4.4));
      Send_Chunk (4, (5.5, 6.6, 7.7, 8.8));
      Send_Chunk (8, (9.9, 10.1));

      for Try in 1 .. 10 loop
         N := Vals'Length;
         F64.Read_With_Domain (Reader, Vals, Ticks, N, Timeout_Ms => 200);
         for I in 0 .. N - 1 loop
            Put_Line ("  [" & Ticks (I)'Image & "," & Vals (I)'Image
                      & " ]");
         end loop;
         Total := Total + N;
         exit when Total >= 10;
      end loop;
   end;

   Put_Line ("signals_packets:" & Total'Image & " samples round-tripped");
   if Total = 10 then
      Put_Line ("signals_packets: OK");
   else
      Put_Line ("signals_packets: FAIL - expected 10 samples");
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Signals_Packets;
