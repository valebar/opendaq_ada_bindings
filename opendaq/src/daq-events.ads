with Copendaq;

--  Wrapper over IEvent (daqEvent) plus Ada-side subscriptions.
--
--  The C callback type (daqEventCall) carries NO user-data pointer, and Ada
--  cannot synthesize closure thunks at runtime, so subscriptions go through
--  a fixed pool of C-convention trampolines, each statically bound to a slot
--  in a protected table (see the body). Pool size: Max_Subscriptions.
--
--  Callbacks execute on whatever openDAQ thread triggers the event — keep
--  them short and synchronize access to shared state yourself.
package Daq.Events is

   Max_Subscriptions : constant := 64;

   type Event is new Daq.Object with null record;

   type Callback is access procedure (Sender, Args : Daq.Object);

   type Subscription is private;

   No_Subscription : constant Subscription;

   function Subscribe (Ev : Event'Class; CB : Callback) return Subscription;
   --  Raises Opendaq_Error when the pool is exhausted. Keep the returned
   --  Subscription and Unsubscribe when done; letting it dangle keeps the
   --  slot occupied for the process lifetime.

   procedure Unsubscribe (S : in out Subscription);
   --  Removes the handler from the event and frees the slot. Null-safe.

   function Subscriber_Count (Ev : Event'Class) return Natural;

   --  Wrapper construction: Event inherits Take / Borrow / No_Object from
   --  Daq.Object (null extension), returning Event.

private

   type Subscription is record
      Slot      : Natural := 0;                     --  0 = inactive
      Ev        : Copendaq.daqBaseObject := Copendaq.Null_Object;
      Handler_H : Copendaq.daqBaseObject := Copendaq.Null_Object;
   end record;

   No_Subscription : constant Subscription := (others => <>);

end Daq.Events;
