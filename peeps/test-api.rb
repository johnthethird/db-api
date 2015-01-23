# test peeps schema
require 'pg'
require 'minitest/autorun'
require 'json'

DB = PG::Connection.new(dbname: 'd50b_test', user: 'd50b')
SCHEMA = File.read('schema.sql')
FIXTURES = File.read('fixtures.sql')

class Minitest::Test
	def setup
		DB.exec(SCHEMA)
		DB.exec(FIXTURES)
	end
end

Minitest.after_run do
	DB.exec(SCHEMA)
	DB.exec(FIXTURES)
end

class TestPeepsAPI < Minitest::Test

	def test_unopened_email_count
		res = DB.exec("SELECT * FROM unopened_email_count(1)")
		j = JSON.parse(res[0]['js'])
		assert_equal %w(derek@sivers we@woodegg), j.keys
		assert_equal({'woodegg' => 1, 'not-derek' => 1}, j['we@woodegg'])
		res = DB.exec("SELECT * FROM unopened_email_count(4)")
		j = JSON.parse(res[0]['js'])
		assert_equal %w(we@woodegg), j.keys
		res = DB.exec("SELECT * FROM unopened_email_count(3)")
		j = JSON.parse(res[0]['js'])
		assert_equal({}, j)
	end

	def test_unopened_emails
		res = DB.exec("SELECT * FROM unopened_emails(1, 'we@woodegg', 'woodegg')")
		j = JSON.parse(res[0]['js'])
		assert_instance_of Array, j
		assert_equal 1, j.size
		assert_equal 'I refuse to wait', j[0]['subject']
		assert_nil j[0]['body']
		res = DB.exec("SELECT * FROM unopened_emails(3, 'we@woodegg', 'woodegg')")
		assert_equal [], JSON.parse(res[0]['js'])
	end

	def test_open_next_email
		res = DB.exec("SELECT * FROM open_next_email(1, 'we@woodegg', 'woodegg')")
		j = JSON.parse(res[0]['js'])
		assert_equal 8, j['id']
		assert_equal 1, j['openor']['id']
		assert_equal 'Derek Sivers', j['openor']['name']
		assert_match /^\d{4}-\d{2}-\d{2}/, j['opened_at']
		assert_equal 'I refuse to wait', j['subject']
		assert_equal 'I refuse to wait', j['body']
		res = DB.exec("SELECT * FROM open_next_email(1, 'we@woodegg', 'woodegg')")
		assert_equal 'application/problem+json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', j['title']
	end

	def test_opened_emails
		res = DB.exec("SELECT * FROM opened_emails(1)")
		j = JSON.parse(res[0]['js'])
		assert_instance_of Array, j
		assert_equal 1, j.size
		assert_equal 'I want that Wood Egg book now', j[0]['subject']
		res = DB.exec("SELECT * FROM opened_emails(3)")
		assert_equal [], JSON.parse(res[0]['js'])
	end

	def test_get_email
		res = DB.exec("SELECT * FROM get_email(1, 8)")
		j = JSON.parse(res[0]['js'])
		assert_equal 'I refuse to wait', j['subject']
		assert_equal 'Derek Sivers', j['openor']['name']
		res = DB.exec("SELECT * FROM get_email(1, 6)")
		j = JSON.parse(res[0]['js'])
		assert_equal '2014-05-21', j['opened_at'][0,10]
		res = DB.exec("SELECT * FROM get_email(3, 6)")
		assert_equal 'application/problem+json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert_equal 'about:blank', j['type']
		assert_equal 'Not Found', j['title']
		assert_equal 404, j['status']
	end

	def test_update_email
		res = DB.exec_params("SELECT * FROM update_email(1, 8, $1)", ['{"subject":"boop", "ig":"nore"}'])
		j = JSON.parse(res[0]['js'])
		assert_equal 'boop', j['subject']
		res = DB.exec_params("SELECT * FROM update_email(3, 8, $1)", ['{"subject":"boop", "ig":"nore"}'])
		assert_equal 'application/problem+json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', j['title']
	end

	def test_update_email_errors
		res = DB.exec_params("SELECT * FROM update_email(1, 8, $1)", ['{"opened_by":"boop"}'])
		assert_equal 'application/problem+json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert j['type'].include? '22P02'
		assert j['title'].include? 'invalid input syntax for integer'
		assert j['detail'].include? 'jsonupdate'
	end

	def test_delete_email
		res = DB.exec("SELECT * FROM delete_email(1, 8)")
		assert_equal 'application/json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert_equal 'I refuse to wait', j['subject']
		res = DB.exec("SELECT * FROM delete_email(1, 8)")
		assert_equal 'application/problem+json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', j['title']
		res = DB.exec("SELECT * FROM delete_email(3, 1)")
		assert_equal 'application/problem+json', res[0]['mime']
		j = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', j['title']
	end

	def test_close_email
		res = DB.exec("SELECT * FROM close_email(4, 6)")
		j = JSON.parse(res[0]['js'])
		assert_equal 4, j['closor']['id']
	end

	def test_unread_email
		res = DB.exec("SELECT * FROM unread_email(4, 6)")
		j = JSON.parse(res[0]['js'])
		assert_nil j['opened_at']
		assert_nil j['openor']
	end

	def test_not_my_email
		res = DB.exec("SELECT * FROM not_my_email(4, 6)")
		j = JSON.parse(res[0]['js'])
		assert_nil j['opened_at']
		assert_nil j['openor']
		assert_equal 'not-gong', j['category']
	end

	def test_reply_to_email
		res = DB.exec("SELECT * FROM reply_to_email(4, 8, 'Groovy, baby')")
		j = JSON.parse(res[0]['js'])
		assert_equal 11, j['id']
		assert_equal 3, j['person_id']
		assert_match /\A[0-9]{17}\.3@sivers.org\Z/, j['message_id']
		assert_equal j['message_id'][0,12], Time.now.strftime('%Y%m%d%H%M')
		assert j['body'].include? 'Groovy, baby'
		assert_match /\AHi Veruca -/, j['body']
		assert_match /^> I refuse to wait$/, j['body']
		assert_match %r{^Wood Egg  we@woodegg.com  http://woodegg.com\/$}, j['body']
		assert_equal nil, j['outgoing']
		assert_equal 're: I refuse to wait', j['subject']
		assert_match %r{^20}, j['created_at']
		assert_match %r{^20}, j['opened_at']
		assert_match %r{^20}, j['closed_at']
		assert_equal '巩俐', j['creator']['name']
		assert_equal '巩俐', j['openor']['name']
		assert_equal '巩俐', j['closor']['name']
		assert_equal 'Veruca Salt', j['their_name']
		assert_equal 'veruca@salt.com', j['their_email']
	end

end
