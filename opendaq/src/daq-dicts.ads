with Copendaq;

with Daq.Lists;

--  Wrapper over IDict (daqDict). Keys and values are Daq.Objects; use the
--  As_* extractors (or Daq.API casts) on the results.
package Daq.Dicts is

   type Dict is new Daq.Object with null record;

   function Create return Dict;

   function Count (Self : Dict) return Natural;

   function Get (Self : Dict; Key : Daq.Object'Class) return Daq.Object;
   function Get (Self : Dict; Key : String) return Daq.Object;

   procedure Set (Self : Dict; Key, Value : Daq.Object'Class);
   procedure Set (Self : Dict; Key : String; Value : Daq.Object'Class);

   function Has_Key (Self : Dict; Key : String) return Boolean;

   function Keys (Self : Dict) return Daq.Lists.List;
   function Values (Self : Dict) return Daq.Lists.List;

   --  Wrapper construction: Dict inherits Take / Borrow / No_Object from
   --  Daq.Object (null extension), returning Dict.

end Daq.Dicts;
