class Effect < Drawable
  def initialize(w, h)
    super
    Level.instance.add_effect(self)
  end

  def draw(tick_count)

  end

  def simulate(tick_count)

  end

  def destroy args
    Level.instance.remove_effect(self)
  end
end
