module CrystalModule
   # extend self

   class CrystalClass
      CLASS_ROOT_CONST = 42
      @@CLASS_CONST = 47

      def self.class_func()
         true
      end

      def memb_func()
         true
      end

   end

   @@MODULE_CONST = 47
   ROOT_CONST = 47

   foo = 42

   def root_def()
      true
   end

   def self.self_def()
      true
   end

end

pp CrystalModule

pp CrystalModule::ROOT_CONST
pp CrystalModule::CrystalClass
pp CrystalModule::CrystalClass::CLASS_ROOT_CONST
pp CrystalModule.self_def
pp CrystalModule::CrystalClass.class_func

# pp CrystalModule::foo
# pp CrystalModule.foo
# pp CrystalModule::MODULE_CONST
# pp CrystalModule::CrystalClass.CLASS_CONST
# pp CrystalModule.root_def
# pp CrystalModule::CrystalClass.memb_func

module CrystalModule2
   extend self

   class CrystalClass
      CLASS_ROOT_CONST = 42
      @@CLASS_CONST = 47

      def self.class_func()
         true
      end

      def memb_func()
         true
      end

   end

   @@MODULE_CONST = 47
   ROOT_CONST = 47

   foo = 42

   def root_def()
      true
   end

   def self.self_def()
      true
   end

end

pp CrystalModule2

pp CrystalModule2::ROOT_CONST
pp CrystalModule2::CrystalClass
pp CrystalModule2::CrystalClass::CLASS_ROOT_CONST
pp CrystalModule2.self_def
pp CrystalModule2::CrystalClass.class_func
pp CrystalModule2.root_def

# pp CrystalModule2::foo
# pp CrystalModule2.foo
# pp CrystalModule2::MODULE_CONST
# pp CrystalModule2::CrystalClass.CLASS_CONST
##pp CrystalModule2::CrystalClass.memb_func
