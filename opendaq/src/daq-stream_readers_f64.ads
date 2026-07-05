with Copendaq.Types;

with Daq.Stream_Readers;

--  The common instantiation: Float64 values with Int64 (tick) domain.
package Daq.Stream_Readers_F64 is new Daq.Stream_Readers
  (Sample      => Long_Float,
   Value_Kind  => Copendaq.Types.daqSampleTypeFloat64,
   Domain      => Long_Long_Integer,
   Domain_Kind => Copendaq.Types.daqSampleTypeInt64);
