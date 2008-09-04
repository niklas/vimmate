module VimMate
  module Tree
    module Definitions
      module Column
        @@columns = []
        def self.column(label,type)
          @@columns << [label.to_sym, type]
          const_set label.to_s.upcase, @@columns.length-1
        end
        def self.columns
          @@columns
        end
        def columns
          self.class.columns
        end
        def self.columns_labels
          columns.collect { |c| c[0] }
        end
        def columns_labels
          self.class.columns_labels
        end
        def self.columns_types
          columns.collect { |c| c[1] }
        end
      end
    end
  end
end
