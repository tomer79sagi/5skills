require File.dirname(__FILE__) + '/../test_helper'

class MysqlConnectionTimeoutControllerTest < Test::Unit::TestCase
  def setup
  end

  def test_mysql_connection_after_timeout
    assert ActiveRecord::Base.connection.active?
    ActiveRecord::Base.connection.update("set @@wait_timeout=1")
    sleep 2
    assert ActiveRecord::Base.connection.select_all("select 1=1")
  end

  def test_mysql_connection_after_timeout_with_manual_reconnect
    assert ActiveRecord::Base.connection.active?
    ActiveRecord::Base.connection.update("set @@wait_timeout=5")
    sleep 2
    ActiveRecord::Base.connection.reconnect!
    assert ActiveRecord::Base.connection.select_all("select 1=1")
  end

  def test_mysql_connection_after_timeout_with_verify
    assert ActiveRecord::Base.connection.active?
    ActiveRecord::Base.connection.update("set @@wait_timeout=5")
    sleep 2
    ActiveRecord::Base.connection.verify!(0)
    assert ActiveRecord::Base.connection.select_all("select 1=1")
  end

end