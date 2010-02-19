require 'json'

class GithubHookController < ApplicationController
  
  skip_before_filter :verify_authenticity_token, :check_if_login_required

  def index

    Repository.all.each do |repository|
      if repository.is_a?(Repository::Git)
        puts repository.url
        command = "cd '#{repository.url}/../' && git pull"
        exec(command)
      end
    end
    Repository.fetch_changesets
    render(:text => 'OK')
  end

  private
  
  def exec(command)
    logger.info { "GithubHook: Executing command: '#{command}'" }
    output = `#{command}`
    logger.info { "GithubHook: Shell returned '#{output}'" }
  end

end
