require File.dirname(__FILE__) + '/../test_helper'

require 'mocha'

class GithubHookControllerTest < ActionController::TestCase

  def setup
    # Sample JSON post from http://github.com/guides/post-receive-hooks
    @json = '{ 
      "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
      "repository": {
        "url": "http://github.com/defunkt/github",
        "name": "github",
        "description": "You\'re lookin\' at it.",
        "watchers": 5,
        "forks": 2,
        "private": 1,
        "owner": {
          "email": "chris@ozmm.org",
          "name": "defunkt"
        }
      },
      "commits": [
        {
          "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
          "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
          "author": {
            "email": "chris@ozmm.org",
            "name": "Chris Wanstrath"
          },
          "message": "okay i give in",
          "timestamp": "2008-02-15T14:57:17-08:00",
          "added": ["filepath.rb"]
        },
        {
          "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
          "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
          "author": {
            "email": "chris@ozmm.org",
            "name": "Chris Wanstrath"
          },
          "message": "update pricing a tad",
          "timestamp": "2008-02-15T14:36:34-08:00"
        }
      ],
      "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
      "ref": "refs/heads/master"
    }'
    @repository = Repository::Git.new
    @repository.stubs(:fetch_changesets).returns(true)

    @project = Project.new
    @project.stubs(:repository).returns(@repository)
    Project.stubs(:find_by_identifier).with('github').returns(@project)

    # Make sure we don't run actual commands in test
    Open3.stubs(:popen3)

    Repository.expects(:fetch_changesets).never
  end

  def mock_descriptor(kind, contents = [])
    descriptor = mock(kind)
    descriptor.expects(:readlines).returns(contents)
    descriptor
  end

  def do_post(payload = nil)
    payload = @json if payload.nil?
    payload = payload.to_json if payload.is_a?(Hash)
    post :index, :payload => payload
  end

  def test_should_use_the_repository_name_as_project_identifier
    Project.expects(:find_by_identifier).with('github').returns(@project)
    @controller.stubs(:exec).returns(true)
    do_post
  end

  def test_should_update_the_repository_using_git_on_the_commandline
    Project.expects(:find_by_identifier).with('github').returns(@project)
    @controller.expects(:exec).returns(true)
    do_post
  end

  def test_should_use_project_identifier_from_request
    Project.expects(:find_by_identifier).with('redmine').returns(@project)
    @controller.stubs(:exec).returns(true)
    post :index, :project_id => 'redmine', :payload => @json
  end

  def test_should_downcase_identifier
    # Redmine project identifiers are always downcase
    Project.expects(:find_by_identifier).with('redmine').returns(@project)
    @controller.stubs(:exec).returns(true)
    post :index, :project_id => 'ReDmInE', :payload => @json
  end

  def test_should_render_ok_when_done
    @controller.expects(:exec).returns(true)
    do_post
    assert_response :success
    assert_equal 'OK', @response.body
  end

  def test_should_fetch_changesets_into_the_repository
    @controller.expects(:exec).returns(true)
    @repository.expects(:fetch_changesets).returns(true)
    do_post
    assert_response :success
    assert_equal 'OK', @response.body
  end

  def test_should_return_404_if_project_identifier_not_given
    assert_raises ActiveRecord::RecordNotFound do
      do_post :repository => {}
    end
  end

  def test_should_return_404_if_project_not_found
    assert_raises ActiveRecord::RecordNotFound do
      Project.expects(:find_by_identifier).with('foobar').returns(nil)
      do_post :repository => {:name => 'foobar'}
    end
  end

  def test_should_return_500_if_project_has_no_repository
    assert_raises TypeError do
      project = mock('project', :to_s => 'My Project', :identifier => 'github')
      project.expects(:repository).returns(nil)
      Project.expects(:find_by_identifier).with('github').returns(project)
      do_post :repository => {:name => 'github'}
    end
  end

  def test_should_return_500_if_repository_is_not_git
    assert_raises TypeError do
      project = mock('project', :to_s => 'My Project', :identifier => 'github')
      repository = Repository::Subversion.new
      project.expects(:repository).at_least(1).returns(repository)
      Project.expects(:find_by_identifier).with('github').returns(project)
      do_post :repository => {:name => 'github'}
    end
  end

  def test_should_not_require_login
    @controller.expects(:exec).returns(true)
    @controller.expects(:check_if_login_required).never
    do_post
  end

  def test_exec_should_log_output_from_git_as_debug
    stdout = mock_descriptor('STDOUT', ["output 1\n", "output 2\n"])
    stderr = mock_descriptor('STDERR', ["error 1\n", "error 2\n"])
    Open3.expects(:popen3).returns(['STDIN', stdout, stderr])

    @controller.logger.expects(:debug).at_least(4)
    do_post
  end

end
