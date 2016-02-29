type BasicBlock
   @in-edges   = [] of BasicBlock 'get 'set
   @out-edges  = [] of BasicBlock 'get 'set

   init(@name) ->

   to-s(io) ->
      io << "BB#"
      io << @name
end

type BasicBlockEdge < value
   init(cfg, from-name, to-name) ->
      @from = cfg.create-node(from-name)
      @to = cfg.create-node(to-name)
      @from.out-edges << @to
      @to.in-edges << @from

   Type.add(cfg, from-name, to-name) ->
      edge = new(cfg, from-name, to-name)
      cfg.add-edge(edge)
end

type CFG
   @edge-list = [] of BasicBlockEdge
   @basic-block-map = {} of Int32 => BasicBlock 'get 'set
   @start-node = nil 'get 'set

   create-node(name) ->
      node = (@basic-block-map[name] ||= BasicBlock name)
      @start-node ||= node
      node

   add-edge(edge) ->
      @edge-list << edge

   get-num-nodes() ->
      @basic-block-map.size
end

type SimpleLoop
   @basic-blocks  = Set<BasicBlock>()
   @children      = Set<SimpleLoop>()
   @parent        = nil    'get 'set
   @header        = nil    'get 'set
   @is-root       = false  'get 'set
   @is-reducible  = true   'get 'set
   @counter       = 0      'get 'set
   @nesting-level = 0      'get 'set
   @depth-level   = 0      'get 'set

   add-node(bb) ->
      @basic-blocks.add(bb)

   add-child-loop(l) ->
      @children.add(l)

   set-parent(parent) ->
      @parent = parent
      parent.add-child-loop(self)

   set-header(bb) ->
      @basic-blocks.add(bb)
      @header = bb

   set-nesting-level(level) ->
      @nesting-level = level
      if level == 0
         @is-root = true
end

$loop-counter = 0

type LSG
   init() ->
      @loops = [] of SimpleLoop
      @root = create-new-loop
      @root.set-nesting-level(0)
      add-loop(@root)

   create-new-loop() ->
      s = SimpleLoop()
      s.counter = $loop-counter = $loop-counter + 1
      s

   add-loop(l) ->
      @loops << l

   calculate-nesting-level() ->
      @loops.each (liter) ~>
         if !liter.is-root and liter.parent == nil
            liter.set-parent(@root)

      calculate-nesting-level-rec(@root, 0)

   calculate-nesting-level-rec(l, depth) ->
      l.depth-level = depth
      l.children.each (liter) ~>
         calculate-nesting-level-rec(liter, depth + 1)
         l.set-nesting-level(Math.max(l.nesting-level, 1 + liter.nesting-level))

   get-num-loops() ->
      @loops.size
end

type UnionFindNode
   @parent     = nil 'get 'set
   @bb         = nil 'get 'set
   @l          = nil 'get 'set
   @dfs-number = 0   'get 'set

   init-node(bb, dfs-number) ->
      @parent = self
      @bb = bb
      @dfs-number = dfs-number

   find-set() ->
      node-list = [] of UnionFindNode
      node = self
      while node isnt node.parent
         parent = node.parent.not-nil!
         if parent isnt parent.parent
            node-list << node
         end
         node = parent
      end
      node-list.each(~.parent = node.parent)
      node

   union(union-find-node) ->
      @parent = union-find-node
end

