with System;

with Copendaq;
with Copendaq.Signal;
with Copendaq.Types;

package body Daq.Packet_Buffers is

   use Copendaq;
   use Copendaq.Signal;

   function Self_H
     (Packet : Daq.API.Data_Packet'Class)
      return Copendaq.Types.daqDataPacket is
     (Copendaq.Types.daqDataPacket (Handle (Packet)));

   function Raw_Address
     (Packet : Daq.API.Data_Packet'Class) return daqVoidPtr
   is
      Addr : daqVoidPtr := System.Null_Address;
   begin
      Check (daqDataPacket_getRawData (Self_H (Packet), Addr),
             "daqDataPacket_getRawData");
      return Addr;
   end Raw_Address;

   function Buffer_Bytes
     (Packet : Daq.API.Data_Packet'Class) return Natural
   is
      Size : daqSizeT := 0;
   begin
      Check (daqDataPacket_getRawDataSize (Self_H (Packet), Size),
             "daqDataPacket_getRawDataSize");
      return Natural (Size);
   end Buffer_Bytes;

   procedure Write
     (Packet : Daq.API.Data_Packet'Class;
      Data   : Sample_Array)
   is
      Bytes_Needed : constant Natural :=
        Data'Length * (Sample'Size / 8);
   begin
      if Data'Length = 0 then
         return;
      end if;
      if Bytes_Needed > Buffer_Bytes (Packet) then
         raise Opendaq_Error with
           "Packet_Buffers.Write: packet buffer too small ("
           & Buffer_Bytes (Packet)'Image & " bytes for"
           & Bytes_Needed'Image & ")";
      end if;
      declare
         Target : Sample_Array (0 .. Data'Length - 1)
           with Import, Address => Raw_Address (Packet);
      begin
         Target := Data;
      end;
   end Write;

   function Sample_Count
     (Packet : Daq.API.Data_Packet'Class) return Natural
   is
      N : daqSizeT := 0;
   begin
      Check (daqDataPacket_getSampleCount (Self_H (Packet), N),
             "daqDataPacket_getSampleCount");
      return Natural (N);
   end Sample_Count;

   function Read
     (Packet : Daq.API.Data_Packet'Class) return Sample_Array
   is
      N : constant Natural := Sample_Count (Packet);
   begin
      if N = 0 then
         return (1 .. 0 => <>);
      end if;
      declare
         Source : Sample_Array (0 .. N - 1)
           with Import, Address => Raw_Address (Packet);
      begin
         return Source;
      end;
   end Read;

end Daq.Packet_Buffers;
