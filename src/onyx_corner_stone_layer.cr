def say(*objects)
  STDOUT.puts *objects
end

def dbg(*objects)
  ifdef !release
    STDERR.puts *objects
  end
end
