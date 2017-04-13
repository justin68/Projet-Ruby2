class Poke
  attr_reader :x, :y
WINDOW_X = 1024
attr_reader :type
  def initialize(type)
    @image = Gosu::Image.new('images/pika.png')

# La vitesse de deplacement des ruby est variable
    @velocity = Gosu::random(0.8, 3.3)

    #On s'assure que les ruby restent bien dans la fenêtre
    @x = rand * (924 - @image.width)
    # Les ruby apparraissent aléatoirement dans la fenêtre
    @y = rand * (768 - @image.width)
  end

  def update
    @y += @velocity
  end

  def draw
    @image.draw(@x, @y, 1)
  end


end

class GameWindow < Hasu::Window
  SPRITE_SIZE = 100
  WINDOW_X = 1024
  WINDOW_Y = 768
attr_reader :score
  def initialize

    super(WINDOW_X, WINDOW_Y, false)
    @background_sprite = Gosu::Image.new(self, 'images/pokemon.jpg', true)
    @sacha_sprite = Gosu::Image.new(self, 'images/sacha.png', true)
    @enemy_sprite = Gosu::Image.new(self, 'images/jessie.png', true)
    @enemybis_sprite = Gosu::Image.new(self, 'images/james.png', true)
    @image_win = Gosu::Image.new(self, 'images/james.png', true)
    @font = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @ko = Gosu::Image.new(self, 'images/KO.png', true)
    @music = Gosu::Song.new(self, 'musics/poke2.wav')
    @dead = Gosu::Sample.new(self, 'musics/ko.wav')
    @win = Gosu::Sample.new(self, 'musics/win.wav')
    @coups = Gosu::Sample.new(self, 'musics/coups.wav')
    @items = []
    @score = 0
    reset
  end

  def update
    #Ajoute des pokemons
    unless @items.size >= 5
      r = rand
      if r < 0.035
        @items.push(Poke.new(:pika))
      end
    end

    @items.each(&:update)
    @items.reject! {|item| item.y > WINDOW_Y }

    #Evenements quand les poke et les ennemis sont touchés ou collectés
    #Et lors de l'appui sur les touches claviers
    collect_pika(@items)
    collect_enemy(@enemies)
    collect_enemybis(@enemiesbis)
     @player[:x] += @speed if button_down?(Gosu::Button::KbRight)
     @player[:x] -= @speed if button_down?(Gosu::Button::KbLeft)
     @player[:x] += @speed*2 if Gosu.button_down? Gosu::KbSpace and Gosu.button_down? Gosu::KbRight
     @player[:x] -= @speed*2 if Gosu.button_down? Gosu::KbSpace and Gosu.button_down? Gosu::KbLeft
     @player[:x] = normalize(@player[:x], WINDOW_X - SPRITE_SIZE)
     @player[:y] = normalize(@player[:y], WINDOW_Y - SPRITE_SIZE)

     jump if button_down?(Gosu::Button::KbUp)
     handle_jump if @jumping
     handle_enemies
     handle_enemiesbis
     handle_quit

    #Passage au niveau ou un reset du jeu en fonction du score
   case @score
   when 150
     @score = 0
     @win.play
     #@image_win.draw(100,100,3)
     sleep(4)
     reinit
   when -200..-100
     @score = 0
     @dead.play
     sleep(3)
     reset
   end
  end

  #Dessin des ennemis, du player, de la carte
  def draw
    @font.draw("Level #{@enemies.length}", WINDOW_X - 100, 10, 3, 1.0, 1.0, Gosu::Color::BLACK)
    @font.draw("Score: #{@score}", WINDOW_X - 1000, 10, 3, 1.0, 1.0, Gosu::Color::BLACK)
    @sacha_sprite.draw(@player[:x], @player[:y], 2)
    @enemies.each do |enemy|
      @enemy_sprite.draw(enemy[:x], enemy[:y], 2)
    end

    @enemiesbis.each do |enemy|
      @enemybis_sprite.draw(enemy[:x], enemy[:y], 2)
    end

        @background_sprite.draw(-200, 0, 0)
        @items.each(&:draw)

  end

  def jump
    return if @jumping
    @jumping = true
    @vertical_velocity = 100
  end

  #Fonction de saut
  def handle_jump
    gravity = 1.3
    ground_level = 768
    @player[:y] -= @vertical_velocity

    if @vertical_velocity.round == 0
      @vertical_velocity = -1
    elsif @vertical_velocity <0
      @vertical_velocity = @vertical_velocity * gravity
    else
      @vertical_velocity = @vertical_velocity / gravity
    end

    if @player[:y] >= ground_level
      @player[:y] = ground_level
      @jumping = false
    end
  end

    # A chaque pika collecté, ce dernier disparait, le score est incrémenté et un son est émis
    def collect_pika(items)
      items.reject! do |item|
        (item.x - @player[:x]).abs < 50 and (item.y - @player[:y]).abs < 50
        if Gosu.distance(@player[:x], @player[:y], item.x, item.y) < 50
          @score += 10
          @beep= Gosu::Sample.new('musics/piece.wav')
          @beep.play
          true
        else
          false
        end
      end
    end

    # A chaque ennemi collecté,  le score est decrémenté mias l'ennemi ne disparait pas
    def collect_enemy(enemies)
      enemies.reject do |enemy|
        (enemy[:x] - @player[:x]).abs < 50 and (enemy[:y] - @player[:y]).abs < 50
        if Gosu.distance(@player[:x], @player[:y], enemy[:x], enemy[:y]) < 50
          @score -= 10
          @coups.play
          true
        else
          false
        end
      end
    end

    def collect_enemybis(enemiesbis)
      enemiesbis.reject do |enemy|
        (enemy[:x] - @player[:x]).abs < 50 and (enemy[:y] - @player[:y]).abs < 50
        if Gosu.distance(@player[:x], @player[:y], enemy[:x], enemy[:y]) < 50
          @score -= 10
          @coups.play
          true
        else
          false
        end
      end
    end

  private


  #Reinitialise le score, les ennemis, la vitesse et lance la musique
  def reset
    @high_score = 0
    @enemies = []
    @enemiesbis = []
    @speed = 3
    @music.stop
    @music.play
    reinit
  end

  #Commencer le niveau ou passer ou niveau suivant en ajoutant un ennemi
  def reinit
    @speed += 1
    @player = {x: 0, y: 768}
    @enemies.push({x: 500 + rand(100), y: 200 + rand(300)})
    @enemiesbis.push({x: 500 + rand(100), y: 200 + rand(300)})
    high_score
  end

  #Ecrire un fichier avec le score du joueur
  def high_score
    unless File.exist?('hiscore')
      File.new('hiscore', 'w')
    end
    @new_high_score = [@enemies.count, File.read('hiscore').to_i].max
    File.write('hiscore', @new_high_score)
  end

  def random_mouvement
    (rand(3) - 1)
  end

  def normalize(v, max)
    if v < 0
      0
    elsif v > max
      max
    else
      v
    end
  end

  #Quitte le jeu
  def handle_quit
    if button_down? Gosu::KbEscape
      close
    end
  end

  #Fais déplacer les ennemis de façon aléatoire
  def handle_enemies
    @enemies = @enemies.map do |enemy|
      enemy[:timer] ||= 0
      if enemy[:timer] == 0
        enemy[:result_x] = random_mouvement
        enemy[:result_y] = random_mouvement
        enemy[:timer] = 50 + rand(50)
      end
      enemy[:timer] -= 1

      new_enemy = enemy.dup
      new_enemy[:x] += new_enemy[:result_x] * @speed
      new_enemy[:y] += new_enemy[:result_y] * @speed
      new_enemy[:x] = normalize(new_enemy[:x], WINDOW_X - SPRITE_SIZE)
      new_enemy[:y] = normalize(new_enemy[:y], WINDOW_Y - SPRITE_SIZE)
      enemy = new_enemy
      enemy
    end
  end

  def handle_enemiesbis
    @enemiesbis = @enemiesbis.map do |enemy|
      enemy[:timer] ||= 0
      if enemy[:timer] == 0
        enemy[:result_x] = random_mouvement
        enemy[:result_y] = random_mouvement
        enemy[:timer] = 50 + rand(50)
      end
      enemy[:timer] -= 1

      new_enemy = enemy.dup
      new_enemy[:x] += new_enemy[:result_x] * @speed
      new_enemy[:y] += new_enemy[:result_y] * @speed
      new_enemy[:x] = normalize(new_enemy[:x], WINDOW_X - SPRITE_SIZE)
      new_enemy[:y] = normalize(new_enemy[:y], WINDOW_Y - SPRITE_SIZE)
      enemy = new_enemy
      enemy
    end
  end
end
