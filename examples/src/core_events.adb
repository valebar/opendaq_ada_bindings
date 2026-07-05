with Ada.Command_Line;
with Ada.Text_IO;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;
with Daq.Events;

with Core_Event_Handler;
with Example_Support; use Example_Support;

--  Subscribe to the context's core event, change channel properties,
--  observe the attribute/property events.
procedure Core_Events is
   use Ada.Text_IO;

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);
   Dev  : constant Device'Class := Connect_By_Prefix (Inst, "daqref");
begin
   if Dev.Is_Null then
      Put_Line ("core_events: FAIL - no daqref device");
      Ada.Command_Line.Set_Exit_Status (1);
      return;
   end if;

   declare
      Chan : constant Channel'Class :=
        As_Channel (Dev.Find_Component ("IO/AI/RefCh0"));
      Sub  : Daq.Events.Subscription :=
        Daq.Events.Subscribe
          (Inst.Get_Context.Get_On_Core_Event,
           Core_Event_Handler.Handle'Access);
   begin
      Chan.Set_Property_Value ("Frequency", To_Daq (25.0));
      Chan.Set_Property_Value ("Amplitude", To_Daq (7.5));

      delay 1.0;
      Daq.Events.Unsubscribe (Sub);

      Put_Line ("core_events:"
                & Core_Event_Handler.Events_Seen'Image & " events");
      if Core_Event_Handler.Events_Seen > 0 then
         Put_Line ("core_events: OK");
      else
         Put_Line ("core_events: FAIL - no events observed");
         Ada.Command_Line.Set_Exit_Status (1);
      end if;
   end;
end Core_Events;
