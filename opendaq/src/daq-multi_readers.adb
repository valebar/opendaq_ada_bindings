with System;

with Copendaq.Reader;

package body Daq.Multi_Readers is

   use Copendaq;
   use Copendaq.Reader;

   function Self_H (R : Reader) return Copendaq.Types.daqMultiReader is
     (Copendaq.Types.daqMultiReader (Handle (R)));

   procedure Drop (Status : in out Copendaq.Types.daqMultiReaderStatus) is
      H : daqBaseObject := daqBaseObject (Status);
   begin
      Release_Handle (H);
      Status := Copendaq.Types.daqMultiReaderStatus (Null_Object);
   end Drop;

   function Create
     (Signals      : Daq.Lists.List'Class;
      Mode         : Copendaq.Types.daqReadMode :=
        Copendaq.Types.daqReadModeScaled;
      Timeout_Type : Copendaq.Types.daqReadTimeoutType :=
        Copendaq.Types.daqReadTimeoutTypeAny)
      return Reader
   is
      H : Copendaq.Types.daqMultiReader;
   begin
      Check
        (daqMultiReader_createMultiReader
           (H,
            Copendaq.Types.daqList (Handle (Signals)),
            Value_Kind, Domain_Kind, Mode, Timeout_Type),
         "daqMultiReader_createMultiReader");
      return Take (daqBaseObject (H));
   end Create;

   function Available (R : Reader) return Natural is
      N : daqSizeT := 0;
   begin
      Check
        (daqReader_getAvailableCount
           (Copendaq.Types.daqReader (Handle (R)), N),
         "daqReader_getAvailableCount");
      return Natural (N);
   end Available;

   --  The C API's `samples` argument is a void** — one buffer pointer per
   --  signal. Rows of the (row-major, Convention C) matrices are the
   --  per-signal buffers.
   type Address_Array is array (Natural range <>) of aliased daqVoidPtr
     with Convention => C;

   procedure Read
     (R          : Reader;
      Values     : out Sample_Matrix;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0)
   is
      Rows : constant Natural := Values'Length (1);
      N    : daqSizeT :=
        daqSizeT (Natural'Min (Count, Values'Length (2)));
      Ptrs   : aliased Address_Array (0 .. Rows - 1);
      Status : Copendaq.Types.daqMultiReaderStatus;
      Code   : daqErrCode;
   begin
      for I in 0 .. Rows - 1 loop
         Ptrs (I) :=
           Values (Values'First (1) + I, Values'First (2))'Address;
      end loop;
      Code := daqMultiReader_read
        (Self_H (R), Ptrs (0)'Address, N, daqSizeT (Timeout_Ms), Status);
      Drop (Status);
      Check (Code, "daqMultiReader_read");
      Count := Natural (N);
   end Read;

   procedure Read_With_Domain
     (R          : Reader;
      Values     : out Sample_Matrix;
      Domains    : out Domain_Matrix;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0)
   is
      Rows : constant Natural := Values'Length (1);
      N    : daqSizeT :=
        daqSizeT (Natural'Min
                    (Count,
                     Natural'Min
                       (Values'Length (2), Domains'Length (2))));
      V_Ptrs : aliased Address_Array (0 .. Rows - 1);
      D_Ptrs : aliased Address_Array (0 .. Rows - 1);
      Status : Copendaq.Types.daqMultiReaderStatus;
      Code   : daqErrCode;
   begin
      if Domains'Length (1) /= Rows then
         raise Opendaq_Error with
           "Multi_Readers: Values/Domains row counts differ";
      end if;
      for I in 0 .. Rows - 1 loop
         V_Ptrs (I) :=
           Values (Values'First (1) + I, Values'First (2))'Address;
         D_Ptrs (I) :=
           Domains (Domains'First (1) + I, Domains'First (2))'Address;
      end loop;
      Code := daqMultiReader_readWithDomain
        (Self_H (R), V_Ptrs (0)'Address, D_Ptrs (0)'Address, N,
         daqSizeT (Timeout_Ms), Status);
      Drop (Status);
      Check (Code, "daqMultiReader_readWithDomain");
      Count := Natural (N);
   end Read_With_Domain;

end Daq.Multi_Readers;
