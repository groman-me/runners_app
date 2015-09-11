require "roda"
require 'sequel'
require 'json'

class App < Roda
  plugin :head
  plugin :default_headers,
      'Content-Type'=>'text/html',
      'Content-Security-Policy'=>"default-src 'self' https://oss.maxcdn.com/ https://maxcdn.bootstrapcdn.com https://ajax.googleapis.com",
      #'Strict-Transport-Security'=>'max-age=16070400;', # Uncomment if only allowing https:// access
      'X-Frame-Options'=>'deny',
      'X-Content-Type-Options'=>'nosniff',
      'X-XSS-Protection'=>'1; mode=block'

  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
  ALLOWED_HOSTS = %w(groman-me.github.io localhost)

  route do |r|
    set_cors_header(request, response)

    r.root do
      r.redirect "/week.json"
    end
    
    r.is "month.json" do
      cur_month  = Date.new(Date.today.year, Date.today.month)
      prev_month = cur_month.prev_month
      DB.fetch(stats_sql, period: 'month', first_day_cur: cur_month, first_day_prev: prev_month).to_a.to_json
    end
    
    r.is "week.json" do
      cur_week  = Date.commercial(Date.today.year, Date.today.cweek)
      prev_week = cur_week - 7
      DB.fetch(stats_sql, period: 'week', first_day_cur: cur_week, first_day_prev: prev_week).to_a.to_json
    end
  end
  
  private

  def stats_sql
    sql = <<-SQL
    SELECT
      cur_stats.remote_user_sys_id  AS id,
      social_networks.name,
      remote_users.nick_name,
      CASE WHEN length(remote_users.full_name) > 0
        THEN remote_users.full_name
      ELSE remote_users.nick_name END as full_name,
      coalesce(cur_stats.value, 0)  AS cur_val,
      cur_stats.period_first_day,
      coalesce(prev_stats.value, 0) AS prev_val,
      prev_stats.period_first_day,
      cur_stats.type,
      cur_stats.period_type
    FROM remote_users
      LEFT JOIN users_board AS cur_stats
        ON remote_users.id = cur_stats.remote_user_sys_id 
        AND cur_stats.period_first_day = :first_day_cur
        AND cur_stats.period_type = :period 
      LEFT JOIN users_board AS prev_stats
        ON remote_users.id = prev_stats.remote_user_sys_id 
        AND prev_stats.period_first_day = :first_day_prev 
        AND prev_stats.period_type = :period
      JOIN social_networks ON social_networks.id = remote_users.social_network_id
    WHERE remote_users.active
    ORDER BY CASE WHEN coalesce(cur_stats.value, 0) > 0
      THEN cur_stats.value + 10000
             ELSE
               prev_stats.value
             END DESC NULLS LAST
    SQL
  end

  def set_cors_header(req, resp)
    if ALLOWED_HOSTS.include?(req.host)
      uri = URI(request.referrer)
      resp['Access-Control-Allow-Origin'] = "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end
  end

end
