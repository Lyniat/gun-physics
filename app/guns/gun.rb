class Gun
  MAX_GRAVITY = 3
  MAX_PROJECTILES = 6
  COLOR_TRASH = {r: 100, g: 100, b:100}
  COLOR_COMMON = {r: 0, g: 255, b:0}
  COLOR_RARE = {r: 0, g: 0, b:255}
  COLOR_UNIQUE = {r: 255, g: 0, b:255}
  COLOR_LEGENDARY = {r:252, g:98, b:3}

  ENCHANTMENT_COLOR_CHAOTIC = {r:138, g:230, b:144}
  ENCHANTMENT_COLOR_VOLATILE = {r:138, g:202, b:230}
  ENCHANTMENT_COLOR_PRIMORDIAL = {r:196, g:138, b:230}
  ENCHANTMENT_COLOR_ASCENDEND = {r:230, g:186, b:138}

  ENCHANTMENT_FACTOR_NONE = 1
  ENCHANTMENT_FACTOR_CHAOTIC = 1.4
  ENCHANTMENT_FACTOR_VOLATILE = 1.8
  ENCHANTMENT_FACTOR_PRIMORDIAL = 2.2
  ENCHANTMENT_FACTOR_ASCENDEND = 2.6

  ENCHANTMENT_NONE = 0
  ENCHANTMENT_CHAOTIC = 1
  ENCHANTMENT_VOLATILE = 2
  ENCHANTMENT_PRIMORDIAL = 3
  ENCHANTMENT_ASCENDEND = 4

  SPECIAL_GUN_TYPE_NONE = 0
  SPECIAL_GUN_TYPE_FUNK = 1
  SPECIAL_GUN_TYPE_FISH = 2
  SPECIAL_GUN_TYPE_MAGIC = 3

  SPRITE_BASE = "/sprites/guns/base.png"
  SPRITE_ADDON = "/sprites/guns/addon/addon_"
  SPRITE_GRIP = "/sprites/guns/grip/grip_"
  SPRITE_HAMMER = "/sprites/guns/hammer/hammer_"
  SPRITE_SCOPE = "/sprites/guns/scope/scope_"
  SPRITE_SLIDE = "/sprites/guns/slide/slide_"
  SPRITE_TRIGGER = "/sprites/guns/trigger/trigger_"

  SPRITE_PARTS = [SPRITE_ADDON, SPRITE_GRIP, SPRITE_HAMMER, SPRITE_SCOPE, SPRITE_SLIDE, SPRITE_TRIGGER]

  WORDS_GUN = ["Gun", "Killer", "Murderer", "Hunter", "Piece", "Boom-Boom",
               "Torturer", "Punisher", "Machine" , "Destroyer", "King", "Knight",
               "Captain", "Soldier", "Pain Boy", "Pain Girl", "Bad Boy", "Bad Girl",
               "Badass", "Champion", "Winner"]
  WORDS_UNIQUE = ["Gods", "Heroes", "Chimera", "Irradiation", "Sirens", "Destruction",
                  "Dragons", "Giants", "Monsters", "Insanity", "Singularity"]
  WORDS_COMMON = ["Books", "Stuffed Animals", "Rats", "Garbage", "Collectors", "Chess Players",
                  "Mathematicians", "Biologists", "Dung Piles", "Dust", "Soil", "Rust", "Mold",
                  "Moisture", "Soap", "Sewage", "Fog", "Steam", "Administration", "Shoes",
                  "Pants", "Hairstyle", "Feelings", "Sleep", "Anxiety", "Rotten", "Vocabularies",
                  "Isolation", "Probabilities", "Algorithms", "Economy", "Nature", "Beings"]

  attr_reader :reloading
  def initialize
    @enchantment = ENCHANTMENT_NONE
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
    @name
    @special_type = SPECIAL_GUN_TYPE_NONE

    randomize
    generate_sprite
  end

  def generate_sprite
    $args.render_target(:gun).clear_before_render = true
    $args.render_target(:gun).sprites << { x: 0,
                                                  y: 0,
                                                  w: 8 * 128,
                                                  h: 8 * 72,
                                                  path: SPRITE_BASE}
    i = 0
    while i < SPRITE_PARTS.length
      part = rand(4)
      $args.render_target(:gun).sprites << { x: 0,
                                               y: 0,
                                               w: 8 * 128,
                                               h: 8 * 72,
                                               path: "#{SPRITE_PARTS[i]}#{part}.png"}
      i += 1
    end
  end

  def set_engine_sound
    audio = (rand(2) == 0)? "sounds/engine.wav" : "sounds/engine_2.wav"
    case @special_type
    when SPECIAL_GUN_TYPE_FUNK
      audio = "sounds/funk.ogg"
    when SPECIAL_GUN_TYPE_FISH
      audio = "sounds/boiling.wav"
    when SPECIAL_GUN_TYPE_MAGIC
      audio = "sounds/harp.wav"
    end
    $args.audio[:gun_engine] = {
      input: audio,
      gain: 0.0,
      pitch: 1.0,
      paused: false,
      looping: true,
    }
  end

  def get_name(is_unique, special_name)
    if is_unique
      word = WORDS_UNIQUE[rand(WORDS_UNIQUE.length)]
    else
      word = WORDS_COMMON[rand(WORDS_COMMON.length)]
    end

    gun = WORDS_GUN[rand(WORDS_GUN.length)]

    gun = special_name unless special_name.nil?

    return "#{gun} of #{word}"
  end

  def draw(tick_count)
    case @hit_type
    when Bullet::HIT_TYPE_DESTROY
      s_type = "bullet"
    when Bullet::HIT_TYPE_BOUNCE
      s_type = "bounce"
    when Bullet::HIT_TYPE_STICK
      s_type = "arrow"
    when Bullet::HIT_TYPE_TONE
      s_type = "funky"
    when Bullet::HIT_TYPE_FISH
      s_type = "wet"
    when Bullet::HIT_TYPE_MAGIC
      s_type = "magic"
    end

    s_gravity = (@gravity * 100).ceil
    s_spray = (@spray * 100).ceil
    s_damage = @damage.ceil
    s_automatic = @automatic? "automatic" : "semi-automatic"
    s_warmup = (@max_acceleration > 0)? "#{((@current_speed / @max_acceleration) * 100)} %" : "none"

    r = COLOR_TRASH.r
    g = COLOR_TRASH.g
    b = COLOR_TRASH.b
    text = "Trashy"

    if @rating > 80
      r = COLOR_LEGENDARY.r
      g = COLOR_LEGENDARY.g
      b = COLOR_LEGENDARY.b
      text = "Legendary"
    elsif @rating > 70
      r = COLOR_UNIQUE.r
      g = COLOR_UNIQUE.g
      b = COLOR_UNIQUE.b
      text = "Unique"
    elsif @rating > 60
      r = COLOR_RARE.r
      g = COLOR_RARE.g
      b = COLOR_RARE.b
      text = "Rare"
    elsif @rating > 50
      r = COLOR_COMMON.r
      g = COLOR_COMMON.g
      b = COLOR_COMMON.b
      text = "Useful"
    end

    text = "#{text} #{@name}"

    enchantment_text = ""
    enchantment_r = COLOR_TRASH.r
    enchantment_g = COLOR_TRASH.g
    enchantment_b = COLOR_TRASH.b

    case @enchantment
    when ENCHANTMENT_CHAOTIC
      enchantment_r = ENCHANTMENT_COLOR_CHAOTIC.r
      enchantment_g = ENCHANTMENT_COLOR_CHAOTIC.g
      enchantment_b = ENCHANTMENT_COLOR_CHAOTIC.b
      enchantment_text = "Chaotic"
    when ENCHANTMENT_VOLATILE
      enchantment_r = ENCHANTMENT_COLOR_VOLATILE.r
      enchantment_g = ENCHANTMENT_COLOR_VOLATILE.g
      enchantment_b = ENCHANTMENT_COLOR_VOLATILE.b
      enchantment_text = "Volatile"
    when ENCHANTMENT_PRIMORDIAL
      enchantment_r = ENCHANTMENT_COLOR_PRIMORDIAL.r
      enchantment_g = ENCHANTMENT_COLOR_PRIMORDIAL.g
      enchantment_b = ENCHANTMENT_COLOR_PRIMORDIAL.b
      enchantment_text = "Primordial"
    when ENCHANTMENT_ASCENDEND
      enchantment_r = ENCHANTMENT_COLOR_ASCENDEND.r
      enchantment_g = ENCHANTMENT_COLOR_ASCENDEND.g
      enchantment_b = ENCHANTMENT_COLOR_ASCENDEND.b
      enchantment_text = "Ascendend"
    end

    w, h = $args.gtk.calcstringbox(enchantment_text)
    w += 10 if w > 0
    $args.outputs.labels << [0, HEIGHT - 240, enchantment_text, 0, 0, enchantment_r, enchantment_g, enchantment_b]
    $args.outputs.labels << [w, HEIGHT - 240, "#{text} (#{@rating}%)", 0, 0, r, g, b]
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
    start_x = mid_x + dir_x * 50
    start_y = mid_y + dir_y * 40
    spray_angle = 0 #TODO: fix
    angle += spray_angle
    if !@has_multiple_projectiles
      sin = Math.sin(angle)
      cos = Math.cos(angle)
      Bullet.new(start_x, start_y, cos, sin, @hit_type, @gravity, @damage, @bullet_speed, @crit_chance,@max_crit)
      sound = "sounds/bow.wav"
    else
      i = 0
      while i < @projectiles
        projectile_angle = (-@projectiles / 2 + i) / 10
        angle += projectile_angle
        sin = Math.sin(angle)
        cos = Math.cos(angle)
        Bullet.new(start_x, start_y, cos, sin, @hit_type, @gravity, @damage / @projectiles, @bullet_speed, @crit_chance,@max_crit)
        i += 1
      end
      sound = "sounds/shotgun.wav"
    end

    play_sound = true

    case @special_type
    when SPECIAL_GUN_TYPE_FUNK
      play_sound = false
    when SPECIAL_GUN_TYPE_MAGIC
      play_sound = false
    when SPECIAL_GUN_TYPE_FISH
      sound = "sounds/splat.wav"
    end

    if play_sound
      $args.audio[:gun_shot] = {
        input: sound,
        gain: 1.0,
        pitch: 1.0 + rand(100) / 500,
        paused: false,
        looping: false,
      }
    end
    return @kickback
  end

  def randomize
    has_enchantment = rand(25) == 0
    @enchantment = ENCHANTMENT_NONE
    @enchantment_factor = ENCHANTMENT_FACTOR_NONE
    if has_enchantment
      @enchantment = 1 + rand(4)
      case @enchantment
      when ENCHANTMENT_CHAOTIC
        @enchantment_factor = ENCHANTMENT_FACTOR_CHAOTIC
      when ENCHANTMENT_VOLATILE
        @enchantment_factor = ENCHANTMENT_FACTOR_VOLATILE
      when ENCHANTMENT_PRIMORDIAL
        @enchantment_factor = ENCHANTMENT_FACTOR_PRIMORDIAL
      when ENCHANTMENT_ASCENDEND
        @enchantment_factor = ENCHANTMENT_FACTOR_ASCENDEND
      end
    end

    @hit_type = rand(3)
    @has_gravity = rand(2) == 0
    gravity = rand(60)
    @gravity = @has_gravity? -gravity / 180 : 0
    @has_spray = rand(2) == 0
    @spray = @has_spray? rand(2) : 0
    @has_multiple_projectiles = rand(2) == 0
    @projectiles = (@has_multiple_projectiles? rand(MAX_PROJECTILES - 1) + 2 : 1) * (@enchantment_factor * 1.5)
    damage = rand(51)
    @damage = (damage + 25) * @enchantment_factor
    speed = rand(101)
    @speed = (0.2 + speed / 300)# / @enchantment_factor TODO: slows down game if too fast
    max_magazine = rand(50)
    @max_magazine = max_magazine + 1
    @magazine = @max_magazine * @enchantment_factor
    reload_time = rand(250)
    @reload_time = (0.2 + reload_time / 100) / @enchantment_factor
    @automatic = rand(2) == 0
    @bullet_speed = ((@hit_type == Bullet::HIT_TYPE_STICK)? 12 + rand(12) : 20 + rand(20)) * @enchantment_factor
    @max_acceleration = ((max_magazine > 30 && @automatic)? (3 + rand(300) / 100) * 60 : 0) / @enchantment_factor
    @crit_chance = rand(51) * @enchantment_factor
    @max_crit = rand(101) * @enchantment_factor
    @kickback = ((damage > 40)? (rand(200) / 100) * @projectiles : 0) / @enchantment_factor

    @engine_sound_enabled = @max_acceleration > 0

    @special_type = SPECIAL_GUN_TYPE_NONE
    is_special = rand(2) == 0
    if is_special
      @special_type = 1 + rand(100)
      case @special_type
      when SPECIAL_GUN_TYPE_FUNK
        @bullet_speed = 1
        @automatic = true
        @max_acceleration = 300
        @magazine = 70
        @max_magazine = @magazine
        @hit_type = Bullet::HIT_TYPE_TONE
        @projectiles = 1
        @engine_sound_enabled = true
        @gravity = 0
      when SPECIAL_GUN_TYPE_FISH
        @speed = 1
        @bullet_speed = 6
        @automatic = true
        @max_acceleration = 300
        @magazine = 70
        @max_magazine = @magazine
        @hit_type = Bullet::HIT_TYPE_FISH
        @projectiles = 1
        @engine_sound_enabled = true
        @gravity = -1
        @damage *= 2
      when SPECIAL_GUN_TYPE_MAGIC
        @bullet_speed = 1
        @automatic = true
        @max_acceleration = 1
        @magazine = 70
        @max_magazine = @magazine
        @hit_type = Bullet::HIT_TYPE_MAGIC
        @projectiles = 1
        @engine_sound_enabled = true
        @gravity = 0
      end
    end

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

    name = nil if is_special
    case @special_type
    when SPECIAL_GUN_TYPE_FUNK
      name = "Beatbox"
    when SPECIAL_GUN_TYPE_FISH
      name = "Fisherman"
    when SPECIAL_GUN_TYPE_MAGIC
      name = "Wizard"
    end
    @name = get_name(@rating > 70, name)

    set_engine_sound
  end
end
