class Object
  ##
  #   @person.name unless @person.nil?
  # vs
  #   @person.try(:name)
  def try(method)
    self.send(method) unless self.nil?
  end
end
