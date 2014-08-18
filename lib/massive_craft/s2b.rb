require "nbtfile"

#---
# MODIFIED by Sven (2called-chaos) Pachnit, mcl@sp-mg.de for use with MCL.
# Modifications are MIT licensed.
#---

# Massconverter from .schematic files to .bo2 files
# Usage: ruby s2b.rb
#        This will convert all schematics in the sibling folder "in".
#        The results will be placed in the folder "out".
#        Air and magenta colored wool is ignored.
#        If the file name is ending with R5 the z will use a -5 offset
#
# See: http://www.minecraftwiki.net/wiki/Schematic_File_Format
#      https://github.com/Wickth/TerrainControll/blob/master/bo2spec.txt
#
# Lisence: MIT
class SchematicBo2sConverter
  # Needy blocks are items like torches and doors, which require other blocks to
  # be in place -- otherwise they'll simply fall to the ground as entities. We
  # defer them to the end of the BOB output to ensure they're "built" last.
  NEEDY_BLOCKS = [6, 26, 27, 28, 31, 32, 37, 38, 39, 40, 50, 51, 55, 59, 63, 64, 65, 66, 68, 69, 70, 71, 72, 75, 76, 77, 78, 81, 83, 85, 90, 96, 104, 105, 106, 111, 115, 127]

  def self.convert srcio
    new(srcio).convert
  end

  def self.open srcio
    NBTFile.load(srcio)[1]
  end

  def initialize srcio
    @srcio = srcio
  end

  def convert
    schematic = NBTFile.load(@srcio)[1]
    {}.tap do |r|
      r[:dimensions] = [schematic["Width"], schematic["Height"], schematic["Length"]]
      r[:data]       = convert_nbt(schematic)
    end
  end

  def stringify_line(line_array)
    "#{line_array[0]},#{line_array[1]},#{line_array[2]}:#{line_array[3]}.#{line_array[4]}"
  end

  def convert_nbt schematic
    [].tap do |ret|
      # Slice blocks and block metadata by the size of the schematic's axes, then
      # zip the slices up into pairs of [id, metadata] for convenient consumption.
      blocks = schematic["Blocks"].bytes.each_slice(schematic["Width"]).to_a
      blocks = blocks.each_slice(schematic["Length"]).to_a
      data = schematic["Data"].bytes.each_slice(schematic["Width"]).to_a
      data = data.each_slice(schematic["Length"]).to_a
      layers = blocks.zip(data).map { |blocks, data| blocks.zip(data).map { |blocks, data| blocks.zip(data) } }
      deferred = []

      layers.each_with_index do |rows, z|
        rows.each_with_index do |columns, x|
          # x -= schematic["Width"] / 2 # Center the object on the X axis
          columns.each_with_index do |(block, data), y|
            next if block == 0
            # y -= schematic["Length"] / 2 # Center the object on the Y axis
            line = [y, x, z, block, data]
            if NEEDY_BLOCKS.include?(block)
              deferred << line
            else
              ret << stringify_line(line)
            end
          end
        end
      end

      # Write needy blocks to the end of the BOB file, respecting the order of
      # NEEDY_BLOCKS, in case some blocks are needier than others.
      deferred.sort! {|a, b| NEEDY_BLOCKS.index(a[3]) <=> NEEDY_BLOCKS.index(b[3]) }
      deferred.map {|line| stringify_line(line) }.reverse.each {|line| ret << line }
    end
  end
end
