defmodule Bittorrent.CLI do
  def main(argv) do
      case argv do
          ["decode" | [encoded_str | _]] ->
              # You can use print statements as follows for debugging, they'll be visible when running tests.
              IO.puts(:stderr, "Logs from your program will appear here!")

              decoded_str = Bencode.decode(encoded_str)
              IO.puts(Jason.encode!(decoded_str))
          [command | _] ->
              IO.puts("Unknown command: #{command}")
              System.halt(1)
          [] ->
              IO.puts("Usage: your_bittorrent.sh <command> <args>")
              System.halt(1)
      end
  end
end

defmodule Bencode do
    def decode_next("i" <> rest) when byte_size(rest) > 2 do
      case String.split(rest, "e", parts: 2) do
        [numeric_str, rest] -> { String.to_integer(numeric_str), rest }
      end
    end

    def decode_next(encoded_value) when is_binary(encoded_value) do
      [length, str] = String.split(encoded_value, ":")
      String.split_at(str, String.to_integer(length))
    end

    def decode_list(decoded_items, rest) do
       # end of the list
      if String.first(rest, "e") do
       {Enum.reverse(decoded_items), String.slice(rest, 1, byte_size(rest) - 1)}
      else
       {item, rest } = decode_next(rest)
       decode_list([item | decoded_items], rest)
      end
    end

    def decode(encoded_value) when is_binary(encoded_value) do
        binary_data = :binary.bin_to_list(encoded_value)
        case Enum.find_index(binary_data, fn char -> char == 58 end) do
          nil ->
            binary_data
             |> List.delete_at(0)
             |> List.delete_at(length(binary_data) - 2)
             |> List.to_integer
          index ->
            rest = Enum.slice(binary_data, index+1..-1)
            List.to_string(rest)
        end
      end

    def decode(_), do: "Invalid encoded value: not binary"
end
