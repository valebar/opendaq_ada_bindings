with Copendaq;
with Copendaq.Types;

with Daq.API;

--  Typed stream reader over IStreamReader (daqStreamReader): the hot-path,
--  hand-written counterpart of the generated wrappers. Reads go straight
--  into an Ada array (Buffer'Address into the C API) — no per-sample
--  marshalling or controlled wrappers.
--
--  Instantiate per (value, domain) sample type — see Daq.Stream_Readers_F64
--  for the common Float64/Int64 case — with Kind values matching the Sample/
--  Domain representations (daqSampleTypeFloat64 <-> Long_Float etc.).
generic
   type Sample is private;
   Value_Kind : Copendaq.Types.daqSampleType;
   type Domain is private;
   Domain_Kind : Copendaq.Types.daqSampleType;
package Daq.Stream_Readers is

   type Reader is new Daq.Object with null record;

   type Sample_Array is array (Natural range <>) of aliased Sample
     with Convention => C;
   type Domain_Array is array (Natural range <>) of aliased Domain
     with Convention => C;

   function Create
     (Sig          : Daq.API.Signal'Class;
      Mode         : Copendaq.Types.daqReadMode :=
        Copendaq.Types.daqReadModeScaled;
      Timeout_Type : Copendaq.Types.daqReadTimeoutType :=
        Copendaq.Types.daqReadTimeoutTypeAny)
      return Reader;

   function Available (R : Reader) return Natural;
   --  Samples ready to read right now.

   procedure Read
     (R          : Reader;
      Buffer     : out Sample_Array;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0);
   --  In: Count = max samples wanted (<= Buffer'Length).
   --  Out: Count = samples actually written to Buffer (from Buffer'First).

   procedure Read_With_Domain
     (R          : Reader;
      Values     : out Sample_Array;
      Domains    : out Domain_Array;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0);
   --  Same, filling value and domain (e.g. timestamp ticks) in lockstep.

end Daq.Stream_Readers;
