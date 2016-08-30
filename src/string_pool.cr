# A string pool is a collection of strings.
# It allows a runtime to save memory by preserving strings in a pool, allowing to
# reuse an instance of a common string instead of creating a new one.
#
# ```
# require "string_pool"
# pool = StringPool.new
# a = "foo" + "bar"
# b = "foo" + "bar"
# a.object_id # => 136294360
# b.object_id # => 136294336
# a = pool.get(a)
# b = pool.get(b)
# a.object_id # => 136294312
# b.object_id # => 136294312
# ```
class StringPool
  # Returns the size
  #
  # ```
  # pool = StringPool.new
  # pool.size # => 0
  # ```
  getter size : Int32
  @bucket_power : Int32
  @bucket_mask : Int32 = 0

  # Creates a new empty string pool.
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

  # Returns `true` if the String Pool has no element otherwise returns `false`.
  #
  # ```
  # pool = StringPool.new
  # pool.empty? # => true
  # pool.get("crystal")
  # pool.empty? # => false
  # ```
  def empty?
    @size == 0
  end

  # Returns a string with the contents of the given slice.
  #
  # If a string with those contents was already present in the pool, that one is returned.
  # Otherwise a new string is created, put in the pool and returned.
  #
  # ```
  # pool = StringPool.new
  # ptr = Pointer.malloc(9) { |i| ('a'.ord + i).to_u8 }
  # slice = Slice.new(ptr, 3)
  # pool.empty? # => true
  # pool.get(slice)
  # pool.empty? # => false
  #  ```
  def get(slice : Slice(UInt8))
    get slice.pointer(slice.size), slice.size
  end

  # Returns a string with the contents given by the pointer *str* of size *len*.
  #
  # If a string with those contents was already present in the pool, that one is returned.
  # Otherwise a new string is created, put in the pool and returned.
  #
  # ```
  # pool = StringPool.new
  # pool.get("hey".to_unsafe, 3)
  # pool.size # => 1
  # ```
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

  # Returns a string with the contents of the given `MemoryIO`.
  #
  # If a string with those contents was already present in the pool, that one is returned.
  # Otherwise a new string is created, put in the pool and returned
  #
  # ```
  # pool = StringPool.new
  # io = MemoryIO.new "crystal"
  # pool.empty? # => true
  # pool.get(io)
  # pool.empty? # => false
  # ```
  def get(str : MemoryIO)
    get(str.buffer, str.bytesize)
  end


  # Returns a string with the contents of all the given strings concatinated..
  # No actual concat is done, which saves unnecessary temporary allocations.
  #
  # If a string with those contents was already present in the pool, that one is returned.
  # Otherwise a new string is created, put in the pool and returned
  #
  # ```
  # pool = StringPool.new
  # string = "crystal"
  # pool.empty? # => true
  # pool.get(string)
  # pool.empty? # => false
  # ```
  def get(*string_parts : String)
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

    bucket = @buckets.unsafe_at(bucket_ix)

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

  # Rebuilds the hash based on the current hash values for each key,
  # if values of key objects have changed since they were inserted.
  #
  # Call this method if you modified a string submitted to the pool.
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
