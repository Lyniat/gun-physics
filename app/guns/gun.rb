class Gun
  MAX_GRAVITY = 5
  MAX_PROJECTILES = 6
  def initialize
    @hit_type = 0
    @has_gravity = false
    @gravity = 0
    @has_spray = false
    @spray = 0
    @has_multiple_projectiles = false
    @projectiles = 1
    @damage = 0
    randomize
  end

  def draw(tick_count)
    case @hit_type
    when Bullet::HIT_TYPE_DESTROY
      s_type = "bullet"
    when Bullet::HIT_TYPE_BOUNCE
      s_type = "bounce"
    when Bullet::HIT_TYPE_STICK
      s_type = "arrow"
    end
    s_gravity = @gravity.ceil
    s_spray = @spray.ceil
    s_damage = @damage.ceil
    $args.outputs.labels << [0, HEIGHT - 260, "TYPE: #{s_type}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 280, "GRAVITY: #{s_gravity}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 300, "SPRAY: #{s_spray}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 320, "PROJECTILES: #{@projectiles}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 340, "DAMAGE: #{s_damage}", 0, 0, 255, 0, 0]
  end

  def fire(mid_x, mid_y, dir_x, dir_y)
    angle = Math.atan2(dir_y, dir_x)
    spray_angle = (rand(@spray) - @spray/2) / 3
    angle += spray_angle
    if !@has_multiple_projectiles
      sin = Math.sin(angle)
      cos = Math.cos(angle)
      Bullet.new(mid_x, mid_y, cos, sin, @hit_type, @gravity, @damage)
    else
      i = 0
      while i < @projectiles
        projectile_angle = (-@projectiles / 2 + i) / 10
        angle += projectile_angle
        sin = Math.sin(angle)
        cos = Math.cos(angle)
        Bullet.new(mid_x, mid_y, cos, sin, @hit_type, @gravity, @damage / @projectiles)
        i += 1
      end
    end
  end

  def randomize
    @hit_type = rand(3)
    @has_gravity = rand(2) == 0
    @gravity = @has_gravity? -rand(60) / 60 : 0
    @has_spray = rand(2) == 0
    @spray = @has_spray? rand(2) : 0
    @has_multiple_projectiles = rand(2) == 0
    @projectiles = @has_multiple_projectiles? rand(MAX_PROJECTILES - 1) + 2 : 1
    @damage = rand(50) + 25
  end
end
