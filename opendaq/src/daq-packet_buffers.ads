with Daq.API;

--  Writing (and reading back) sample data in IDataPacket buffers — the
--  missing piece for producing signals programmatically: build a packet
--  with Daq.API.Create_Data_Packet, fill it here, then
--  Signal_Config.Send_Packet.
generic
   type Sample is private;
package Daq.Packet_Buffers is

   type Sample_Array is array (Natural range <>) of aliased Sample
     with Convention => C;

   procedure Write
     (Packet : Daq.API.Data_Packet'Class;
      Data   : Sample_Array);
   --  Copies Data into the packet's raw buffer (raises Opendaq_Error when
   --  the packet buffer is smaller than Data).

   function Sample_Count
     (Packet : Daq.API.Data_Packet'Class) return Natural;

   function Read
     (Packet : Daq.API.Data_Packet'Class) return Sample_Array;
   --  The packet's (raw) buffer content, Sample_Count samples long.

end Daq.Packet_Buffers;
