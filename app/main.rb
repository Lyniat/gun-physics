require 'app/lib/camera.rb'
require 'app/game/player_camera.rb'
require 'app/lib/rect.rb'
require 'app/lib/actor.rb'
require 'app/lib/drawable/color.rb'
require 'app/lib/drawable/drawable.rb'
require 'app/lib/drawable/sprite.rb'
require 'app/lib/level.rb'
require 'app/lib/solid.rb'
require 'app/lib/projectile.rb'
require 'app/game/arrow.rb'
require 'app/game/player.rb'
require 'app/game/platform.rb'
require 'app/game/platform_linear.rb'
require 'app/game/platform_circle.rb'
require 'app/lib/drawable/box.rb'
require 'app/lib/drawable/animation.rb'
require 'app/lib/service.rb'
require 'app/guns/advanced_projectile.rb'
require 'app/guns/bullet.rb'
require 'app/guns/gun.rb'
require 'app/guns/target.rb'
require 'app/guns/effect.rb'
require 'app/guns/damage_popup.rb'

WIDTH = 1280
HEIGHT = 720

def init args
  @player = Player.new(0, 0, 50, 50 * 2)
  init_objects
  @camera = PlayerCamera.new(args, @player)
  Level.instance.set_camera(@camera)
  @show_debug = false
  @paused = false
  @resetting = false
end

def init_objects
  cloud_block = Sprite.new(100, 100, "/sprites/cloud_block.png", 0, 16, 16)
  Solid.new(0, -100, WIDTH, 100, Box.new(WIDTH, 100, Color::RED))
  Solid.new(0, 150, 100, 100, cloud_block)
  Solid.new(200, 400, 100, 100, cloud_block)

  platform_1 = Sprite.new(300, 50, "/sprites/platform.png", 0, 48, 8)
  PlatformCircle.new(300, 100, 300, 50, 0.02, platform_1, 100)

  platform_2 = Sprite.new(50, 300, "/sprites/platform_2.png", 0, 8, 48)
  PlatformLinear.new(900, 120, 50, 300, 0.02, platform_2, 1200, 120)

  target = Sprite.new(100, 100, "/sprites/target_block.png", 0, 16, 16)
  Target.new(720, 200, 100, 100, target)
end

def tick args
  $args = args
  init(args) if args.state.tick_count == 0

  @show_debug = !@show_debug if args.inputs.keyboard.key_down.escape
  @paused = !@paused if args.inputs.keyboard.key_down.backspace
  Level.instance.debug(@show_debug)
  Level.instance.pause(@paused)

  unless @paused
    @player.move_left if args.inputs.keyboard.key_held.a
    @player.move_right if args.inputs.keyboard.key_held.d
    @player.climb if args.inputs.keyboard.key_held.shift_left
    @player.move_up if args.inputs.keyboard.key_held.w
    @player.move_down if args.inputs.keyboard.key_held.s
    @player.jump if args.inputs.keyboard.key_down.space
    @player.fire(@camera.mouse_x, @camera.mouse_y, false) if args.inputs.mouse.click
    @player.fire(@camera.mouse_x, @camera.mouse_y, true) if args.inputs.mouse.button_left
    @player.update_mouse(@camera.mouse_x, @camera.mouse_y)

    @player.randomize_gun if args.inputs.keyboard.key_down.r
  end

  Level.instance.simulate(args)
  Level.instance.draw(args)

  if @player.dead and !@resetting
    Service.new(2, method(:reset), {}, false)
    @resetting = true
  end

  args.outputs.labels << [0, HEIGHT, "move: W, A, S, D", 0, 0, 255, 0, 0]
  args.outputs.labels << [0, HEIGHT - 20, "jump: SPACE", 0, 0, 255, 0, 0]
  args.outputs.labels << [0, HEIGHT - 40, "climb: SHIFT", 0, 0, 255, 0, 0]
  args.outputs.labels << [0, HEIGHT - 60, "fire: MOUSE", 0, 0, 255, 0, 0]
  args.outputs.labels << [0, HEIGHT - 80, "debug: ESCAPE", 0, 0, 255, 0, 0]
  args.outputs.labels << [0, HEIGHT - 100, "pause: BACKSPACE", 0, 0, 255, 0, 0]
  args.outputs.labels << [0, HEIGHT - 120, "randomize gun: R", 0, 0, 255, 0, 0]

  $args.outputs.sprites << {x: 0,
                            y: 0,
                            w: 160,
                            h: 160,
                            path: :gun}
end

def reset args
  @player = Player.new(0, 0, 50, 50 * 2)
  @camera = PlayerCamera.new(args, @player)
  Level.instance.set_camera(@camera)
  @resetting = false
end
