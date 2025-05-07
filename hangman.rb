# Hangman
require "yaml"

# Game Logic
class Game
  def initialize
    @total_guesses = 10
  end

  def view_board
    @board.each do |space|
      print "#{space}  "
    end
    puts "\n\nLetters used: #{@player.letters_used.join(' ')}\n\nTotal guesses left: #{@total_guesses}"
  end

  def set_secret
    @secret = @dico.sample.chars
    puts ">> The secret word has been selected:\n\n"
    @board = Array.new(@secret.length, "_")
  end

  def match_letter
    @secret.each_index do |index|
      @board[index] = @player.letters_used.last if @secret[index] == @player.letters_used.last
    end
    @total_guesses -= 1
  end

  def create_player
    puts ">> What is your name?"
    @player = Player.new(gets.chomp.capitalize)
    set_secret
  end

  def save_game
    puts ">> Saving game..."
    @player.letters_used.pop
    @player.last_saved = Time.now
    GameFile.save_file(game_data = [@secret, @board, @player])
  end

  def load_game
    loaded_game_data = GameFile.list_files
    @secret = loaded_game_data[0]
    @board = loaded_game_data[1]
    @player = loaded_game_data[2]
    @total_guesses -= @player.letters_used.length
    puts ">> Successfully loaded from '#{@player.last_saved}...\n\n"
  end

  def game_menu
    puts "======= MAIN MENU ======="
    puts "1. New Game"
    puts "2. Load Game"
    puts "3. Quit Game"
    puts "========================="
    puts ">> Select an option:"
    gets.chomp.to_i
  end

  def select_menu
    choice = game_menu
    case choice
    when 1
      create_player
    when 2
      load_game
    when 3
      GameFile.quit_game
    else
      puts ">> Invalid entry, try again!"
      select_menu
    end
  end

  def guess_save?
    if @player.guess_letter == "!"
      @total_guesses += 1
      save_game
    else
      false
    end
  end

  def win_draw?
    if @board == @secret
      announce_winner
      true
    elsif @total_guesses.zero?
      announce_draw
      true
    end
  end

  def announce_winner
    view_board
    puts ">> Congratulations! The secret word was #{@secret.join}."
  end

  def announce_draw
    view_board
    puts ">> Almost had it! The secret word was #{@secret.join}."
  end

  def play
    puts "HANGMAN is starting..."
    @dico = GameFile.load_dictionary
    select_menu
    loop do
      view_board
      break if guess_save?

      match_letter
      break if win_draw?
    end
  end
end

# Game Files Management
class GameFile
  def self.load_dictionary
    dictionary = []
    puts ">> Loading Dictionary..."
    f = File.open("google-10000-english-no-swears.txt")
    until f.eof?
      word = f.gets.chomp
      dictionary << word.upcase if word.length < 12 && word.length > 5
    end
    puts ">> Dictionary loaded successfully!"
    dictionary
  end

  def self.save_file(game_data)
    name = game_data[2].name
    filename = "save_files/#{name.downcase}.yaml"
    File.write(filename, YAML.dump(game_data))
    puts ">> Successfully saved game for '#{name}' at #{game_data[2].last_saved}! \n>> Continue playing? (Y/N)"
    if gets.chomp.upcase == "Y"
      false
    else
      puts "Goodbye!"
      true
    end
  end

  def self.load_file(save_files)
    player_list = save_files.map { |file| File.basename(file, ".yaml") }
    puts ">> Choose your save file:"
    choice = gets.chomp.to_i
    player_name = player_list[choice - 1]
    puts ">> Loading saved game for '#{player_name.capitalize}'..."
    yaml = File.read("save_files/#{player_name}.yaml")
    YAML.load(yaml, permitted_classes: [Player, Time])
  end

  def self.list_files
    puts "======= SAVE FILES ======="
    save_files = Dir.glob("save_files/*.yaml", sort: true)
    save_files.each_with_index do |file, index|
      player_name = File.basename(file, ".yaml").capitalize
      puts "#{index + 1}. #{player_name}"
    end
    puts "=========================="
    load_file(save_files)
  end

  def self.quit_game
    puts ">> Goodbye!"
    Process.exit!(true)
  end
end

# Players
class Player
  attr_accessor :name, :letters_used, :last_saved

  def initialize(name)
    @name = name.capitalize
    @letters_used = []
    @last_saved = 0
  end

  def guess_letter
    puts ">> Guess a letter (or type '!' to save):"
    letter = gets.chomp.upcase
    letters_used << letter
    puts ""
    letter
  end
end

Game.new.play
