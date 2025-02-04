defmodule Arango.Utils.AqlBuilder do
  defmacro __using__(_opts) do
    quote do
      # Sort funcs
      def sort(enumerator, {key}, :asc),                                              do: "#{enumerator}.#{key} ASC"
      def sort(enumerator, {key}, :desc),                                             do: "#{enumerator}.#{key} DESC"
      def sort(_, _, _),                                                              do: ""

      # Filter funcs
      def filter(enumerator, {key, value}, :equal) when is_binary(value),             do: "#{enumerator}.#{key} == '#{value}'"
      def filter(enumerator, {key, value}, :equal),                                   do: "#{enumerator}.#{key} == #{value}"
      def filter(enumerator, {key, value}, :greater_or_equal),                        do: "#{enumerator}.#{key} >= #{value}"
      def filter(enumerator, {key, value}, :less_or_equal),                           do: "#{enumerator}.#{key} <= #{value}"
      def filter(enumerator, {key, value}, :greater),                                 do: "#{enumerator}.#{key} > #{value}"
      def filter(enumerator, {key, value}, :less),                                    do: "#{enumerator}.#{key} < #{value}"
      def filter(enumerator, {key, {high, low}}, :in_range),                          do: "#{low} <= #{enumerator}.#{key} <= #{high} "
      def filter(enumerator, {key, value}, :in_list),                                 do: "#{value} IN #{enumerator}.#{key}"
      def filter(enumerator, {key, value}, :contains),                                do: "CONTAINS(LOWER(#{enumerator}.#{key}), LOWER('#{value}'))"
      def filter(_, _, _),                                                            do: ""

      # Limit funcs
      def limit(offset, count),  do: "#{offset}, #{count}"
      def limit(count),         do: "#{count}"
      def limit(_),             do: ""
    end
  end
end
