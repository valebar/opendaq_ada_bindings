with Daq;

--  Library-level handler for the core_events example: Daq.Events.Callback
--  is a library-level access type, so the subscribed procedure cannot be
--  nested inside the example's main procedure.
package Core_Event_Handler is

   procedure Handle (Sender, Args : Daq.Object);

   function Events_Seen return Natural;

end Core_Event_Handler;
