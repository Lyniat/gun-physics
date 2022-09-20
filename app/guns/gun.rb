class Gun
  MAX_GRAVITY = 3
  MAX_PROJECTILES = 6
  COLOR_TRASH = {r: 100, g: 100, b:100}
  COLOR_COMMON = {r: 0, g: 255, b:0}
  COLOR_RARE = {r: 0, g: 0, b:255}
  COLOR_UNIQUE = {r: 255, g: 0, b:255}
  COLOR_LEGENDARY = {r:252, g:98, b:3}

  attr_reader :reloading
  def initialize
    @hit_type = 0
    @has_gravity = false
    @gravity = 0
    @has_spray = false
    @spray = 0
    @has_multiple_projectiles = false
    @projectiles = 1
    @damage = 0
    @ready = true
    @reloading = false
    @reload_time = 1
    @speed = 1
    @max_magazine = 0
    @magazine = 0
    @automatic = false
    @bullet_speed = 1
    @rating = 0
    @max_acceleration = 0
    @current_speed = 0
    @was_triggered = false
    @crit_chance = 0
    @max_crit = 0
    @kickback = 0
    @engine_sound_enabled = false

    $args.audio[:gun_engine] = {
      input: 'sounds/engine.wav',
      gain: 0.0,
      pitch: 1.0,
      paused: false,
      looping: true,
    }

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

    s_gravity = (@gravity * 100).ceil
    s_spray = (@spray * 100).ceil
    s_damage = @damage.ceil
    s_automatic = @automatic? "automatic" : "semi-automatic"
    s_warmup = (@max_acceleration > 0)? "#{((@current_speed / @max_acceleration) * 100)} %" : "none"

    r = COLOR_TRASH.r
    g = COLOR_TRASH.g
    b = COLOR_TRASH.b
    text = "TRASH"

    if @rating > 90
      r = COLOR_LEGENDARY.r
      g = COLOR_LEGENDARY.g
      b = COLOR_LEGENDARY.b
      text = "LEGENDARY"
    elsif @rating > 80
      r = COLOR_UNIQUE.r
      g = COLOR_UNIQUE.g
      b = COLOR_UNIQUE.b
      text = "UNIQUE"
    elsif @rating > 70
      r = COLOR_RARE.r
      g = COLOR_RARE.g
      b = COLOR_RARE.b
      text = "RARE"
    elsif @rating > 40
      r = COLOR_COMMON.r
      g = COLOR_COMMON.g
      b = COLOR_COMMON.b
      text = "COMMON"
    end

    $args.outputs.labels << [0, HEIGHT - 240, "#{text} (#{@rating}%)", 0, 0, r, g, b]
    $args.outputs.labels << [0, HEIGHT - 260, "TYPE: #{s_type}, #{s_automatic}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 280, "GRAVITY: #{s_gravity}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 300, "SPRAY: #{s_spray}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 320, "PROJECTILES: #{@projectiles}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 340, "DAMAGE: #{s_damage}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 360, "SPEED: #{@speed}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 380, "MAGAZINE: #{@magazine} / #{@max_magazine}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 400, "RELOAD TIME: #{@reload_time}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 420, "PROJECTILE SPEED: #{@bullet_speed}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 440, "WARMUP: #{s_warmup}", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 460, "CRIT CHANCE: #{@crit_chance}%", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 480, "CRIT DAMAGE: #{@max_crit}%", 0, 0, 255, 0, 0]
    $args.outputs.labels << [0, HEIGHT - 500, "KICKBACK: #{@kickback}", 0, 0, 255, 0, 0]
  end

  def get_ready args
    @ready = true
  end

  def reloaded args
    @magazine = @max_magazine
    @reloading = false
  end

  def simulate(tick_count)
    unless @was_triggered
      @current_speed -= 1
      if @current_speed < 0
        @current_speed = 0
      end
    end
    @was_triggered = false

    @current_speed = 0 if @reloading

    gain = @engine_sound_enabled? (@current_speed / @max_acceleration) + 0.1 : 0

    if gain > 1
      gain = 1
    end

    $args.audio[:gun_engine].gain = gain
    $args.audio[:gun_engine].pitch = 0.5 + (@current_speed / @max_acceleration)
  end

  def fire(mid_x, mid_y, dir_x, dir_y, held)
    if held && @max_acceleration > 0
      @current_speed += 1
      @was_triggered = true
      if @current_speed > @max_acceleration
        @current_speed = @max_acceleration
      end
    end
    if held && !@automatic
      return 0 #kickback
    end
    if @ready
      @ready = false
      warmup = 0
      if @max_acceleration != 0
        warmup = (1 - (@current_speed / @max_acceleration)) * @speed * 2
      end
      Service.new(@speed + warmup, method(:get_ready), {}, false)
    else
      return 0 #kickback
    end

    if @magazine == 0 && !@reloading
      @reloading = true
      Service.new(@reload_time, method(:reloaded), {}, false)
      $args.audio[:gun_reload] = {
        input: 'sounds/reload.wav',
        gain: 1.0,
        paused: false,
        looping: false,
      }
    end

    if @reloading
      return 0 #kickback
    end

    @magazine -= 1

    angle = Math.atan2(dir_y, dir_x)
    spray_angle = (rand(@spray) - @spray/2) / 3
    angle += spray_angle
    if !@has_multiple_projectiles
      sin = Math.sin(angle)
      cos = Math.cos(angle)
      Bullet.new(mid_x, mid_y, cos, sin, @hit_type, @gravity, @damage, @bullet_speed, @crit_chance,@max_crit)
      $args.audio[:gun_shot] = {
        input: 'sounds/bow.wav',
        gain: 1.0,
        pitch: 1.0 + rand(100) / 500,
        paused: false,
        looping: false,
      }
    else
      i = 0
      while i < @projectiles
        projectile_angle = (-@projectiles / 2 + i) / 10
        angle += projectile_angle
        sin = Math.sin(angle)
        cos = Math.cos(angle)
        Bullet.new(mid_x, mid_y, cos, sin, @hit_type, @gravity, @damage / @projectiles, @bullet_speed, @crit_chance,@max_crit)
        i += 1
      end
      $args.audio[:gun_shot] = {
        input: 'sounds/shotgun.wav',
        gain: 1.0,
        pitch: 1.0 + rand(100) / 500,
        paused: false,
        looping: false,
      }
    end
    return @kickback
  end

  def randomize
    @hit_type = rand(3)
    @has_gravity = rand(2) == 0
    gravity = rand(60)
    @gravity = @has_gravity? -gravity / 60 : 0
    @has_spray = rand(2) == 0
    @spray = @has_spray? rand(2) : 0
    @has_multiple_projectiles = rand(2) == 0
    @projectiles = @has_multiple_projectiles? rand(MAX_PROJECTILES - 1) + 2 : 1
    damage = rand(51)
    @damage = damage + 25
    speed = rand(101)
    @speed = 0.2 + speed / 300
    max_magazine = rand(50)
    @max_magazine = max_magazine + 1
    @magazine = @max_magazine
    reload_time = rand(250)
    @reload_time = 0.2 + reload_time / 100
    @automatic = rand(2) == 0
    @bullet_speed = (@hit_type == Bullet::HIT_TYPE_STICK)? 12 + rand(12) : 20 + rand(20)
    @max_acceleration = (max_magazine > 30 && @automatic)? (3 + rand(300) / 100) * 60 : 0
    @crit_chance = rand(51)
    @max_crit = rand(101)
    @kickback = (damage > 40)? (rand(200) / 100) * @projectiles : 0

    @engine_sound_enabled = @max_acceleration > 0

    @rating += 1 - (gravity / 60)
    @rating += damage / 50
    @rating += (1 - (speed / 100)) * 2 #dmg has double weight
    @rating += max_magazine / 50
    @rating += 1 - (reload_time / 250)
    @rating += (@max_acceleration > 0)? 0 : 1
    @rating += (@crit_chance / 50) * 2 #crit has double weight
    @rating += (@max_crit / 100) * 2 #crit has double weight

    @rating /= 11
    @rating *= 100
    @rating = @rating.round
  end
end
