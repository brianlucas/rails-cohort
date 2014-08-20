class Order < ActiveRecord::Base
  belongs_to :user
  
  def self.cohorts

    # grabs earliest date we have stored
    earliest_date = Rails.cache.fetch('earliest_date', :expires_in => 24.hours) {
      Order.select("MIN(created_at)")[0].min
    }
    # create AREL query to grab cohort data, but let's cache it first
    data = Rails.cache.fetch('cohort_data', :expires_in => 24.hours) {
      Order.
          joins("JOIN (SELECT users.id, MIN(users.created_at) as cohort_date FROM users  WHERE (created_at > '#{earliest_date}') GROUP BY id) AS cohorts ON orders.user_id = cohorts.id").
          select("orders.user_id, orders.id, orders.order_num, orders.created_at, cohort_date, FLOOR(extract(epoch from (orders.created_at - cohort_date))/604800) as periods_out").where("orders.created_at > '#{earliest_date}'")
    }
    
    # the block below is inspired / lifted from the CohortMe gem: https://github.com/n8/cohort_me
    
    unique_data = data.all.uniq{|d| [d.send("id"), d.cohort_date, d.periods_out] }

    analysis = unique_data.group_by{|d| convert_to_cohort_date(Time.parse(d.cohort_date.to_s), "weeks")}

    cohort_hash =  Hash[analysis.sort_by { |cohort, data| cohort }.reverse]

    table = {}
    cohort_hash.each do |arr|
      periods = []
      first_time = []
      
      table[arr[0]] = {}

      cohort_hash.size.times{|i| periods << arr[1].count{|d| d.periods_out.to_i == i} if arr[1]}
      cohort_hash.size.times{|i| first_time << arr[1].count{|d| d.periods_out.to_i == i && d.order_num.to_i == 1} if arr[1]}
      
      table[arr[0]][:count] = periods
      table[arr[0]][:first_time] = first_time
      table[arr[0]][:data] = arr[1]
    end

    return table

  end
  
  # lifted from CohortMe gem: https://github.com/n8/cohort_me
  def self.convert_to_cohort_date(datetime, interval)
    if interval == "weeks"
      return datetime.at_beginning_of_week.to_date
      
    elsif interval == "days"
      return Date.parse(datetime.strftime("%Y-%m-%d"))

    elsif interval == "months"
      return Date.parse(datetime.strftime("%Y-%m-1"))
    end
  end
end
