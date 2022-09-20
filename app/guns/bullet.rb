class Bullet < AdvancedProjectile

  SIZE = 10
  ANGLE_OFFSET = -45
  LIFE_TIME = 2 * 60

  HIT_TYPE_DESTROY = 0
  HIT_TYPE_BOUNCE = 1
  HIT_TYPE_STICK = 2

  DMG_TICK = 10

  def initialize(x, y, x_speed, y_speed, hit_type, gravity, damage, speed, crit_chance, max_crit)
    @speed = speed
    super(x, y, x_speed * @speed, y_speed * @speed, SIZE, SIZE, @drawable)
    @has_hit = false
    @last_angle = 0
    @life_time = LIFE_TIME
    @total_lifetime = LIFE_TIME
    @hit_type = hit_type
    @gravity = gravity
    @damage = damage.ceil
    @crit_chance = crit_chance
    @max_crit = max_crit
    @dmg_service = nil

    case @hit_type
    when HIT_TYPE_DESTROY
      sprite = '/sprites/bullet_long.png'
    when HIT_TYPE_BOUNCE
      sprite = '/sprites/bullet_round.png'
    when HIT_TYPE_STICK
      sprite = '/sprites/arrow_flame.png'
    end

    @drawable = Sprite.new(SIZE,SIZE, sprite, 0, 16, 16, 5, 5)
  end

  def simulate(tick_count)
    @y_speed += @gravity unless @is_riding
    super(tick_count)

    @total_lifetime -= 1
    if @total_lifetime <= 0
      unless @dmg_service.nil?
        @dmg_service.destroy
      end
      destroy
    end

    if @has_hit
      @life_time -= 1
      if @life_time <= 0
        unless @dmg_service.nil?
          @dmg_service.destroy
        end
        destroy
      end
    end

    if !@has_hit or @hit_type == HIT_TYPE_BOUNCE
      angle = Math.atan2(y_speed, x_speed)
      degrees = 180 * angle / 3.14
      degrees = (degrees + 360 + ANGLE_OFFSET) % 360

      @drawable.angle = degrees
      sin = Math.sin(angle)
      cos = Math.cos(angle)
      @drawable.offset_x = -25 - cos * 25
      @drawable.offset_y = -25 - sin * 25
      @last_angle = degrees
    end
  end

  def do_damage args
    crit = crit_damage
    args.collider.on_bullet_hit(@x, @y, (((@damage + crit) / DMG_TICK) * ((LIFE_TIME / 60) / DMG_TICK)).ceil, crit > 0)
  end

  def on_hit(collider, direction)
    if collider.respond_to?(:on_bullet_hit)
      crit = crit_damage
      collider.on_bullet_hit(@x, @y, @damage + crit, crit > 0)
    end
    unless @has_hit
      @total_lifetime = LIFE_TIME
    end
    @has_hit = true
    case @hit_type
    when HIT_TYPE_DESTROY
      destroy
    when HIT_TYPE_BOUNCE
      if direction == HORIZONTAL
        @x_speed *= -1
      else
        @y_speed *= -1
      end
    when HIT_TYPE_STICK
      @x_speed = 0
      @y_speed = 0
      if collider.respond_to?(:on_bullet_hit)
        @dmg_service = Service.new(1 / DMG_TICK, method(:do_damage), {collider: collider}, true)
      end
    end
  end

  def crit_damage
    r = rand(100) + 1
    if r <= @crit_chance
      return (@damage * (@max_crit / 100)).ceil
    end
    return 0
  end
end
