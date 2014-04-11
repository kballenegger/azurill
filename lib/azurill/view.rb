
module Azurill

  class View

    attr_accessor :rect
    def initialize
      @rect = {x: 0, y: 0, w: 0, h: 0}
      @dirty = true
      @subviews = []
    end

    def dirty!
      @dirty = true
    end

    def add_subview(v)
      @subviews << v
    end

    def remove_subview(v)
      @subviews.delete(v)
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
