defmodule Bittorrent.CLI do
  def main(argv) do
      case argv do
          ["decode" | [encoded_str | _]] ->
              # You can use print statements as follows for debugging, they'll be visible when running tests.
              IO.puts(:stderr, "Logs from your program will appear here!")

              decoded_str = Bencode.decode(encoded_str)
              IO.puts(Jason.encode!(decoded_str))
          ["info" | filename] ->
             info = Bencode.get_file_info(filename)
             IO.puts("Tracker URL: #{info["announce"]}")
             IO.puts("Length: #{info["info"]["length"]}")
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

    def decode_next("l" <> rest) do
     decode_list([], rest)
    end

    def decode_next("d" <> rest) do
     decode_dictionary(%{}, rest)
    end

    def decode_next(encoded_value) when is_binary(encoded_value)  do
      [length, str] = String.split(encoded_value, ":", parts: 2)
      String.split_at(str, String.to_integer(length))
    end

    def decode_list(decoded_items, rest) do
       # end of the list
      if String.first(rest) ==  "e" do
       {Enum.reverse(decoded_items), String.slice(rest, 1, byte_size(rest) - 1)}
      else
       {item, rest } = decode_next(rest)
       decode_list([item | decoded_items], rest)
      end
    end

    def decode_dictionary(decodes_keys, encoded_string) do
      # end of the list
      if String.first(encoded_string) ==  "e" do
       { decodes_keys, String.slice(encoded_string, 1, byte_size(encoded_string) - 1)}
      else
       { key, rest } = decode_next(encoded_string)
       { val, rest} = decode_next(rest)
      # IO.puts("a #{key}:#{val}")
       decode_dictionary(Map.put(decodes_keys, key, val), rest)
      end
    end

    def decode(encoded_value) when is_binary(encoded_value) do
        {decoded, _ }= decode_next(encoded_value)
        decoded
    end

    def decode(_), do: "Invalid encoded value: not binary"

    def get_file_info(filename) do
      case File.read(filename) do
        {:ok, content} -> decode(content)
        {:error, reason } -> IO.puts(reason)
      end
    end
end
