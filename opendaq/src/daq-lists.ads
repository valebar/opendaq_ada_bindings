with Copendaq;

--  Wrapper over IList (daqList). Iterable with GNAT's aspect:
--     for Item of My_List loop ... end loop   --  Item : Daq.Object
package Daq.Lists is

   type List is new Daq.Object with null record
     with Iterable => (First       => First,
                       Next        => Next,
                       Has_Element => Has_Element,
                       Element     => Element);

   function Create return List;

   function Count (Self : List) return Natural;

   function Element (Self : List; Index : Natural) return Daq.Object;
   --  0-based, owned wrapper of the element.

   procedure Append (Self : List; Item : Daq.Object'Class);

   --  Iterable plumbing (cursor = 0-based index).
   function First (Self : List) return Natural is (0);
   function Next (Self : List; C : Natural) return Natural is (C + 1);
   function Has_Element (Self : List; C : Natural) return Boolean is
     (C < Count (Self));

   --  Wrapper construction: List inherits Take / Borrow / No_Object from
   --  Daq.Object (null extension), returning List.

end Daq.Lists;
