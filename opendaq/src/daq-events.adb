with Interfaces.C;

with Copendaq.Core_Types;
with Copendaq.Types;

package body Daq.Events is

   use Copendaq;
   use Copendaq.Core_Types;

   ----------------------------------------------------------------
   --  Slot registry
   ----------------------------------------------------------------

   type Callback_Array is array (1 .. Max_Subscriptions) of Callback;

   protected Registry is
      procedure Acquire (CB : Callback; Slot : out Natural);  --  0 when full
      procedure Release (Slot : Natural);
      function Get (Slot : Natural) return Callback;
   private
      Slots : Callback_Array := (others => null);
   end Registry;

   protected body Registry is
      procedure Acquire (CB : Callback; Slot : out Natural) is
      begin
         Slot := 0;
         for I in Slots'Range loop
            if Slots (I) = null then
               Slots (I) := CB;
               Slot := I;
               return;
            end if;
         end loop;
      end Acquire;

      procedure Release (Slot : Natural) is
      begin
         if Slot in Slots'Range then
            Slots (Slot) := null;
         end if;
      end Release;

      function Get (Slot : Natural) return Callback is
      begin
         if Slot in Slots'Range then
            return Slots (Slot);
         end if;
         return null;
      end Get;
   end Registry;

   procedure Dispatch (Slot : Natural; Sender, Args : daqBaseObject) is
      CB : constant Callback := Registry.Get (Slot);
   begin
      if CB /= null then
         --  Borrow: the C side owns its references for the call duration;
         --  copies the user keeps get their own ref via Adjust.
         CB (Daq.Borrow (Sender), Daq.Borrow (Args));
      end if;
   exception
      when others =>
         null;  --  never propagate into the C runtime
   end Dispatch;

   ----------------------------------------------------------------
   --  Trampoline pool: one C-convention procedure per slot
   ----------------------------------------------------------------

   generic
      Slot : Natural;
   procedure Trampoline_G (Sender, Args : daqBaseObject) with Convention => C;

   procedure Trampoline_G (Sender, Args : daqBaseObject) is
   begin
      Dispatch (Slot, Sender, Args);
   end Trampoline_G;

   --  64 library-level instantiations (Max_Subscriptions).
   procedure T01 is new Trampoline_G (1);   procedure T02 is new Trampoline_G (2);
   procedure T03 is new Trampoline_G (3);   procedure T04 is new Trampoline_G (4);
   procedure T05 is new Trampoline_G (5);   procedure T06 is new Trampoline_G (6);
   procedure T07 is new Trampoline_G (7);   procedure T08 is new Trampoline_G (8);
   procedure T09 is new Trampoline_G (9);   procedure T10 is new Trampoline_G (10);
   procedure T11 is new Trampoline_G (11);  procedure T12 is new Trampoline_G (12);
   procedure T13 is new Trampoline_G (13);  procedure T14 is new Trampoline_G (14);
   procedure T15 is new Trampoline_G (15);  procedure T16 is new Trampoline_G (16);
   procedure T17 is new Trampoline_G (17);  procedure T18 is new Trampoline_G (18);
   procedure T19 is new Trampoline_G (19);  procedure T20 is new Trampoline_G (20);
   procedure T21 is new Trampoline_G (21);  procedure T22 is new Trampoline_G (22);
   procedure T23 is new Trampoline_G (23);  procedure T24 is new Trampoline_G (24);
   procedure T25 is new Trampoline_G (25);  procedure T26 is new Trampoline_G (26);
   procedure T27 is new Trampoline_G (27);  procedure T28 is new Trampoline_G (28);
   procedure T29 is new Trampoline_G (29);  procedure T30 is new Trampoline_G (30);
   procedure T31 is new Trampoline_G (31);  procedure T32 is new Trampoline_G (32);
   procedure T33 is new Trampoline_G (33);  procedure T34 is new Trampoline_G (34);
   procedure T35 is new Trampoline_G (35);  procedure T36 is new Trampoline_G (36);
   procedure T37 is new Trampoline_G (37);  procedure T38 is new Trampoline_G (38);
   procedure T39 is new Trampoline_G (39);  procedure T40 is new Trampoline_G (40);
   procedure T41 is new Trampoline_G (41);  procedure T42 is new Trampoline_G (42);
   procedure T43 is new Trampoline_G (43);  procedure T44 is new Trampoline_G (44);
   procedure T45 is new Trampoline_G (45);  procedure T46 is new Trampoline_G (46);
   procedure T47 is new Trampoline_G (47);  procedure T48 is new Trampoline_G (48);
   procedure T49 is new Trampoline_G (49);  procedure T50 is new Trampoline_G (50);
   procedure T51 is new Trampoline_G (51);  procedure T52 is new Trampoline_G (52);
   procedure T53 is new Trampoline_G (53);  procedure T54 is new Trampoline_G (54);
   procedure T55 is new Trampoline_G (55);  procedure T56 is new Trampoline_G (56);
   procedure T57 is new Trampoline_G (57);  procedure T58 is new Trampoline_G (58);
   procedure T59 is new Trampoline_G (59);  procedure T60 is new Trampoline_G (60);
   procedure T61 is new Trampoline_G (61);  procedure T62 is new Trampoline_G (62);
   procedure T63 is new Trampoline_G (63);  procedure T64 is new Trampoline_G (64);

   Trampolines : constant array (1 .. Max_Subscriptions) of daqEventCall :=
     (T01'Access, T02'Access, T03'Access, T04'Access, T05'Access, T06'Access,
      T07'Access, T08'Access, T09'Access, T10'Access, T11'Access, T12'Access,
      T13'Access, T14'Access, T15'Access, T16'Access, T17'Access, T18'Access,
      T19'Access, T20'Access, T21'Access, T22'Access, T23'Access, T24'Access,
      T25'Access, T26'Access, T27'Access, T28'Access, T29'Access, T30'Access,
      T31'Access, T32'Access, T33'Access, T34'Access, T35'Access, T36'Access,
      T37'Access, T38'Access, T39'Access, T40'Access, T41'Access, T42'Access,
      T43'Access, T44'Access, T45'Access, T46'Access, T47'Access, T48'Access,
      T49'Access, T50'Access, T51'Access, T52'Access, T53'Access, T54'Access,
      T55'Access, T56'Access, T57'Access, T58'Access, T59'Access, T60'Access,
      T61'Access, T62'Access, T63'Access, T64'Access);

   ----------------------------------------------------------------
   --  API
   ----------------------------------------------------------------

   function Subscribe (Ev : Event'Class; CB : Callback) return Subscription
   is
      Slot    : Natural;
      Handler : Copendaq.Types.daqEventHandler;
      Ignore  : Interfaces.C.int;
      S       : Subscription;
   begin
      if Ev.Is_Null then
         raise Opendaq_Error with "Subscribe: null event";
      end if;
      if CB = null then
         raise Opendaq_Error with "Subscribe: null callback";
      end if;

      Registry.Acquire (CB, Slot);
      if Slot = 0 then
         raise Opendaq_Error with
           "Subscribe: trampoline pool exhausted ("
           & Max_Subscriptions'Image & " )";
      end if;

      begin
         Check (daqEventHandler_createEventHandler
                  (Handler, Trampolines (Slot)),
                "daqEventHandler_createEventHandler");
         Check (daqEvent_addHandler
                  (Copendaq.Types.daqEvent (Handle (Ev)),
                   Handler),
                "daqEvent_addHandler");
      exception
         when others =>
            Registry.Release (Slot);
            raise;
      end;

      Ignore := daqBaseObject_addRef (Handle (Ev));
      S := (Slot      => Slot,
            Ev        => Handle (Ev),
            Handler_H => daqBaseObject (Handler));
      return S;
   end Subscribe;

   procedure Unsubscribe (S : in out Subscription) is
   begin
      if S.Slot = 0 then
         return;
      end if;
      Check (daqEvent_removeHandler
               (Copendaq.Types.daqEvent (S.Ev),
                Copendaq.Types.daqEventHandler (S.Handler_H)),
             "daqEvent_removeHandler");
      Release_Handle (S.Handler_H);
      Release_Handle (S.Ev);
      Registry.Release (S.Slot);
      S := No_Subscription;
   end Unsubscribe;

   function Subscriber_Count (Ev : Event'Class) return Natural is
      N : daqSizeT := 0;
   begin
      if Ev.Is_Null then
         return 0;
      end if;
      Check (daqEvent_getSubscriberCount
               (Copendaq.Types.daqEvent (Handle (Ev)), N),
             "daqEvent_getSubscriberCount");
      return Natural (N);
   end Subscriber_Count;

end Daq.Events;