type HavlakLoopFinder
   BB_TOP            = 0
   BB_NONHEADER      = 1
   BB_REDUCIBLE      = 2
   BB_SELF           = 3
   BB_IRREDUCIBLE    = 4
   BB_DEAD           = 5
   BB_LAST           = 6

   UNVISITED         = -1

   MAXNONBACKPREDS   = 32 * 1024

   init(@cfg, @lsg) ->

   is-ancestor(w, v, last) ->
      w <= v <= last[w]

   dfs(current-node, nodes, number, last, current) ->
      nodes[current].init-node(current-node, current)
      number[current-node] = current
      lastid = current
      current-node.out-edges.each (target) ~>
         if number[target] is UNVISITED
            lastid = dfs(target, nodes, number, last, lastid + 1)

      last[number[current-node]] = lastid
      lastid

   find-loops() ->
      return 0 unless start-node = @cfg.start-node

      size = @cfg.get-num-nodes
      non-back-preds = List size, ~> Set<Int32>()
      back-preds = List size, ~> List<Int32>()

      number = {} of BasicBlock => Int32
      header = List size, 0
      types = List size, 0
      last = List size, 0
      nodes = List size, ~> UnionFindNode()

      @cfg.basic-block-map.each-value (v) ~>
         number[v] = UNVISITED

      dfs(start-node, nodes, number, last, 0)
      size.times (w) ~>
         header[w] = 0
         types[w] = BB_NONHEADER
         node-w = (nodes[w]).bb
         if node-w
            node-w.in-edges.each (node-v) ~>
               v = number[node-v]
               unless v is UNVISITED
                  if is-ancestor(w, v, last)
                     (back-preds[w]) << v
                  else
                     (non-back-preds[w]).add(v)
                  end
               end

         else
            types[w] = BB_DEAD
         end

      header.0 = 0
      (size - 1).downto(0, (w) ~>
         node-pool = [] of UnionFindNode
         node-w = (nodes[w]).bb
         if node-w
            (back-preds[w]).each (v) ~>
               if v != w
                  node-pool << (nodes[v]).find-set
               else
                  types[w] = BB_SELF
               end

            work-list = node-pool.dup
            if node-pool.size != 0
               types[w] = BB_REDUCIBLE
            end
            while !work-list.empty?
               x = work-list.shift
               non-back-size = (non-back-preds[x.dfs-number]).size
               if non-back-size > MAXNONBACKPREDS
                  return 0
               end
               (non-back-preds[x.dfs-number]).each (iter) ~>
                  y = nodes[iter]
                  ydash = y.find-set
                  if !(is-ancestor(w, ydash.dfs-number, last))
                     types[w] = BB_IRREDUCIBLE
                     (non-back-preds[w]).add(ydash.dfs-number)
                  else
                     if ydash.dfs-number != w and !(node-pool.includes?(ydash))
                        work-list << ydash
                        node-pool << ydash
                     end
                  end

            end
            if node-pool.size > 0 || (types[w]) == BB_SELF
               l = @lsg.create-new-loop
               l.set-header(node-w)
               l.is-reducible = (types[w]) != BB_IRREDUCIBLE
               (nodes[w]).l = l
               node-pool.each (node) ~>
                  header[node.dfs-number] = w
                  node.union(nodes[w])
                  if node-l = node.l
                     node-l.set-parent(l)
                  else
                     l.add-node(node.bb.not-nil!)
                  end

               @lsg.add-loop(l)
            end
         end
      )
      @lsg.get-num-loops
end

build-diamond(start) ->
   bb0 = start
   BasicBlockEdge.add($cfg, bb0, bb0 + 1)
   BasicBlockEdge.add($cfg, bb0, bb0 + 2)
   BasicBlockEdge.add($cfg, bb0 + 1, bb0 + 3)
   BasicBlockEdge.add($cfg, bb0 + 2, bb0 + 3)
   bb0 + 3

build-connect(_start, _end) ->
   BasicBlockEdge.add($cfg, _start, _end)

build-straight(start, n) ->
   n.times (i) ~>
      build-connect(start + i, (start + i) + 1)
   start + n

build-base-loop(from) ->
   header = build-straight(from, 1)
   diamond1 = build-diamond(header)
   d11 = build-straight(diamond1, 1)
   diamond2 = build-diamond(d11)
   footer = build-straight(diamond2, 1)
   build-connect(diamond2, d11)
   build-connect(diamond1, header)
   build-connect(footer, from)
   build-straight(footer, 1)


say "Welcome to LoopTesterApp, Onyx Edition"
say "Constructing Simple CFG..."

$cfg = CFG()
$cfg.create-node(0)
build-base-loop(0)
$cfg.create-node(1)
build-connect(0, 2)
say "15000 dummy loops"
15000.times ~>
   (HavlakLoopFinder $cfg, LSG()).find-loops

say "Constructing CFG..."
n = 2
10.times ~>
   $cfg.create-node(n + 1)
   build-connect(2, n + 1)
   n = n + 1
   100.times ~>
      top = n
      n = build-straight(n, 1)
      25.times ~>
         n = build-base-loop(n)

      bottom = build-straight(n, 1)
      build-connect(n, top)
      n = bottom

   build-connect(n, 1)

say "Performing Loop Recognition\n1 Iteration"
loops = (HavlakLoopFinder $cfg, LSG()).find-loops
say "Another 50 iterations..."
sum = 0
50.times ~>
   print(".")
   sum = sum + (HavlakLoopFinder $cfg, LSG()).find-loops

say "\nFound {loops} loops (including artificial root node) ({sum})\n"
