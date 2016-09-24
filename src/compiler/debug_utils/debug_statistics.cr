module DbgStatistics
  @@total_types_allocated = 0

  def self.total_types_allocated_inc
    @@total_types_allocated += 1
  end

  def self.total_types_allocated
    @@total_types_allocated
  end

  @@total_unions_allocated = 0

  def self.total_unions_allocated_inc
    @@total_unions_allocated += 1
  end

  def self.total_unions_allocated
    @@total_unions_allocated
  end
end
