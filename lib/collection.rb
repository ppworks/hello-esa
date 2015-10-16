class Collection
  attr_accessor :data, :page, :per

  def initialize
    @data = []
    @page = 1
    @per  = 100
  end
end
