class Target < Solid
  def initialize(x, y, w, h, drawable)
    super(x, y, w, h, drawable)
    @x = x
    @y = y
    @w = w
    @h = h
    @current_dmg = 0
    @dmg_list = []
  end

  def calculate_dps(tick_count)
    @dmg_list << @current_dmg
    @current_dmg = 0

    if @dmg_list.length > 60
      @dmg_list.shift
    end

    dps = 0
    if @dmg_list.length > 0
      i = 0
      while i < @dmg_list.length
        dps += @dmg_list[i]
        i += 1
      end
      dps /= 60
    end

    # currently wrong TODO: fix
    #$args.outputs.labels << [0, HEIGHT - 200, "DPS: #{dps.ceil}", 0, 0, 0, 0, 0]
  end

  def simulate(tick_count)
    calculate_dps(tick_count)
    super(tick_count)
  end

  def on_bullet_hit(x, y, damage, is_critical)
    DamagePopup.new(x + @w / 2, y + @h / 2, damage, is_critical)

    @current_dmg += damage
  end
end

