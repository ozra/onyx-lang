require "../../crystal/syntax/transformer"

module Crystal
  class Transformer
    def transform(node : For)
      node.value_id = node.value_id.try &.transform(self)
      node.index_id = node.index_id.try &.transform(self)
      node.iterable = node.iterable.transform(self)
      node.stepping = node.stepping.try &.transform(self)
      node.body = node.body.transform(self)
      node
    end
  end
end
