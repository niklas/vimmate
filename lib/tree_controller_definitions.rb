module VimMate
  module Tree
    module Definitions
      module Column
        def self.included(base)
          base.class_eval do
            include InstanceMethods
            extend ClassMethods
          end
        end
        module InstanceMethods
          def columns
            self.class.columns
          end
          def columns_labels
            self.class.columns_labels
          end
        end
        module ClassMethods
          def column(label,type)
            columns << [label.to_sym, type]
            const_set label.to_s.upcase, @@columns.length-1
          end
          def columns
            @@columns ||= []
          end
          def columns_labels
            columns.collect { |c| c[0] }
          end
          def columns_types
            columns.collect { |c| c[1] }
          end
        end
      end
    end
  end
end
