require "string"

class StringPool
  getter size : Int32
  @bucket_power : Int32
  @bucket_mask : Int32 = 0

  def initialize(initial_bucket_power = 14)
    @buckets = Array(Array(String)?).new(1 << initial_bucket_power, nil)
    @size = 0
    @bucket_power = initial_bucket_power - 1

    @bucket_mask = 0 # *TODO* WORKAROUND - should not be needed!

    calculate_new_size
    _dbg_on
    _dbg "StringPool.init - initial_bucket_power=#{initial_bucket_power}, size=#{2 << initial_bucket_power}, bucket_mask=#{@bucket_mask.to_s(2)}"
    # CallStack.print_backtrace

  end

  def empty?
    @size == 0
  end

  def get(slice : Slice(UInt8))
    get slice.pointer(slice.size), slice.size
  end

  def get(str : UInt8*, len)
    index = bucket_index str, len
    bucket = @buckets[index]

    if bucket
      entry = find_entry_in_bucket(bucket, str, len)
      if entry
        return entry
      end
    else
      @buckets[index] = bucket = Array(String).new
    end

    @size += 1
    entry = String.new(str, len)
    bucket.push entry
    rehash if @size > 5 * @buckets.size # avoid doing check every time
    entry
  end

  def get(str : MemoryIO)
    get(str.buffer, str.bytesize)
  end

  # def get(str : String)
  #   get(str.to_unsafe, str.bytesize)
  # end

  def get(*string_parts : String)
    # _dbg "get string_parts #{string_parts.size}"

    if OptTests.test_opt_mode_c == 2


    h = 0
    string_parts.each do |str|
      str_ptr = str.to_unsafe

      case str.bytesize
      when 1
        h = (31 * h) + str_ptr[0]
      # when 2
      #   h = (31 * h) + str_ptr[0]
      #   h = (31 * h) + str_ptr[1]
      # when 3
      #   h = (31 * h) + str_ptr[0]
      #   h = (31 * h) + str_ptr[1]
      #   h = (31 * h) + str_ptr[2]
      # when 4
      #   h = (31 * h) + str_ptr[0]
      #   h = (31 * h) + str_ptr[1]
      #   h = (31 * h) + str_ptr[2]
      #   h = (31 * h) + str_ptr[3]
      else
        size = str.bytesize
        h = (31 * h) + str_ptr[0]
        h = (31 * h) + str_ptr[size - 2]
        h = (31 * h) + str_ptr[1]
        h = (31 * h) + str_ptr[size - 1]
        h = (31 * h) + str_ptr[size >> 2]
      end

      # full, linear, hashing
      # str.to_slice.each do |c|
      #   h = (31 * h) + c
      # end

    end
    # end

    bucket_ix = h & @bucket_mask
    # _dbg "- get - calced bucket ix to #{bucket_ix}"

    bucket = @buckets.at_unsafe(bucket_ix) # *TODO* -> .at_unsafe()

    if bucket
      entry = find_entry_in_bucket(bucket, *string_parts)
      if entry
        return entry
      end
    else
      @buckets.set_unsafe(bucket_ix, bucket = Array(String).new(5))
    end

    @size += 1
    if string_parts.size == 1
      entry = string_parts.first

    else
      total_size = string_parts.sum {|str| str.size}

      entry = String.build total_size do |io|
        string_parts.each_with_index do |part, i|
          io << part
        end
      end

      _dbg "Adds entry: '#{entry}' to #{bucket}".white

    end

    bucket << entry
    rehash if @size > 2 * @buckets.size # avoid doing check every time
    return entry


    else
      total_size = 0
      string_parts.each do |str|
        total_size += str.size
      end
      full_str = String.build total_size do |io|
        string_parts.each do |part|
          io << part
        end
      end
      return get(full_str.to_unsafe, full_str.bytesize)
    end

  end

  # *TODO*
  # def dbg_coverage
  # count entries in buckets and list



  # *TODO* if we aim at having "near perfect" hashing, we should expect only one
  #   entry, thus memcmp'ing directly would be better - no tricks!

  private def find_entry_in_bucket(bucket, *string_parts : String)
    tot_len = 0
    string_parts.each do |str|
      tot_len += str.bytesize
    end

    # _dbg "- find_entry_in_bucket #{bucket} for string_parts (#{string_parts})".white
    found = false

    bucket.each do |entry|
      if entry.bytesize != tot_len
        # _dbg "entry and parts-total bytesize don't match #{entry.bytesize} vs #{tot_len}".red
        next
      # else
        # _dbg "entry and parts-total bytesize MATCH #{entry.bytesize} vs #{tot_len}".yellow
      end

      entry_lix = entry.size - 1
      # next if entry.unsafe_byte_at(entry_lix) != string_parts.last[-1]
      # next if entry[0] != string_parts[0][0]

      pos = 0
      entry_ptr = entry.to_unsafe
      found = true

      string_parts.each do |part|
        part_ptr = part.to_unsafe
        # part_lix = part.bytesize - 1
        # break if entry_ptr[part_lix] != part_ptr[part_lix]

        # if my_memeq_aligned(part.to_unsafe, entry_ptr, part_len)
        #   return entry
        # end
        if my_memeq_aligned(part_ptr, entry_ptr, part.bytesize) == false
          # _dbg "part_ptr and entry_ptr content don't match".yellow
          found = false
          break
        else
          # _dbg "part_ptr and entry_ptr content match".yellow
        end
        entry_ptr += part.bytesize
      end

      if found
        # _dbg "FOUND ENTRY! '#{entry}'".yellow
        return entry
      else
        # _dbg "FAILED ENTRY MATCH: #{entry_ptr} vs #{string_parts.last.to_unsafe + tot_len}".red
      end
    end

    # _dbg "FAILED FINDING ENTRY!".red
    nil
  end

  private def find_entry_in_bucket(bucket, str : Pointer, len : Int)
    bucket.each do |entry|
      if entry.size == len
        if str.memcmp(entry.to_unsafe, len) == 0
          return entry
        end
      end
    end
    nil
  end

  def rehash
    # new_size = calculate_new_size(@size)
    calculate_new_size
    old_buckets = @buckets
    @buckets = Array(Array(String)?).new((1 << @bucket_power), nil)
    @size = 0

    _dbg "REHASH buckets = #{(1 << @bucket_power) }!!!".red

    old_buckets.each do |bucket|
      bucket.try &.each do |entry|
        get(entry.to_unsafe, entry.size)
      end
    end
  end

  private def bucket_index(str, len)
    hash = hash(str, len)
    (hash % @buckets.size).to_i
  end

  private def hash(str, len)
    h = 0
    str.to_slice(len).each do |c|
      h = 31 * h + c
    end
    h
  end

  private def calculate_new_size #(size)
    @bucket_power += 1
    @bucket_mask = ((1 << @bucket_power) - 1)

    # new_size = 8
    # Hash::HASH_PRIMES.each do |hash_size|
    #   return hash_size if new_size > size
    #   new_size <<= 1
    # end
    # raise "Hash table too big"
  end
end
