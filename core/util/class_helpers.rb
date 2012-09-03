# A module with utility functions for classes.

# All of these are only meant to be called from a class (not instance) context.
module ClassUtil
   # Define a re-loadable constant.
   # So... a constant that can change.
   def RELOADABLE_CONSTANT(name, value)
      if (self.const_defined?(name))
         self.send(:remove_const, name)
      end

      self.const_set(name, value)
   end

   def RELOADABLE_CLASS_VARIABLE(name, defaultValue)
      # Don't do anything is the class variable is defined.
      if (!self.class_variable_defined?(name))
         self.class_variable_set(name, defaultValue)
      end
   end
end
