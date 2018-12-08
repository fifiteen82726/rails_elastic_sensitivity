require "rails_elastic_sensitivity/version"
require 'active_record'

class ElaticSensitivity
  attr_accessor :main_t, :elastic_sensitivity, :epi, :k, :c, :k_square, :cache_mfx_table
  alias_method :mfx, :precompute_mfx

  def initialize(table)
    @cache_mfx_table = {}
    @main_t = table.to_s.classify.constantize
    Rails.cache.write('now_es', self)
    @k_square = 0
    @k = 1
    @c = 1
  end

  def precompute_mfx(attribute, table)
    if @cache_mfx_table["#{table}_#{attribute}"]
      return @cache_mfx_table["#{table}_#{attribute}"]
    end

    sql = "SELECT COUNT(#{attribute}) as count FROM #{table} GROUP BY #{attribute} ORDER BY count DESC LIMIT 1;"
    records_array = ActiveRecord::Base.connection.execute(sql)
    return @cache_mfx_table["#{table}_#{attribute}"] = records_array.first[0] # result
  end

  # Print model table name, sql description, noise added, elastic sensitivity, mfx value
  def details
    p '===== details ====='
    p "Main TABLE: #{@main_t}"
    p "MAX_FREQUENCY_METRIX"
    p @cache_mfx_table
    '===== details ====='
  end

  # like User.joins(:gamecharacters)
  def joins(*args)
    self_table_name = @main_t.to_s.downcase
    joins_t = args[0]

    #  multiple joins
    if args[0].is_a?(Hash)
      @k_square = 2
      first_t = joins_t.keys[0]
      second_t = joins_t[first_t]
      precompute_params = [
        ['id', "#{self_table_name}s"],
        ["#{self_table_name}_id", first_t.to_s],
      ]
      precompute_params.each{ |ps| precompute_mfx(*ps) }
      temp_c = compute_constant(precompute_params)
      temp_k = 2
      mfx_on_second_t = precompute_mfx("#{first_t.to_s.singularize}_id", second_t.to_s)
      @k = temp_k + (temp_k * mfx_on_second_t) + (temp_c) + 1
      @c = (temp_c * mfx_on_second_t) + mfx_on_second_t + temp_c
    else
      # single joins
      @k_square = 0
      precompute_params = [
        ['id', "#{self_table_name}s"],
        ["#{self_table_name}_id", joins_t.to_s],
      ]
      precompute_params.each{ |ps| precompute_mfx(*ps) }
      @c = compute_constant(precompute_params)
      @k = 2
    end

    Rails.cache.write('now_es', self)
    @main_t.joins(joins_t)
  end

  def compute_constant(precompute_params)
    precompute_params.map do |ps|
      key = "#{ps[1]}_#{ps[0]}"
      @cache_mfx_table[key]
    end.reduce(0, :+) + 1
  end
end

class ActiveRecord::Relation
  EPS = 1
  delta = 10 ** -8
  BETA = EPS / (2 * (Math.log(2 / delta)))

  def elastic_count
    es = Rails.cache.read("now_es")
    ture_result = self.count
    n = es.main_t.count
    elastic_sensitivity = compute_elastic_sensitivity(es.c, es.k, es.k_square, n)
    laplace_noise_scale = (2 * elastic_sensitivity) / EPS
    (ture_result + laplace(laplace_noise_scale)).abs
  end

  def compute_elastic_sensitivity(c, k, k_square, n)
    max = 0
    n = 0 if k_square == 0 # MAX value is when k == 0

    (0..n).each do |i|
      temp = (Math::E ** (-BETA*i)) * ((k_square * i **2 ) + (i * k) + c )
      max = temp if temp > max
    end

    max
  end

  def laplace(scale)
    u = 0.5 - rand(0.0..1.0)
    -(u <=> 0.0) * scale * Math.log(1 - (2 * (u).abs))
  end
end
