require 'singleton'
require 'tty-prompt'
require 'tty-table'
require 'bigdecimal'
require 'colorize'

ITEMS = {
  Cola:      { price: BigDecimal('3'), amount: 5,  label: 'Cola'.red },
  Chips:     { price: BigDecimal('2'), amount: 10, label: 'Chips'.light_yellow },
  Chocolate: { price: BigDecimal('5'), amount: 7,  label: 'Chocolate'.light_magenta },
}.freeze

COINS = {
  BigDecimal('5') => 1,
  BigDecimal('2') => 1,
  BigDecimal('1') => 1,
  BigDecimal('0.5') => 1,
  BigDecimal('0.2') => 1,
  BigDecimal('0.1') => 1
}.freeze

class VendingMachine
  include Singleton

  def initialize
    @items = ITEMS.dup
    @coins = COINS.dup.sort.reverse.to_h
    @prompt = TTY::Prompt.new
  end

  def menu
    display_left_items
    display_left_coins

    item = @prompt.select('Select item:') do |menu|
      @items.each do |item, info|
        menu.choice(
          {
            name:     "#{info[:label]}. Amount: #{info[:amount]}, Price: #{info[:price].to_i}",
            value:    item,
            disabled: ('(out of stock)' if info[:amount].zero?)
          }
        )
      end
    end

    inserted_coins = insert_coins(item)
    odd_money = odd_money(item, inserted_coins)

    give_item(item, inserted_coins, odd_money)
  end

  def give_item(item, inserted_coins, odd_money)
    rest_sum, odd_money = odd_money

    @items[item][:amount] -= 1

    puts "\n"
    puts "Please take your #{@items[item][:label]}."
    puts "Odd money: #{odd_money.map { |c| number_to_currency(c) }}." if odd_money.any?
    puts "Can't return: #{number_to_currency(rest_sum)}." if rest_sum.nonzero?
    puts "\n"
  end

  def odd_money(item, inserted_coins)
    odd_sum = inserted_coins.sum - @items[item][:price]
    odd_money = []

    return [0, []] if odd_sum.zero?

    @coins.each do |coin, amount|
      while odd_sum >= coin && amount.nonzero? && odd_sum.nonzero?
        odd_sum -= coin
        odd_money << coin
        amount -= 1
      end

      @coins[coin] = amount
    end

    return [odd_sum, odd_money]
  end

  def insert_coins(item)
    inserted_coins = []

    while inserted_coins.sum < @items[item][:price]
      puts "\nInserted: #{inserted_coins.map { |c| number_to_currency(c) }}"

      inserted_coin = @prompt.ask("Please insert coin. #{@coins.keys.map { |c| number_to_currency(c) }}")
      inserted_coin = currency_to_number(inserted_coin.to_s)

      if @coins[inserted_coin]
        inserted_coins << inserted_coin
      else
        puts 'Invalid coin!'.red
      end
    end

    inserted_coins.each { |c| @coins[c] += 1 }

    inserted_coins
  end

  def display_left_items
    display_table %w(item amount),
                  @items.map { |item, info| [item, info[:amount]] }
  end

  def display_left_coins
    display_table %w(coin amount),
                  @coins.map { |coin, amount| [number_to_currency(coin), amount] }
  end

  def display_table(headers, columns)
    puts (
      TTY::Table.new headers, columns
    ).render(:ascii)
  end

  def number_to_currency(number)
    return "#{(number * 100).to_i}c" if number < 1

    "$#{number.to_i}"
  end

  def currency_to_number(currency)
    number =
      if currency.start_with?('$')
        currency[1..-1]
      else
        currency.to_f/100
      end.to_s

    BigDecimal(number)
  end
end

loop do
  VendingMachine.instance.menu
rescue TTY::Reader::InputInterrupt
  puts "\n\nHave a nice day!"
  break
end