class AdvancedProjectile < Actor
  attr_reader :x_speed, :y_speed

  HORIZONTAL = 0
  VERTICAL = 1

  def initialize(x, y, x_speed, y_speed, w, h, drawable)
    super(x, y, w, h, drawable)
    @x_speed = x_speed
    @y_speed = y_speed
  end

  def simulate(tick_count)
    move_x(@x_speed)
    move_y(@y_speed)

    solid = nil
    possible_solids = []
    possible_solids << solid_right?
    possible_solids << solid_left?
    possible_solids << solid_below?
    possible_solids << solid_above?

    possible_solids.each do |ps|
      next if ps == nil
      solid = ps
    end

    unless solid == nil
      solid.add_rider(self)
      @is_riding = true
    end
  end

  def on_collision_x(squish, collider)
    destroy if squish
    on_hit(collider, HORIZONTAL)
  end

  def on_collision_y(squish, collider)
    destroy if squish
    on_hit(collider, VERTICAL)
  end
end
