P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class TestComment < Minitest::Test
	include JDB

	def setup
		super
		@new_comment = {uri: 'boo', name: 'Bob Dobalina', email: 'bob@dobali.na', html: 'þ <script>alert("poop")</script> <a href="http://bad.cc">yuck</a> :-)'}
	end

	def test_add
		qry("peeps.get_person(9)")
		assert_equal 'application/problem+json', @res[0]['mime']
		qry("sivers.get_comment(6)")
		assert_equal 'application/problem+json', @res[0]['mime']
		qry("sivers.add_comment($1, $2, $3, $4)", [
			@new_comment[:uri],
			@new_comment[:name],
			@new_comment[:email],
			@new_comment[:html]])
		qry("peeps.get_person(9)")
		assert_equal 'Bob Dobalina', @j[:name]
		qry("sivers.get_comment(6)")
		assert_equal 9, @j[:person_id]
		assert_includes @j[:html], 'þ'
		refute_includes @j[:html], '<script>'
		assert_includes @j[:html], '&quot;poop&quot;'
		refute_includes @j[:html], '<a href'
		assert_includes @j[:html], 'yuck'
		assert_includes @j[:html], 'smile.gif'
	end
	
	def test_comments_newest
		qry("sivers.new_comments()")
		assert_equal [5, 4, 3, 2, 1], @j.map {|x| x[:id]}
	end

	def test_reply
		qry("sivers.reply_to_comment(1, 'Thanks')")
		assert_equal 'That is great.<br><span class="response">Thanks -- Derek</span>', @j[:html]
		qry("sivers.reply_to_comment(2, ':-)')")
		assert_includes @j[:html], 'smile'
		qry("sivers.reply_to_comment(999, 'Thanks')")
		assert_equal 'Not Found', @j[:title]
	end

	def test_delete
		qry("sivers.delete_comment(5)")
		assert_equal 'spam2', @j[:html]
		qry("sivers.new_comments()")
		assert_equal [4, 3, 2, 1], @j.map {|x| x[:id]}
		qry("peeps.get_person(5)")
		assert_equal 'Oompa Loompa', @j[:name]
		qry("sivers.delete_comment(999)")
		assert_equal 'Not Found', @j[:title]
	end

	def test_spam
		qry("sivers.spam_comment(5)")
		assert_equal 'spam2', @j[:html]
		qry("peeps.get_person(5)")
		assert_equal 'application/problem+json', @res[0]['mime']
		qry("sivers.new_comments()")
		assert_equal [3, 2, 1], @j.map {|x| x[:id]}
		qry("sivers.spam_comment(999)")
		assert_equal 'Not Found', @j[:title]
	end

	def test_update
		qry("sivers.update_comment(5, $1)", ['{"html":"new body", "name":"Opa!", "created_at":"2000-01-01"}'])
		assert_equal 'Opa!', @j[:name]
		assert_equal 'new body', @j[:html]
		assert_equal 'oompa@loompa.mm', @j[:email]
		assert_equal '2014-04-28', @j[:created_at]
		qry("sivers.update_comment(999, $1)", ['{"html":"hi"}'])
		assert_equal 'Not Found', @j[:title]
	end

	def test_comment_person
		qry("sivers.get_comment(1)")
		assert_equal 'trust', @j[:uri]
		assert_equal 'Willy Wonka', @j[:person][:name]
		assert_equal 'musicthoughts', @j[:person][:stats][1][:name]
		assert_equal 'http://www.wonka.com/', @j[:person][:urls][0][:url]
		assert_equal 'you coming by?', @j[:person][:emails][0][:subject]
		qry("sivers.get_comment(999)")
		assert_equal 'Not Found', @j[:title]
	end

end
