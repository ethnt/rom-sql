require 'sequel/core'

Sequel.extension(:pg_range, :pg_range_ops)

module ROM
  module SQL
    module Postgres
      module Values
        Range = ::Struct.new(:lower, :upper, :bounds) do
          def initialize(lower, upper, bounds = :'[)')
            super
          end

          def exclude_begin?
            bounds[0] == '('
          end

          def exclude_end?
            bounds[1] == ')'
          end
        end
      end

      # @api public
      module Types
        # The list of range types supported by PostgreSQL
        # @see https://www.postgresql.org/docs/current/static/rangetypes.html

        @range_parsers = {
          int4range: Sequel::Postgres::PGRange::Parser.new(
            'int4range', SQL::Types::Coercible::Int
          ),
          int8range: Sequel::Postgres::PGRange::Parser.new(
            'int8range', SQL::Types::Coercible::Int
          ),
          numrange:  Sequel::Postgres::PGRange::Parser.new(
            'numrange', SQL::Types::Coercible::Int
          ),
          tsrange:   Sequel::Postgres::PGRange::Parser.new(
            'tsrange', SQL::Types::Form::Time
          ),
          tstzrange: Sequel::Postgres::PGRange::Parser.new(
            'tstzrange', SQL::Types::Form::Time
          ),
          daterange: Sequel::Postgres::PGRange::Parser.new(
            'daterange', SQL::Types::Form::Date
          )
        }.freeze

        # @api private
        def self.range_read_type(name)
          SQL::Types.Constructor(Values::Range) do |value|
            pg_range =
              if value.is_a?(Sequel::Postgres::PGRange)
                value
              elsif value && value.respond_to?(:to_s)
                @range_parsers[name].(value.to_s)
              else
                value
              end

            Values::Range.new(
              pg_range.begin,
              pg_range.end,
              [pg_range.exclude_begin? ? :'(' : :'[',
               pg_range.exclude_end? ? :')' : :']']
              .join('').to_sym
            )
          end
        end

        # @api private
        def self.range(name, read_type)
          Type(name) do
            type = SQL::Types.Definition(Values::Range).constructor do |range|
              format('%s%s,%s%s',
                     range.exclude_begin? ? :'(' : :'[',
                     range.lower,
                     range.upper,
                     range.exclude_end? ? :')' : :']')
            end

            type.meta(read: read_type)
          end
        end

        Int4Range = range('int4range', range_read_type(:int4range))
        Int8Range = range('int8range', range_read_type(:int8range))
        NumRange  = range('numrange',  range_read_type(:numrange))
        TsRange   = range('tsrange',   range_read_type(:tsrange))
        TsTzRange = range('tstzrange', range_read_type(:tstzrange))
        DateRange = range('daterange', range_read_type(:daterange))

        module RangeOperators
          def contains(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).contains(value)
            )
          end

          def contained_by(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).contained_by(value)
            )
          end

          def overlaps(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).overlaps(value)
            )
          end

          def left_of(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).left_of(value)
            )
          end

          def right_of(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).right_of(value)
            )
          end

          def starts_after(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).starts_after(value)
            )
          end

          def ends_before(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).ends_before(value)
            )
          end

          def adjacent_to(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).adjacent_to(value)
            )
          end
        end

        module RangeFunctions
          def lower(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).lower
            )
          end

          def upper(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).upper
            )
          end

          def isempty(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).isempty
            )
          end

          def lower_inc(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).lower_inc
            )
          end

          def upper_inc(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).upper_inc
            )
          end

          def lower_inf(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).lower_inf
            )
          end

          def upper_inf(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).upper_inf
            )
          end
        end

        TypeExtensions.register(Int4Range) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(Int8Range) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(NumRange) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(TsRange) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(TsTzRange) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(DateRange) do
          include RangeOperators
          include RangeFunctions
        end
      end
    end
  end
end
