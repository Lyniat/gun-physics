class DamagePopup < Effect

  DURATION = 1
  MAX_SIZE = 12

  def initialize(x, y, amount, is_critical)
    super(1, 1)
    @x = x + rand(50) - 25
    @y = y + rand(50) - 25
    @amount = amount.to_s
    @time = 0
    @is_critical = is_critical
    if is_critical
      @red = 255
    else
      @red = 155 - rand(100)
    end
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
      size_enum:               (@time / 60) * MAX_SIZE * (@is_critical? 2 : 1),
      alignment_enum:          1,
      r:                       @red,
      g:                       0,
      b:                       0,
      a:                       255
    }
  end
end
