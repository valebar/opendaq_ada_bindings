with Copendaq.Reader;

package body Daq.Stream_Readers is

   use Copendaq;
   use Copendaq.Reader;

   function Self_H (R : Reader) return Copendaq.Types.daqStreamReader is
     (Copendaq.Types.daqStreamReader (Handle (R)));

   --  Reader statuses are returned owned (+1) on every read; we don't
   --  surface them (failed reads raise via Check), so just drop the ref.
   procedure Drop (Status : in out Copendaq.Types.daqReaderStatus) is
      H : daqBaseObject := daqBaseObject (Status);
   begin
      Release_Handle (H);
      Status := Copendaq.Types.daqReaderStatus (Null_Object);
   end Drop;

   function Create
     (Sig          : Daq.API.Signal'Class;
      Mode         : Copendaq.Types.daqReadMode :=
        Copendaq.Types.daqReadModeScaled;
      Timeout_Type : Copendaq.Types.daqReadTimeoutType :=
        Copendaq.Types.daqReadTimeoutTypeAny)
      return Reader
   is
      H : Copendaq.Types.daqStreamReader;
   begin
      Check
        (daqStreamReader_createStreamReader
           (H,
            Copendaq.Types.daqSignal (Handle (Sig)),
            Value_Kind, Domain_Kind, Mode, Timeout_Type),
         "daqStreamReader_createStreamReader");
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

   procedure Read
     (R          : Reader;
      Buffer     : out Sample_Array;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0)
   is
      N      : daqSizeT :=
        daqSizeT (Natural'Min (Count, Buffer'Length));
      Status : Copendaq.Types.daqReaderStatus;
      Code   : daqErrCode;
   begin
      Code := daqStreamReader_read
        (Self_H (R),
         Buffer (Buffer'First)'Address,
         N,
         daqSizeT (Timeout_Ms),
         Status);
      Drop (Status);
      Check (Code, "daqStreamReader_read");
      Count := Natural (N);
   end Read;

   procedure Read_With_Domain
     (R          : Reader;
      Values     : out Sample_Array;
      Domains    : out Domain_Array;
      Count      : in out Natural;
      Timeout_Ms : Natural := 0)
   is
      N : daqSizeT :=
        daqSizeT (Natural'Min
                    (Count,
                     Natural'Min (Values'Length, Domains'Length)));
      Status : Copendaq.Types.daqReaderStatus;
      Code   : daqErrCode;
   begin
      Code := daqStreamReader_readWithDomain
        (Self_H (R),
         Values (Values'First)'Address,
         Domains (Domains'First)'Address,
         N,
         daqSizeT (Timeout_Ms),
         Status);
      Drop (Status);
      Check (Code, "daqStreamReader_readWithDomain");
      Count := Natural (N);
   end Read_With_Domain;

end Daq.Stream_Readers;
