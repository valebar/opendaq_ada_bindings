with Copendaq;
with Copendaq.Types;

with Daq.Lists;

--  Typed multi-signal reader over IMultiReader (daqMultiReader): reads
--  several signals in lockstep (aligned by domain). Matrices are indexed
--  (signal, sample); rows must match the number of signals the reader was
--  created with.
generic
   type Sample is private;
   Value_Kind : Copendaq.Types.daqSampleType;
   type Domain is private;
   Domain_Kind : Copendaq.Types.daqSampleType;
package Daq.Multi_Readers is

   type Reader is new Daq.Object with null record;

   type Sample_Matrix is
     array (Natural range <>, Natural range <>) of aliased Sample
     with Convention => C;
   type Domain_Matrix is
     array (Natural range <>, Natural range <>) of aliased Domain
     with Convention => C;

   function Create
     (Signals      : Daq.Lists.List'Class;
      Mode         : Copendaq.Types.daqReadMode :=
        Copendaq.Types.daqReadModeScaled;
      Timeout_Type : Copendaq.Types.daqReadTimeoutType :=
        Copendaq.Types.daqReadTimeoutTypeAny)
      return Reader;

   function Available (R : Reader) return Natural;

   procedure Read
     (R          : Reader;
      Values     : out Sample_Matrix;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0);
   --  In: Count = max samples per signal (<= Values'Length (2)).
   --  Out: Count = samples written per signal, from column Values'First (2).

   procedure Read_With_Domain
     (R          : Reader;
      Values     : out Sample_Matrix;
      Domains    : out Domain_Matrix;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0);

end Daq.Multi_Readers;
