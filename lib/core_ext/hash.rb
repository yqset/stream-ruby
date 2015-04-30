class Hash
  ##
  # Example:
  #   { "x" => 1, "y" => 2, "z" => 3 }.hmap { |k,v| [k, v * 2] }
  #     => {
  #          "x" => 2,
  #          "y" => 4,
  #          "z" => 6
  #        }
  def hmap(&block)
    Hash[self.map {|k, v| block.call(k,v) }]
  end
end
