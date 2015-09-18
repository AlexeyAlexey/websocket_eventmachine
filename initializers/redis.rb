#$redis = Redis.new(:host => 'localhost', :port => 6379)
$redis_pool = ConnectionPool.new(size: 5, timeout: 5) {  Redis.new }