# frozen_string_literal: true

module ProtoBoeuf
  class Position
    def self.decode(buff)
      buff = buff.b
      allocate.decode_from(buff, 0, buff.bytesize)
    end

    def self.encode(obj)
      buff = obj._encode "".b
      buff.force_encoding(Encoding::ASCII_8BIT)
    end
    # required field readers
    attr_accessor :x, :y, :z

    def initialize(x: 0, y: 0, z: 0)
      @x = x
      @y = y
      @z = z
    end

    def decode_from(buff, index, len)
      @x = 0
      @y = 0
      @z = 0

      tag = buff.getbyte(index)
      index += 1

      while true
        if tag == 0x8
          ## PULL_UINT64
          @x =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x10
          ## PULL_UINT64
          @y =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x18
          ## PULL_UINT64
          @z =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end

        return self if index >= len
      end
    end
    def _encode(buff)
      val = @x
      if val != 0
        buff << 0x08

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @y
      if val != 0
        buff << 0x10

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @z
      if val != 0
        buff << 0x18

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      buff
    end
    def to_h
      result = {}
      result["x".to_sym] = @x
      result["y".to_sym] = @y
      result["z".to_sym] = @z
      result
    end
  end
  class TrunkItem
    def self.decode(buff)
      buff = buff.b
      allocate.decode_from(buff, 0, buff.bytesize)
    end

    def self.encode(obj)
      buff = obj._encode "".b
      buff.force_encoding(Encoding::ASCII_8BIT)
    end
    module ITEM_TYPE
      LAPTOP = 0
      DUFFEL_BAG = 1
      GOLF_CLUBS = 2
      BASEBALL_BAT = 3
      SUITCASE = 4
      BRICKS = 5
      CROWBAR = 6
      CASH = 7
      POKEMON_CARDS = 8
      def self.lookup(val)
        if val == 0
          :LAPTOP
        elsif val == 1
          :DUFFEL_BAG
        elsif val == 2
          :GOLF_CLUBS
        elsif val == 3
          :BASEBALL_BAT
        elsif val == 4
          :SUITCASE
        elsif val == 5
          :BRICKS
        elsif val == 6
          :CROWBAR
        elsif val == 7
          :CASH
        elsif val == 8
          :POKEMON_CARDS
        end
      end
      def self.resolve(val)
        if val == :LAPTOP
          0
        elsif val == :DUFFEL_BAG
          1
        elsif val == :GOLF_CLUBS
          2
        elsif val == :BASEBALL_BAT
          3
        elsif val == :SUITCASE
          4
        elsif val == :BRICKS
          5
        elsif val == :CROWBAR
          6
        elsif val == :CASH
          7
        elsif val == :POKEMON_CARDS
          8
        end
      end
    end

    module COUNTRY
      NOT_US_OF_A = 0
      US_OF_A = 1
      CANADA = 2
      def self.lookup(val)
        if val == 0
          :NOT_US_OF_A
        elsif val == 1
          :US_OF_A
        elsif val == 2
          :CANADA
        end
      end
      def self.resolve(val)
        if val == :NOT_US_OF_A
          0
        elsif val == :US_OF_A
          1
        elsif val == :CANADA
          2
        end
      end
    end
    # required field readers
    attr_accessor :id,
                  :owner_id,
                  :width,
                  :height,
                  :depth,
                  :weight,
                  :is_usbc,
                  :pos,
                  :is_umbrella,
                  :monetary_value

    # enum readers
    def made_in
      COUNTRY.lookup(@made_in) || @made_in
    end
    def item_type
      ITEM_TYPE.lookup(@item_type) || @item_type
    end
    # enum writers
    def made_in=(v)
      @made_in = COUNTRY.resolve(v) || v
    end
    def item_type=(v)
      @item_type = ITEM_TYPE.resolve(v) || v
    end

    def initialize(
      id: "",
      owner_id: "",
      made_in: 0,
      width: 0,
      height: 0,
      depth: 0,
      weight: 0,
      is_usbc: false,
      pos: nil,
      is_umbrella: false,
      monetary_value: 0.0,
      item_type: 0
    )
      @id = id
      @owner_id = owner_id
      @made_in = COUNTRY.resolve(made_in) || made_in
      @width = width
      @height = height
      @depth = depth
      @weight = weight
      @is_usbc = is_usbc
      @pos = pos
      @is_umbrella = is_umbrella
      @monetary_value = monetary_value
      @item_type = ITEM_TYPE.resolve(item_type) || item_type
    end

    def decode_from(buff, index, len)
      @id = ""
      @owner_id = ""
      @made_in = 0
      @width = 0
      @height = 0
      @depth = 0
      @weight = 0
      @is_usbc = false
      @pos = nil
      @is_umbrella = false
      @monetary_value = 0.0
      @item_type = 0

      tag = buff.getbyte(index)
      index += 1

      while true
        if tag == 0xa
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @id = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x12
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @owner_id = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x18
          ## PULL_INT64
          @made_in =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              # Negative 32 bit integers are still encoded with 10 bytes
              # handle 2's complement negative numbers
              # If the top bit is 1, then it must be negative.
              -(
                (
                  (
                    ~(
                      (byte9 << 63) | ((byte8 & 0x7F) << 56) |
                        ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                        ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                        ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                        ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
                    )
                  ) & 0xFFFF_FFFF_FFFF_FFFF
                ) + 1
              )
            else
              raise "integer decoding error"
            end

          ## END PULL_INT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x20
          ## PULL_UINT64
          @width =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x28
          ## PULL_UINT64
          @height =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x30
          ## PULL_UINT64
          @depth =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x38
          ## PULL_UINT64
          @weight =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x40
          ## PULL BOOLEAN
          @is_usbc = (buff.getbyte(index) == 1)
          index += 1
          ## END PULL BOOLEAN

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x4a
          ## PULL_MESSAGE
          ## PULL_UINT64
          msg_len =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          @pos = Position.allocate.decode_from(buff, index, index += msg_len)
          ## END PULL_MESSAGE

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x50
          ## PULL BOOLEAN
          @is_umbrella = (buff.getbyte(index) == 1)
          index += 1
          ## END PULL BOOLEAN

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x59
          @monetary_value = buff.unpack1("D", offset: index)
          index += 8

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x60
          ## PULL_INT64
          @item_type =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              # Negative 32 bit integers are still encoded with 10 bytes
              # handle 2's complement negative numbers
              # If the top bit is 1, then it must be negative.
              -(
                (
                  (
                    ~(
                      (byte9 << 63) | ((byte8 & 0x7F) << 56) |
                        ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                        ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                        ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                        ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
                    )
                  ) & 0xFFFF_FFFF_FFFF_FFFF
                ) + 1
              )
            else
              raise "integer decoding error"
            end

          ## END PULL_INT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end

        return self if index >= len
      end
    end
    def _encode(buff)
      val = @id
      if ((len = val.bytesize) > 0)
        buff << 0x0a
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @owner_id
      if ((len = val.bytesize) > 0)
        buff << 0x12
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @made_in
      if val != 0
        buff << 0x18

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @width
      if val != 0
        buff << 0x20

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @height
      if val != 0
        buff << 0x28

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @depth
      if val != 0
        buff << 0x30

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @weight
      if val != 0
        buff << 0x38

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @is_usbc
      if val == true
        buff << 0x40

        buff << 1
      elsif val == false
        # Default value, encode nothing
      else
        raise "bool values should be true or false"
      end

      val = @pos
      if val
        encoded = val._encode("".b)
        buff << 0x4a
        len = encoded.bytesize
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << encoded
      end

      val = @is_umbrella
      if val == true
        buff << 0x50

        buff << 1
      elsif val == false
        # Default value, encode nothing
      else
        raise "bool values should be true or false"
      end

      val = @monetary_value
      if val != 0
        buff << 0x59

        buff << [val].pack("D")
      end

      val = @item_type
      if val != 0
        buff << 0x60

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      buff
    end
    def to_h
      result = {}
      result["id".to_sym] = @id
      result["owner_id".to_sym] = @owner_id
      result["made_in".to_sym] = @made_in
      result["width".to_sym] = @width
      result["height".to_sym] = @height
      result["depth".to_sym] = @depth
      result["weight".to_sym] = @weight
      result["is_usbc".to_sym] = @is_usbc
      result["pos".to_sym] = @pos.to_h
      result["is_umbrella".to_sym] = @is_umbrella
      result["monetary_value".to_sym] = @monetary_value
      result["item_type".to_sym] = @item_type
      result
    end
  end
  class Vehicle
    def self.decode(buff)
      buff = buff.b
      allocate.decode_from(buff, 0, buff.bytesize)
    end

    def self.encode(obj)
      buff = obj._encode "".b
      buff.force_encoding(Encoding::ASCII_8BIT)
    end
    module VEHICLE_TYPE
      CAR = 0
      SPORTS_CAR = 1
      SUV = 2
      PICKUP_TRUCK = 3
      MINIVAN = 4
      MOTORCYCLE = 5
      def self.lookup(val)
        if val == 0
          :CAR
        elsif val == 1
          :SPORTS_CAR
        elsif val == 2
          :SUV
        elsif val == 3
          :PICKUP_TRUCK
        elsif val == 4
          :MINIVAN
        elsif val == 5
          :MOTORCYCLE
        end
      end
      def self.resolve(val)
        if val == :CAR
          0
        elsif val == :SPORTS_CAR
          1
        elsif val == :SUV
          2
        elsif val == :PICKUP_TRUCK
          3
        elsif val == :MINIVAN
          4
        elsif val == :MOTORCYCLE
          5
        end
      end
    end
    # required field readers
    attr_accessor :id,
                  :make,
                  :model,
                  :owner_id,
                  :year,
                  :is_electric,
                  :num_doors,
                  :num_wheels,
                  :num_windows,
                  :wheel_size,
                  :dry_weight,
                  :trunk_volume,
                  :monetary_value,
                  :trunk_items,
                  :is_manual

    # enum readers
    def type
      VEHICLE_TYPE.lookup(@type) || @type
    end
    # enum writers
    def type=(v)
      @type = VEHICLE_TYPE.resolve(v) || v
    end

    def initialize(
      id: 0,
      make: "",
      model: "",
      owner_id: 0,
      year: 0,
      type: 0,
      is_electric: false,
      num_doors: 0,
      num_wheels: 0,
      num_windows: 0,
      wheel_size: 0,
      dry_weight: 0,
      trunk_volume: 0,
      monetary_value: 0.0,
      trunk_items: [],
      is_manual: false
    )
      @id = id
      @make = make
      @model = model
      @owner_id = owner_id
      @year = year
      @type = VEHICLE_TYPE.resolve(type) || type
      @is_electric = is_electric
      @num_doors = num_doors
      @num_wheels = num_wheels
      @num_windows = num_windows
      @wheel_size = wheel_size
      @dry_weight = dry_weight
      @trunk_volume = trunk_volume
      @monetary_value = monetary_value
      @trunk_items = trunk_items
      @is_manual = is_manual
    end

    def decode_from(buff, index, len)
      @id = 0
      @make = ""
      @model = ""
      @owner_id = 0
      @year = 0
      @type = 0
      @is_electric = false
      @num_doors = 0
      @num_wheels = 0
      @num_windows = 0
      @wheel_size = 0
      @dry_weight = 0
      @trunk_volume = 0
      @monetary_value = 0.0
      @trunk_items = []
      @is_manual = false

      tag = buff.getbyte(index)
      index += 1

      while true
        if tag == 0x8
          ## PULL_UINT64
          @id =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x12
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @make = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x1a
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @model = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x20
          ## PULL_UINT64
          @owner_id =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x28
          ## PULL_UINT64
          @year =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x30
          ## PULL_INT64
          @type =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              # Negative 32 bit integers are still encoded with 10 bytes
              # handle 2's complement negative numbers
              # If the top bit is 1, then it must be negative.
              -(
                (
                  (
                    ~(
                      (byte9 << 63) | ((byte8 & 0x7F) << 56) |
                        ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                        ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                        ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                        ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
                    )
                  ) & 0xFFFF_FFFF_FFFF_FFFF
                ) + 1
              )
            else
              raise "integer decoding error"
            end

          ## END PULL_INT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x38
          ## PULL BOOLEAN
          @is_electric = (buff.getbyte(index) == 1)
          index += 1
          ## END PULL BOOLEAN

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x40
          ## PULL_UINT64
          @num_doors =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x48
          ## PULL_UINT64
          @num_wheels =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x50
          ## PULL_UINT64
          @num_windows =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x58
          ## PULL_UINT64
          @wheel_size =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x60
          ## PULL_UINT64
          @dry_weight =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x68
          ## PULL_UINT64
          @trunk_volume =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x71
          @monetary_value = buff.unpack1("D", offset: index)
          index += 8

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x7a
          ## DECODE REPEATED
          list = @trunk_items
          while true
            ## PULL_MESSAGE
            ## PULL_UINT64
            msg_len =
              if (byte0 = buff.getbyte(index)) < 0x80
                index += 1
                byte0
              elsif (byte1 = buff.getbyte(index + 1)) < 0x80
                index += 2
                (byte1 << 7) | (byte0 & 0x7F)
              elsif (byte2 = buff.getbyte(index + 2)) < 0x80
                index += 3
                (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte3 = buff.getbyte(index + 3)) < 0x80
                index += 4
                (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte4 = buff.getbyte(index + 4)) < 0x80
                index += 5
                (byte4 << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte5 = buff.getbyte(index + 5)) < 0x80
                index += 6
                (byte5 << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte6 = buff.getbyte(index + 6)) < 0x80
                index += 7
                (byte6 << 42) | ((byte5 & 0x7F) << 35) |
                  ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte7 = buff.getbyte(index + 7)) < 0x80
                index += 8
                (byte7 << 49) | ((byte6 & 0x7F) << 42) |
                  ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte8 = buff.getbyte(index + 8)) < 0x80
                index += 9
                (byte8 << 56) | ((byte7 & 0x7F) << 49) |
                  ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                  ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte9 = buff.getbyte(index + 9)) < 0x80
                index += 10

                (byte9 << 63) | ((byte8 & 0x7F) << 56) |
                  ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                  ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              else
                raise "integer decoding error"
              end

            ## END PULL_UINT64

            list << TrunkItem.allocate.decode_from(
              buff,
              index,
              index += msg_len
            )
            ## END PULL_MESSAGE

            tag = buff.getbyte(index)
            index += 1

            break unless tag == 0x7a
          end
          ## END DECODE REPEATED

          return self if index >= len
        end
        if tag == 0x80
          ## PULL BOOLEAN
          @is_manual = (buff.getbyte(index) == 1)
          index += 1
          ## END PULL BOOLEAN

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end

        return self if index >= len
      end
    end
    def _encode(buff)
      val = @id
      if val != 0
        buff << 0x08

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @make
      if ((len = val.bytesize) > 0)
        buff << 0x12
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @model
      if ((len = val.bytesize) > 0)
        buff << 0x1a
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @owner_id
      if val != 0
        buff << 0x20

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @year
      if val != 0
        buff << 0x28

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @type
      if val != 0
        buff << 0x30

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @is_electric
      if val == true
        buff << 0x38

        buff << 1
      elsif val == false
        # Default value, encode nothing
      else
        raise "bool values should be true or false"
      end

      val = @num_doors
      if val != 0
        buff << 0x40

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_wheels
      if val != 0
        buff << 0x48

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_windows
      if val != 0
        buff << 0x50

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @wheel_size
      if val != 0
        buff << 0x58

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @dry_weight
      if val != 0
        buff << 0x60

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @trunk_volume
      if val != 0
        buff << 0x68

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @monetary_value
      if val != 0
        buff << 0x71

        buff << [val].pack("D")
      end

      list = @trunk_items
      if list.size > 0
        list.each do |item|
          val = item
          if val
            encoded = val._encode("".b)
            buff << 0x7a
            len = encoded.bytesize
            while len != 0
              byte = len & 0x7F
              len >>= 7
              byte |= 0x80 if len > 0
              buff << byte
            end

            buff << encoded
          end
        end
      end

      val = @is_manual
      if val == true
        buff << 0x80

        buff << 1
      elsif val == false
        # Default value, encode nothing
      else
        raise "bool values should be true or false"
      end

      buff
    end
    def to_h
      result = {}
      result["id".to_sym] = @id
      result["make".to_sym] = @make
      result["model".to_sym] = @model
      result["owner_id".to_sym] = @owner_id
      result["year".to_sym] = @year
      result["type".to_sym] = @type
      result["is_electric".to_sym] = @is_electric
      result["num_doors".to_sym] = @num_doors
      result["num_wheels".to_sym] = @num_wheels
      result["num_windows".to_sym] = @num_windows
      result["wheel_size".to_sym] = @wheel_size
      result["dry_weight".to_sym] = @dry_weight
      result["trunk_volume".to_sym] = @trunk_volume
      result["monetary_value".to_sym] = @monetary_value
      result["trunk_items".to_sym] = @trunk_items
      result["is_manual".to_sym] = @is_manual
      result
    end
  end
  class ParkingSpace
    def self.decode(buff)
      buff = buff.b
      allocate.decode_from(buff, 0, buff.bytesize)
    end

    def self.encode(obj)
      buff = obj._encode "".b
      buff.force_encoding(Encoding::ASCII_8BIT)
    end
    NONE = Object.new
    private_constant :NONE

    # required field readers
    attr_accessor :pos, :has_electric_charger, :handicapped

    # optional field readers
    attr_reader :vehicle

    # BEGIN writers for optional fields
    def vehicle=(v)
      @_bitmask |= 0x0000000000000001
      @vehicle = v
    end
    # END writers for optional fields

    def initialize(
      pos: nil,
      has_electric_charger: false,
      handicapped: false,
      vehicle: NONE
    )
      @_bitmask = 0
      @pos = pos
      @has_electric_charger = has_electric_charger
      @handicapped = handicapped
      if vehicle == NONE
        @vehicle = nil
      else
        @_bitmask |= 0x0000000000000001
        @vehicle = vehicle
      end
    end

    def has_vehicle?
      (@_bitmask & 0x0000000000000001) == 0x0000000000000001
    end

    def decode_from(buff, index, len)
      @_bitmask = 0

      @pos = nil
      @has_electric_charger = false
      @handicapped = false
      @vehicle = nil

      tag = buff.getbyte(index)
      index += 1

      while true
        if tag == 0xa
          ## PULL_MESSAGE
          ## PULL_UINT64
          msg_len =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          @pos = Position.allocate.decode_from(buff, index, index += msg_len)
          ## END PULL_MESSAGE

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x10
          ## PULL BOOLEAN
          @has_electric_charger = (buff.getbyte(index) == 1)
          index += 1
          ## END PULL BOOLEAN

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x18
          ## PULL BOOLEAN
          @handicapped = (buff.getbyte(index) == 1)
          index += 1
          ## END PULL BOOLEAN

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x22
          ## PULL_MESSAGE
          ## PULL_UINT64
          msg_len =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          @vehicle = Vehicle.allocate.decode_from(buff, index, index += msg_len)
          ## END PULL_MESSAGE

          @_bitmask |= 0x0000000000000001
          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end

        return self if index >= len
      end
    end
    def _encode(buff)
      val = @pos
      if val
        encoded = val._encode("".b)
        buff << 0x0a
        len = encoded.bytesize
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << encoded
      end

      val = @has_electric_charger
      if val == true
        buff << 0x10

        buff << 1
      elsif val == false
        # Default value, encode nothing
      else
        raise "bool values should be true or false"
      end

      val = @handicapped
      if val == true
        buff << 0x18

        buff << 1
      elsif val == false
        # Default value, encode nothing
      else
        raise "bool values should be true or false"
      end

      val = @vehicle
      if val
        encoded = val._encode("".b)
        buff << 0x22
        len = encoded.bytesize
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << encoded
      end

      buff
    end
    def to_h
      result = {}
      result["pos".to_sym] = @pos.to_h
      result["has_electric_charger".to_sym] = @has_electric_charger
      result["handicapped".to_sym] = @handicapped
      result["vehicle".to_sym] = @vehicle.to_h
      result
    end
  end
  class ParkingFloor
    def self.decode(buff)
      buff = buff.b
      allocate.decode_from(buff, 0, buff.bytesize)
    end

    def self.encode(obj)
      buff = obj._encode "".b
      buff.force_encoding(Encoding::ASCII_8BIT)
    end
    # required field readers
    attr_accessor :id,
                  :num_cameras,
                  :num_fire_exits,
                  :num_sprinklers,
                  :area_sqft,
                  :ceiling_height_inches,
                  :parking_spaces

    def initialize(
      id: 0,
      num_cameras: 0,
      num_fire_exits: 0,
      num_sprinklers: 0,
      area_sqft: 0.0,
      ceiling_height_inches: 0,
      parking_spaces: []
    )
      @id = id
      @num_cameras = num_cameras
      @num_fire_exits = num_fire_exits
      @num_sprinklers = num_sprinklers
      @area_sqft = area_sqft
      @ceiling_height_inches = ceiling_height_inches
      @parking_spaces = parking_spaces
    end

    def decode_from(buff, index, len)
      @id = 0
      @num_cameras = 0
      @num_fire_exits = 0
      @num_sprinklers = 0
      @area_sqft = 0.0
      @ceiling_height_inches = 0
      @parking_spaces = []

      tag = buff.getbyte(index)
      index += 1

      while true
        if tag == 0x8
          ## PULL_UINT64
          @id =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x20
          ## PULL_UINT64
          @num_cameras =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x28
          ## PULL_UINT64
          @num_fire_exits =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x30
          ## PULL_UINT64
          @num_sprinklers =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x39
          @area_sqft = buff.unpack1("D", offset: index)
          index += 8

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x40
          ## PULL_UINT64
          @ceiling_height_inches =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x4a
          ## DECODE REPEATED
          list = @parking_spaces
          while true
            ## PULL_MESSAGE
            ## PULL_UINT64
            msg_len =
              if (byte0 = buff.getbyte(index)) < 0x80
                index += 1
                byte0
              elsif (byte1 = buff.getbyte(index + 1)) < 0x80
                index += 2
                (byte1 << 7) | (byte0 & 0x7F)
              elsif (byte2 = buff.getbyte(index + 2)) < 0x80
                index += 3
                (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte3 = buff.getbyte(index + 3)) < 0x80
                index += 4
                (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte4 = buff.getbyte(index + 4)) < 0x80
                index += 5
                (byte4 << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte5 = buff.getbyte(index + 5)) < 0x80
                index += 6
                (byte5 << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte6 = buff.getbyte(index + 6)) < 0x80
                index += 7
                (byte6 << 42) | ((byte5 & 0x7F) << 35) |
                  ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte7 = buff.getbyte(index + 7)) < 0x80
                index += 8
                (byte7 << 49) | ((byte6 & 0x7F) << 42) |
                  ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte8 = buff.getbyte(index + 8)) < 0x80
                index += 9
                (byte8 << 56) | ((byte7 & 0x7F) << 49) |
                  ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                  ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte9 = buff.getbyte(index + 9)) < 0x80
                index += 10

                (byte9 << 63) | ((byte8 & 0x7F) << 56) |
                  ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                  ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              else
                raise "integer decoding error"
              end

            ## END PULL_UINT64

            list << ParkingSpace.allocate.decode_from(
              buff,
              index,
              index += msg_len
            )
            ## END PULL_MESSAGE

            tag = buff.getbyte(index)
            index += 1

            break unless tag == 0x4a
          end
          ## END DECODE REPEATED

          return self if index >= len
        end

        return self if index >= len
      end
    end
    def _encode(buff)
      val = @id
      if val != 0
        buff << 0x08

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_cameras
      if val != 0
        buff << 0x20

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_fire_exits
      if val != 0
        buff << 0x28

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_sprinklers
      if val != 0
        buff << 0x30

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @area_sqft
      if val != 0
        buff << 0x39

        buff << [val].pack("D")
      end

      val = @ceiling_height_inches
      if val != 0
        buff << 0x40

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      list = @parking_spaces
      if list.size > 0
        list.each do |item|
          val = item
          if val
            encoded = val._encode("".b)
            buff << 0x4a
            len = encoded.bytesize
            while len != 0
              byte = len & 0x7F
              len >>= 7
              byte |= 0x80 if len > 0
              buff << byte
            end

            buff << encoded
          end
        end
      end

      buff
    end
    def to_h
      result = {}
      result["id".to_sym] = @id
      result["num_cameras".to_sym] = @num_cameras
      result["num_fire_exits".to_sym] = @num_fire_exits
      result["num_sprinklers".to_sym] = @num_sprinklers
      result["area_sqft".to_sym] = @area_sqft
      result["ceiling_height_inches".to_sym] = @ceiling_height_inches
      result["parking_spaces".to_sym] = @parking_spaces
      result
    end
  end
  class ParkingLot
    def self.decode(buff)
      buff = buff.b
      allocate.decode_from(buff, 0, buff.bytesize)
    end

    def self.encode(obj)
      buff = obj._encode "".b
      buff.force_encoding(Encoding::ASCII_8BIT)
    end
    # required field readers
    attr_accessor :name,
                  :district,
                  :phone_number,
                  :id,
                  :num_floors,
                  :num_entrances,
                  :num_attendants,
                  :floors

    def initialize(
      name: "",
      district: "",
      phone_number: "",
      id: 0,
      num_floors: 0,
      num_entrances: 0,
      num_attendants: 0,
      floors: []
    )
      @name = name
      @district = district
      @phone_number = phone_number
      @id = id
      @num_floors = num_floors
      @num_entrances = num_entrances
      @num_attendants = num_attendants
      @floors = floors
    end

    def decode_from(buff, index, len)
      @name = ""
      @district = ""
      @phone_number = ""
      @id = 0
      @num_floors = 0
      @num_entrances = 0
      @num_attendants = 0
      @floors = []

      tag = buff.getbyte(index)
      index += 1

      while true
        if tag == 0xa
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @name = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x12
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @district = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x1a
          ## PULL_STRING
          value =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          @phone_number = buff.byteslice(index, value)
          index += value

          ## END PULL_STRING

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x20
          ## PULL_UINT64
          @id =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x28
          ## PULL_UINT64
          @num_floors =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x30
          ## PULL_UINT64
          @num_entrances =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x38
          ## PULL_UINT64
          @num_attendants =
            if (byte0 = buff.getbyte(index)) < 0x80
              index += 1
              byte0
            elsif (byte1 = buff.getbyte(index + 1)) < 0x80
              index += 2
              (byte1 << 7) | (byte0 & 0x7F)
            elsif (byte2 = buff.getbyte(index + 2)) < 0x80
              index += 3
              (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte3 = buff.getbyte(index + 3)) < 0x80
              index += 4
              (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                (byte0 & 0x7F)
            elsif (byte4 = buff.getbyte(index + 4)) < 0x80
              index += 5
              (byte4 << 28) | ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte5 = buff.getbyte(index + 5)) < 0x80
              index += 6
              (byte5 << 35) | ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte6 = buff.getbyte(index + 6)) < 0x80
              index += 7
              (byte6 << 42) | ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte7 = buff.getbyte(index + 7)) < 0x80
              index += 8
              (byte7 << 49) | ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte8 = buff.getbyte(index + 8)) < 0x80
              index += 9
              (byte8 << 56) | ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            elsif (byte9 = buff.getbyte(index + 9)) < 0x80
              index += 10

              (byte9 << 63) | ((byte8 & 0x7F) << 56) | ((byte7 & 0x7F) << 49) |
                ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
            else
              raise "integer decoding error"
            end

          ## END PULL_UINT64

          return self if index >= len
          tag = buff.getbyte(index)
          index += 1
        end
        if tag == 0x42
          ## DECODE REPEATED
          list = @floors
          while true
            ## PULL_MESSAGE
            ## PULL_UINT64
            msg_len =
              if (byte0 = buff.getbyte(index)) < 0x80
                index += 1
                byte0
              elsif (byte1 = buff.getbyte(index + 1)) < 0x80
                index += 2
                (byte1 << 7) | (byte0 & 0x7F)
              elsif (byte2 = buff.getbyte(index + 2)) < 0x80
                index += 3
                (byte2 << 14) | ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte3 = buff.getbyte(index + 3)) < 0x80
                index += 4
                (byte3 << 21) | ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte4 = buff.getbyte(index + 4)) < 0x80
                index += 5
                (byte4 << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte5 = buff.getbyte(index + 5)) < 0x80
                index += 6
                (byte5 << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte6 = buff.getbyte(index + 6)) < 0x80
                index += 7
                (byte6 << 42) | ((byte5 & 0x7F) << 35) |
                  ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte7 = buff.getbyte(index + 7)) < 0x80
                index += 8
                (byte7 << 49) | ((byte6 & 0x7F) << 42) |
                  ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              elsif (byte8 = buff.getbyte(index + 8)) < 0x80
                index += 9
                (byte8 << 56) | ((byte7 & 0x7F) << 49) |
                  ((byte6 & 0x7F) << 42) | ((byte5 & 0x7F) << 35) |
                  ((byte4 & 0x7F) << 28) | ((byte3 & 0x7F) << 21) |
                  ((byte2 & 0x7F) << 14) | ((byte1 & 0x7F) << 7) |
                  (byte0 & 0x7F)
              elsif (byte9 = buff.getbyte(index + 9)) < 0x80
                index += 10

                (byte9 << 63) | ((byte8 & 0x7F) << 56) |
                  ((byte7 & 0x7F) << 49) | ((byte6 & 0x7F) << 42) |
                  ((byte5 & 0x7F) << 35) | ((byte4 & 0x7F) << 28) |
                  ((byte3 & 0x7F) << 21) | ((byte2 & 0x7F) << 14) |
                  ((byte1 & 0x7F) << 7) | (byte0 & 0x7F)
              else
                raise "integer decoding error"
              end

            ## END PULL_UINT64

            list << ParkingFloor.allocate.decode_from(
              buff,
              index,
              index += msg_len
            )
            ## END PULL_MESSAGE

            tag = buff.getbyte(index)
            index += 1

            break unless tag == 0x42
          end
          ## END DECODE REPEATED

          return self if index >= len
        end

        return self if index >= len
      end
    end
    def _encode(buff)
      val = @name
      if ((len = val.bytesize) > 0)
        buff << 0x0a
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @district
      if ((len = val.bytesize) > 0)
        buff << 0x12
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @phone_number
      if ((len = val.bytesize) > 0)
        buff << 0x1a
        while len != 0
          byte = len & 0x7F
          len >>= 7
          byte |= 0x80 if len > 0
          buff << byte
        end

        buff << val
      end

      val = @id
      if val != 0
        buff << 0x20

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_floors
      if val != 0
        buff << 0x28

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_entrances
      if val != 0
        buff << 0x30

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      val = @num_attendants
      if val != 0
        buff << 0x38

        while val != 0
          byte = val & 0x7F
          val >>= 7
          byte |= 0x80 if val > 0
          buff << byte
        end
      end

      list = @floors
      if list.size > 0
        list.each do |item|
          val = item
          if val
            encoded = val._encode("".b)
            buff << 0x42
            len = encoded.bytesize
            while len != 0
              byte = len & 0x7F
              len >>= 7
              byte |= 0x80 if len > 0
              buff << byte
            end

            buff << encoded
          end
        end
      end

      buff
    end
    def to_h
      result = {}
      result["name".to_sym] = @name
      result["district".to_sym] = @district
      result["phone_number".to_sym] = @phone_number
      result["id".to_sym] = @id
      result["num_floors".to_sym] = @num_floors
      result["num_entrances".to_sym] = @num_entrances
      result["num_attendants".to_sym] = @num_attendants
      result["floors".to_sym] = @floors
      result
    end
  end
end
