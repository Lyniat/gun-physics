class DamagePopup < Effect

  DURATION = 1
  MAX_SIZE = 12

  def initialize(x, y, amount)
    super(1, 1)
    @x = x + rand(50) - 25
    @y = y + rand(50) - 25
    @amount = amount.to_s
    @time = 0
    @red = 255 - rand(100)
    Service.new(DURATION, method(:destroy), {}, false)
  end

  def simulate(tick_count)
    super
    @time += 1
  end

  def draw(tick_count)
    $args.outputs.labels << {
      x:                       @x - cam_x,
      y:                       @y - cam_y,
      text:                    @amount,
      size_enum:               (@time / 60) * MAX_SIZE,
      alignment_enum:          1,
      r:                       @red,
      g:                       0,
      b:                       0,
      a:                       255
    }
  end
end
