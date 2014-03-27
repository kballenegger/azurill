
module Azurill

  class View

    attr_accessor :rect
    def initialize(rect)
      @rect = rect
      @dirty = true
      @subviews = []
    end

    def dirty!
      @dirty = true
    end

    def add_subview(v)
      @subviews << v
    end

    def draw(&b)
      if block_given?
        @drawer = b
      else
        self.instance_exec(&@drawer) if @drawer && @dirty
        @subviews.each do |s|
          s.draw
        end
        @dirty = false
      end
    end

  end
end
